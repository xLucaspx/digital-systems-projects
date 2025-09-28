`default_nettype none

import Isa::*;

/**
 * Mini serial processor. Communicates with the other blocks (ALU, multiplier etc.) through an SPI.
 *
 * [Wires]
 * - i_clock:   System clock.
 * - i_reset:   Reset signal.
 * - write_ram: RamPort CPU interface to write in the memory.
 * - read_ram:  RamPort Memory interface to read from the memory.
 */
module Processor(
	input var logic i_clock,
	input var logic i_reset,

	RamPort.Cpu write_ram,
	RamPort.Memory read_ram
);

	localparam int ALU_NSS_POSITION = 0;
	localparam int BAS_NSS_POSITION = 1;
	localparam int MUL_NSS_POSITION = 2;

	/**
	 * SPI interface for communication with other modules (Alu, Multiplier etc.).
	 */
	Spi #(3) u_spi();

	Alu #(.NssPosition(ALU_NSS_POSITION)) u_alu(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	BarrelShifter #(.NssPosition(BAS_NSS_POSITION)) u_bas(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	Multiplier #(.NssPosition(MUL_NSS_POSITION)) u_mul(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	/**
	 * States to control the processor's FSM.
	 */
	typedef enum logic [3:0] {
		FETCH      = 'b0001,
		DECODE     = 'b0010,
		EXECUTE    = 'b0100,
		WRITE_BACK = 'b1000,
		HALT       = 'b0000
	} state_t;

	/**
	 * States to control the SPI FSM inside the `EXECUTE` block.
	 */
	typedef enum logic [5:0] {
		IDLE      = 'b00_0001,
		SEND      = 'b00_0010,
		SENDING   = 'b00_0100,
		RECEIVE   = 'b00_1000,
		RECEIVING = 'b01_0000,
		DONE      = 'b10_0000
	} spi_state_t;

	state_t current_state;
	state_t next_state;

	spi_state_t spi_state;

	/**
	 * Register bank. There are REGISTER_BANK_SIZE positions, each with REGISTER_SIZE bits.
	 */
	logic [REGISTER_BANK_SIZE - 1 : 0] [REGISTER_SIZE - 1 : 0] registers;

	/**
	 * Program counter register, stores the address of the instruction being fetched.
	 */
	logic [REGISTER_SIZE - 1 : 0] pc;

	/*
	 * Packet that will be received through the SPI.
	 */
	logic [REGISTER_SIZE - 1 : 0] packet_in;

	/**
	 * Counter to keep track of `packet_in` bits received from the SPI.
	 */
	int counter_in;

	/*
	 * Packet that will be transmitted to the ALU.
	 */
	AluPacket alu_packet_out;

	/**
	 * Counter to keep track of `alu_packet_out` bits sent to the ALU.
	 */
	int alu_counter_out;

	/*
	 * Packet that will be transmitted to the barrel shifter.
	 */
	ShifterPacket bas_packet_out;

	/**
	 * Counter to keep track of `mul_packet_out` bits sent to the barrel shifter.
	 */
	int bas_counter_out;

	/*
	 * Packet that will be transmitted to the multiplier.
	 */
	MulPacket mul_packet_out;

	/**
	 * Counter to keep track of `mul_packet_out` bits sent to the multiplier.
	 */
	int mul_counter_out;

	/**
	 * Temporal barrier register to save the fetched instruction beetween `FETCH` and `DECODE`.
	 */
	logic [INSTRUCTION_SIZE - 1 : 0] instruction_reg;

	/**
	 * Temporal barrier register to save the operation code beetween `DECODE` and `EXECUTE`.
	 */
	Operation opcode_reg;

	/**
	 * Temporal barrier register to save the immediate flag of the instruction format beetween `DECODE` and `EXECUTE`.
	 */
	logic is_immediate_reg;

	/**
	 * Temporal barrier register to save the destination register address beetween `DECODE` and `EXECUTE`.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd_address_reg;

	/**
	 * Temporal barrier register to save the first operand beetween `DECODE` and `EXECUTE`.
	 */
	logic [REGISTER_SIZE - 1 : 0] rs1_value_reg;

	/**
	 * Temporal barrier register to save the second operand beetween `DECODE` and `EXECUTE`.
	 */
	logic [REGISTER_SIZE - 1 : 0] rs2_value_reg;

	/**
	 * Temporal barrier register to save the immediate value beetween `DECODE` and `EXECUTE`.
	 */
	logic [MEMORY_ADDRESS_WIDTH - 1 : 0] immediate_reg;

	/**
	 * Temporal barrier register to save the operation result between `EXECUTE` and `WRITE_BACK`.
	 */
	logic [REGISTER_SIZE - 1 : 0] result_reg;

	/**
	 * Temporal barrier register to save the destination register address between `EXECUTE` and `WRITE_BACK`.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] wb_address_reg;

	/**
	 * Operation decoded from the current instruction.
	 */
	Operation operation;

	/**
	 * Immediate flag decoded from the current instruction.
	 */
	logic is_immediate;

	/**
	 * Destination register address decoded from the current instruction.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;

	/**
	 * Source register 1 address decoded from the current instruction.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs1;

	/**
	 * Source register 2 address decoded from the current instruction.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs2;

	/**
	 * Immediate value decoded from the current instruction.
	 */
	logic [MEMORY_ADDRESS_WIDTH - 1 : 0] immediate;

	logic alu_active;
	logic bas_active;
	logic mul_active;

	logic spi_active;
	logic spi_done;

	assign u_spi.sclk = i_clock;

	/**
	 * The RAM is enabled while the processor is working.
	 */
	assign write_ram.enable = current_state != HALT;

	/**
	 * Writing is enabled during `EXECUTE` for the `SW` operation.
	 */
	assign write_ram.write_enable = (current_state == EXECUTE) && (opcode_reg == SW);

	/**
	 * When enabled, writes the value of `rd` to the specified address.
	 */
	assign write_ram.write_data = registers[rd_address_reg];

	/**
	 * RAM address. During `EXECUTE` for `LW` and `SW`, it's the decoded address (immediate) of the current instruction;
	 * at other times it's the program counter, i.e., the address of the next instruction.
	 */
	assign write_ram.address = (current_state == EXECUTE && opcode_reg inside { LW, SW }) ? immediate_reg : pc;

	/**
	 * SPI is enabled during `EXECUTE` if the instruction is not immediate, or while it's not done communicating.
	 */
	assign spi_active = (current_state == EXECUTE) && !(is_immediate_reg || spi_done);
	assign spi_done   = spi_state == DONE;

	assign alu_active = opcode_reg inside { ADD, AND, OR };
	assign bas_active = opcode_reg inside { SHL, SHR };
	assign mul_active = opcode_reg == MUL;

	/*
	* If the SPI is active, sets `nss` to `0` at the active slave designated position. At maximum one slave must be active
	* at a time, and `nss` should only be set when transmitting/receiving.
	*/
	always_comb
		if (spi_active) begin
			u_spi.nss[ALU_NSS_POSITION] = !alu_active;
			u_spi.nss[BAS_NSS_POSITION] = !bas_active;
			u_spi.nss[MUL_NSS_POSITION] = !mul_active;
		end
		else u_spi.nss = '1;

	/**
	 * Defines the SPI's MOSI signal. When it wants to transmit, it sends `1` to the selected slave and expects the
	 * response to be `0`; during transmission the MOSI is the respective data and when it is available to receive it's
	 * set to `0`.
	 */
	always_comb case (spi_state)
		SEND:    u_spi.mosi = 1'b1;
		SENDING: if (alu_active)      u_spi.mosi = alu_packet_out[alu_counter_out];
			       else if (mul_active) u_spi.mosi = mul_packet_out[mul_counter_out];
			       else if (bas_active) u_spi.mosi = bas_packet_out[bas_counter_out];
		default: u_spi.mosi = 1'b0;
	endcase

	/**
	 * Processor FSM state definition logic.
	 */
	always_comb
		if (!i_reset) next_state = FETCH;
		else case (current_state)
			FETCH:      next_state = DECODE;

			DECODE:     next_state = instruction_reg == '0 ? HALT : EXECUTE;

			EXECUTE:    next_state = (is_immediate_reg || spi_done) ? WRITE_BACK : EXECUTE;

			WRITE_BACK: next_state = FETCH;

			HALT:       next_state = HALT;

			default:    next_state = FETCH;
		endcase

	/**
	 * Decodes the current instruction asynchronously; the signals inside this block will be saved in the DECODE->EXECUTE
	 * temporal barrier.
	 */
	always_comb
		if (!i_reset) { operation, is_immediate, rd, rs1, rs2, immediate } = '0;
		else if (instruction_reg[12]) { operation, is_immediate, rd, immediate } = instruction_reg;
		else { operation, is_immediate, rd, rs1, rs2 } = instruction_reg;

	/**
	 * SPI FSM state transition and execution logic.
	 */
	always_ff @(posedge i_clock, negedge i_reset)
		if (!i_reset) begin
			spi_state       <= IDLE;
			packet_in       <= '0;
			counter_in      <= '0;
			alu_packet_out  <= '0;
			alu_counter_out <= '0;
			bas_packet_out  <= '0;
			bas_counter_out <= '0;
			mul_packet_out  <= '0;
			mul_counter_out <= '0;
		end else case (spi_state)
			IDLE:      spi_state <= spi_active ? SEND : IDLE;

			SEND:      begin
				if (!u_spi.miso && u_spi.mosi) begin
					if (alu_active)      alu_packet_out <= { rs2_value_reg, rs1_value_reg, opcode_reg };
					else if (mul_active) mul_packet_out <= { rs2_value_reg, rs1_value_reg };
					else if (bas_active) bas_packet_out <= { rs2_value_reg, rs1_value_reg, opcode_reg };
					spi_state <= SENDING;
				end else spi_state <= SEND;
			end

			SENDING:   begin
				if (alu_active) begin
					if (alu_counter_out == $bits(alu_packet_out) - 1) begin
						alu_counter_out <= 0;
						spi_state       <= RECEIVE;
					end else begin
						alu_counter_out <= alu_counter_out + 1;
						spi_state       <= SENDING;
					end
				end else if (bas_active) begin
					if (bas_counter_out == $bits(bas_packet_out) - 1) begin
						bas_counter_out <= 0;
						spi_state       <= RECEIVE;
					end else begin
						bas_counter_out <= bas_counter_out + 1;
						spi_state       <= SENDING;
					end
				end else if (mul_active) begin
					if (mul_counter_out == $bits(mul_packet_out) - 1) begin
						mul_counter_out <= 0;
						spi_state       <= RECEIVE;
					end else begin
						mul_counter_out <= mul_counter_out + 1;
						spi_state       <= SENDING;
					end
				end
			end

			RECEIVE:   spi_state <= (u_spi.miso && !u_spi.mosi) ? RECEIVING : RECEIVE;

			RECEIVING: begin
				packet_in[counter_in] <= u_spi.miso;
				counter_in            <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
				spi_state             <= (counter_in == $bits(packet_in) - 1) ? DONE : RECEIVING;
			end

			DONE:      spi_state <= IDLE;

			default:   spi_state <= IDLE;
		endcase

	/**
	 * Synchronous program counter increment on FETCH.
	 */
	always_ff @(posedge i_clock, negedge i_reset)
		if (!i_reset) pc <= '0;
		else if (current_state == FETCH) pc <= pc + 1;
	
	/**
	 * Processor FSM state transition.
	 */
	always_ff @(posedge i_clock, negedge i_reset) current_state <= next_state;

	/**
	 * FETCH->DECODE temporal barrier.
	 */
	always_ff @(posedge i_clock, negedge i_reset)
		if (!i_reset) instruction_reg <= '0;
		else if (current_state == FETCH) instruction_reg <= read_ram.read_data;

	/**
	* DECODE->EXECUTE temporal barrier.
	*/
	always_ff @(posedge i_clock, negedge i_reset)
		if (!i_reset) begin
			opcode_reg       <= Operation'(0);
			is_immediate_reg <= '0;
			rd_address_reg   <= '0;
			rs1_value_reg    <= '0;
			rs2_value_reg    <= '0;
			immediate_reg    <= '0;
		end else if (current_state == DECODE) begin
			opcode_reg       <= operation;
			is_immediate_reg <= is_immediate;
			rd_address_reg   <= rd;
			rs1_value_reg    <= registers[rs1];
			rs2_value_reg    <= registers[rs2];
			immediate_reg    <= immediate;
		end

	/**
	* EXECUTE->WRITE_BACK temporal barrier.
	*/
	always_ff @(posedge i_clock, negedge i_reset)
		if (!i_reset) begin
			wb_address_reg <= '0;
			result_reg     <= '0;
		end else if (current_state == EXECUTE) begin
			wb_address_reg <= rd_address_reg;
			result_reg     <= spi_done ? packet_in : result_reg;
		end

	/**
	 * `WRITE_BACK` state execution.
	 */
	always_ff @(posedge i_clock, negedge i_reset)
		if (current_state == WRITE_BACK) begin
			if (opcode_reg == LW) registers[wb_address_reg] <= read_ram.read_data;
			else if (opcode_reg inside { ADD, AND, OR, MUL, SHL, SHR }) registers[wb_address_reg] <= result_reg;
		end

endmodule: Processor
