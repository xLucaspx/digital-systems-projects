`default_nettype none

import Isa::*;

module Processor (
    input wire logic i_clock,
    input wire logic i_reset,
    dual_port_ram_if.CPU mem_a,
    dual_port_ram_if.MEM mem_b
);
parameter int REG_COUNT = 16;
parameter int REG_WIDTH = 16;

regbank_if #(.REG_WIDTH(REG_WIDTH), .REG_COUNT(REG_COUNT)) rb_if(i_clock, i_reset);
regbank #(.REG_WIDTH(REG_WIDTH)) rb(i_clock, i_reset, rb_if);
// ===================================
// Usar apenas uma SPI para 3 slaves
// ===================================
Spi #(3) spi();
// ===================================
// Comunicação com nss[0]
// ===================================
Alu alu_mod(.i_clock(i_clock), .i_reset(i_reset), .spi(spi));
// ===================================
// Comunicação com nss[1]
// ===================================
Mul mul(.i_clock(i_clock), .i_reset(i_reset), .spi(spi));
// ===================================
// Comunicação com nss[2]
// ===================================
Shifter shifter(.i_clock(i_clock), .i_reset(i_reset), .spi(spi));


// ======================================
// REGISTRADORES DA CPU (DE CONTROLE)
// ======================================
logic[REG_WIDTH -1:0] PC;

logic[3:0] stall;

logic stall_signal;
assign stall_signal = stall[0] || stall[1] || stall[2] || stall[3];
//if $onehot(stall)

// ======================================
// BARREIRAS TEMPORAIS 
// ======================================
typedef struct packed {
    logic[2:0] op_code;
    logic imm;
    logic [$clog2(REG_COUNT) -1:0] rd;
    logic [$clog2(REG_COUNT) -1:0] opa;
    logic [$clog2(REG_COUNT) -1:0] opb;
} fetch_to_decode;


typedef struct packed {
    logic[2:0] op_code;
    logic [$clog2(REG_COUNT) -1:0] rd;
    logic [REG_WIDTH -1:0] value_opa;
    logic [REG_WIDTH -1:0] value_opb;
} decode_to_execute;

typedef struct packed {
	logic [2:0] op_code;
    logic [$clog2(REG_COUNT) -1:0] rd;
    logic [REG_WIDTH -1:0] result;
} execute_to_writeback;
execute_to_writeback barreira3;

assign mem_a.we = 0;
assign mem_a.wdata = 0;

// ======================================
// LÓGICA DOS ESTÁGIOS
// ======================================
// fetch
fetch_to_decode barreira1;
always @(posedge i_clock, negedge i_reset) begin

    if (~i_reset) begin
        PC <= 0;
    end else if (stall_signal) begin
        // Apenas espera
    end else begin
        mem_a.addr <= PC;
        PC <= PC +1;
        {barreira1.op_code, barreira1.imm} <= {mem_a.rdata[15:13], mem_a.rdata[12]};
        {barreira1.rd, barreira1.opa, barreira1.opb} <= {mem_a.rdata[11:8], mem_a.rdata[7:4], mem_a.rdata[3:0]};
    end
end

//decode
// ===========================================|
// Prepara para o próximo ciclo de i_clock      |
// busacar o valor no endereço do registrador.|
assign rb_if.raddr1 = barreira1.opa;        //|
assign rb_if.raddr2 = barreira1.opb;        //|
// ===========================================|

decode_to_execute barreira2;
always @(posedge i_clock, negedge i_reset) begin
    if (~i_reset) begin
        PC <= 0;
    end else if (stall_signal) begin
        // Apenas espera
    end else begin
        {barreira2.op_code} <= barreira1.op_code;
		{barreira2.rd} <= barreira1.rd;
        if (barreira1.imm) begin
            barreira2.value_opa <= {barreira1.opa, barreira1.opb};
        end else begin
            barreira2.value_opa <= rb_if.rdata1;
            barreira2.value_opb <= rb_if.rdata2;
        end
    end
end
// ########################################################

/**
	 * Counter to keep track of alu_packet_in bits received from the ALU.
	 */
	int alu_counter_in;

	/*
	 * Packet that will be transmitted to the ALU.
	 */
	AluPacket alu_packet_out;

	/**
	 * Counter to keep track of alu_packet_out bits sent to the ALU.
	 */
	int alu_counter_out;

	Instruction alu_op;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;

	typedef enum logic [6:0] {
		WAIT         = 7'b000_0001,
		EXECUTE       = 7'b000_0010,
		SEND      = 7'b000_0100,
		SENDING   = 7'b000_1000,
		RECEIVE   = 7'b001_0000,
		RECEIVING = 7'b010_0000,
		STORE     = 7'b100_0000
	} state_t;

	state_t current_state;
	state_t next_state;

	assign spi.sclk = i_clock;

	
// `nss` deve ser 0 apenas quando quisermos transmitir/receber
	logic [2:0] spi_signal;
	assign spi.nss = spi_signal;
	always_comb begin
		if (current_state == WAIT) begin
			unique case (barreira2.op_code)
				ADD: spi_signal = 'b110; // Operações da ULA
				AND: spi_signal = 'b110; // Operações da ULA
				OR : spi_signal = 'b110; // Operações da ULA
				MUL: spi_signal = 'b101; // Operações do MUL
				SHL: spi_signal = 'b011; // Operações do SHL
				SHR: spi_signal = 'b011; // Operações do SHR
				default: spi_signal = 'b111;
			endcase
		end else if (current_state == STORE) begin
			spi_signal = 'b111;
		end
	end

	assign spi.mosi = (current_state == SEND)    ? 1'b1
									: (current_state == SENDING) ? alu_packet_out[alu_counter_out]
									: 1'b0;
	int first_execute = 0;
	always_comb
		if (~i_reset) next_state = WAIT;
		else case (current_state)
				WAIT: next_state = first_execute > 1 && spi_signal != 'b111 ? EXECUTE : WAIT;
				EXECUTE:       next_state = SEND;
				SEND:      next_state = (~spi.miso[2] && spi.mosi || ~spi.miso[1] && spi.mosi || ~spi.miso[0] && spi.mosi) ? SENDING : SEND;
				SENDING:   next_state = (alu_counter_out == $bits(alu_packet_out) - 1) ? RECEIVE : SENDING;
				RECEIVE:   next_state = (spi.miso[2] && ~spi.mosi || spi.miso[1] && ~spi.mosi || spi.miso[0] && ~spi.mosi) ? RECEIVING : RECEIVE;
				RECEIVING: next_state = (alu_counter_in == $bits(barreira2.value_opa) - 1) ? STORE : RECEIVING;
				STORE:     next_state = WAIT;
				default:       next_state = WAIT;
			endcase
		

	logic [REG_WIDTH-1: 0] resultado;
	logic [REG_WIDTH-1: 0] resultado_in;

	always_ff @(posedge i_clock, negedge i_reset) begin: StateMachine
		if (~i_reset) begin
			alu_counter_in  <= 0;
			alu_counter_out <= 0;
			alu_packet_out  <= 0;
			rs_1            <= 0;
			rs_2            <= 0;
			rd              <= 0;
			// barreira1		<= 0;
			// barreira2		<= 0;
			// barreira3		<= 0;
		end
		else begin
			case (current_state)
				EXECUTE: begin
				end
				SEND: begin
					alu_packet_out <= { barreira2.value_opa, barreira2.value_opb, barreira2.op_code};
				end
				SENDING: begin
					alu_counter_out <= (alu_counter_out == $bits(alu_packet_out) - 1) ? 0 : alu_counter_out + 1;
				end
				RECEIVING: begin
					resultado_in[alu_counter_in] <= spi.miso[2] | spi.miso[1] | spi.miso[0] ;
					alu_counter_in <= (alu_counter_in == $bits(resultado_in) - 1) ? 0 : alu_counter_in + 1;
				end
				STORE: resultado <= resultado_in;
			endcase
			current_state <= next_state;
		end

		
	end: StateMachine

assign stall = current_state == WAIT && spi_signal == 3'b111  || current_state == STORE ? 4'b0000 : 4'b0100;
// execute
always @(posedge i_clock, negedge i_reset) begin
    if (~i_reset) begin
        PC <= 0;
    end else if (stall != 4'b0100 && stall_signal) begin
        // Apenas espera
    end else  begin
		if (first_execute < 3) begin
			first_execute <= first_execute +1;
		end
		if (spi_signal != 'b111) begin
			barreira3.op_code <= barreira2.op_code;
			barreira3.rd <= barreira2.rd;
			barreira3.result <= resultado;
		end else begin
			barreira3.op_code <= barreira2.op_code;
			barreira3.rd <= barreira2.rd;
			barreira3.result <= barreira2.value_opa;
		end
    end
end

// ########################################################
// writeback
logic writeback = barreira3.op_code == SW;
assign rb_if.waddr = barreira3.rd;
assign rb_if.wdata = barreira3.result;
assign rb_if.we = LW != barreira3.op_code;

assign mem_b.we = writeback;
assign mem_b.addr = barreira3.rd;
assign mem_b.wdata = barreira3.result;

always @(posedge i_clock, negedge i_reset) begin
    if (~i_reset) begin
        PC <= 0;
    end else if (stall_signal) begin
        // Apenas espera
    end else begin
		case (barreira3.op_code)
			default: begin 

			end
		endcase
		
    end
end

endmodule