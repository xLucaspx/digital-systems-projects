`default_nettype none
`timescale 1ns/1ps

// TODO: `timescale 1ns/1ps
// TODO: document testbench
// TODO: print test function, rotate function
// TODO: finish doc
// TODO: module regbank (?)
// TODO: else/default e setar os bgl em 0 quando não for usado, e.g. imm
module ProcessorTb;

logic clock = 0;
initial forever #5 clock = ~clock;

logic reset = 0;
initial #10 reset = 1;

logic [Isa::INSTRUCTION_SIZE - 1 : 0] instruction = '0;

RamPort u_ram_port(.i_clock(clock));

SinglePortRam u_ram(
	.i_clock(clock),
	.ram_port(u_ram_port)
);

Processor u_processor_dut(
	.i_clock(clock),
	.i_reset(reset),
	.read_ram(u_ram_port),
	.write_ram(u_ram_port)
);

// Fill registers with random values
initial foreach (u_processor_dut.registers[i]) u_processor_dut.registers[i] = $urandom;

// Load memory with instructions and data
initial begin
	u_ram.memory = '{
		0 : { Isa::LW,  1'b1, 4'd1,  8'd101       }, // r1 = 1;
		1 : { Isa::LW,  1'b1, 4'd0,  8'd100       }, // r0 = 0;
		2 : { Isa::ADD, 1'b0, 4'd2,  4'd1,  4'd1  }, // r2 = r1 + r1;
		3 : { Isa::SW,  1'b1, 4'd2,  8'd255       }, // m[255] = r2;
		4 : { Isa::MUL, 1'b0, 4'd3,  4'd2,  4'd2  }, // r3 = r2 * r2;
		5 : { Isa::SHL, 1'b0, 4'd4,  4'd3,  4'd1  }, // r3 = r3 ROL 1;

		6 : { Isa::AND, 1'b0, 4'd15, 4'd15, 4'd15 },
		7 : { Isa::MUL, 1'b0, 4'd14, 4'd14, 4'd14 },
		8 : { Isa::ADD, 1'b0, 4'd13, 4'd13, 4'd13 },
		9 : { Isa::OR,  1'b0, 4'd12, 4'd12, 4'd12 },
		10: { Isa::SHL, 1'b0, 4'd11, 4'd11, 4'd11 },
		11: { Isa::SHR, 1'b0, 4'd10, 4'd10, 4'd10 },

		12: { Isa::OR,  1'b0, 4'd9, 4'd10, 4'd11  },
		13: { Isa::SHR, 1'b0, 4'd9, 4'd10, 4'd11  },
		14: { Isa::ADD, 1'b0, 4'd9, 4'd10, 4'd11  },
		15: { Isa::MUL, 1'b0, 4'd9, 4'd10, 4'd11  },
		16: { Isa::SHL, 1'b0, 4'd9, 4'd10, 4'd11  },
		17: { Isa::AND, 1'b0, 4'd9, 4'd10, 4'd11  },

		18: { Isa::AND, 1'b0, 4'd12, 4'd13, 4'd14 },
		19: { Isa::ADD, 1'b0, 4'd9, 4'd10, 4'd12  },
		20: { Isa::OR,  1'b0, 4'd6,  4'd7,  4'd8  },
		21: { Isa::MUL, 1'b0, 4'd3,  4'd4,  4'd5  },

		22: { Isa::OR,  1'b0, 4'd2, 4'd9, 4'd12   },
		23: { Isa::AND, 1'b0, 4'd1,  4'd3, 4'd4   },
		24: { Isa::ADD, 1'b0, 4'd0,  4'd3, 4'd9   },
		25: { Isa::SW,  1'b1, 4'd10, 8'd255       },

		26: 'b0, // halt

		// data
		100: 1'b0,
		101: 1'b1,

		default: $urandom
	};
end

initial begin
	Isa::Operation operation;
	logic is_immediate;
	logic [$clog2(Isa::REGISTER_BANK_SIZE) - 1 : 0] rd;
	logic [$clog2(Isa::REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(Isa::REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [Isa::MEMORY_ADDRESS_WIDTH - 1 : 0] immediate;

	logic [Isa::REGISTER_SIZE - 1 : 0] src1;
	logic [Isa::REGISTER_SIZE - 1 : 0] src2;
	logic [Isa::REGISTER_SIZE - 1 : 0] expected;
	logic [Isa::REGISTER_SIZE - 1 : 0] actual;
	logic [$clog2(Isa::REGISTER_SIZE) - 1 : 0] shift_amount;

	for (int i = 0; i < Isa::MEMORY_DEPTH; i++) begin
		// wait until the processor exits the EXECUTE state
		@(posedge clock iff (u_processor_dut.next_state == u_processor_dut.EXECUTE));

		instruction = u_ram.memory[i];

		if (instruction == 'b0) begin
			$display("[NOOP] %05t: mem[%02d] { %h } op=%3s { %h } rd=%02d rs1=%02d { %h } rs2=%02d { %h }",
				$time, i, instruction, operation, operation, rd, rs_1, src1, rs_2, src2
			);
			// #1000
			break;
		end

		if (instruction[12]) begin
			{ operation, is_immediate, rd, immediate } = instruction;

			if (operation == Isa::LW) expected = u_ram.memory[immediate];
			else expected = u_processor_dut.registers[rd];

		end else begin
			{ operation, is_immediate, rd, rs_1, rs_2 } = instruction;
			src1 = u_processor_dut.registers[rs_1];
			src2 = u_processor_dut.registers[rs_2];
			shift_amount = src2[$clog2(Isa::REGISTER_SIZE) - 1 : 0];

			case (operation)
				Isa::ADD: expected = src1 + src2;
				Isa::MUL: expected = src1 * src2;
				Isa::AND: expected = src1 & src2;
				Isa::OR : expected = src1 | src2;
				Isa::SHL: expected = (src1 << shift_amount) | (src1 >> (Isa::REGISTER_SIZE - shift_amount));
				Isa::SHR: expected = (src1 >> shift_amount) | (src1 << (Isa::REGISTER_SIZE - shift_amount));
				default:  expected = 'x;
			endcase
		end

			// espera o WRITE_BACK terminar
			@(negedge clock iff (u_processor_dut.current_state == u_processor_dut.FETCH));
			// agora espera mais 1 ciclo para garantir que os valores foram escritos
			// @(ne clock);

			if (operation == Isa::SW) actual = u_ram.memory[immediate];
			else actual = u_processor_dut.registers[rd];

			if (expected === actual) begin
				$display("[PASS] %05t: mem[%02d] { %h } op=%3s { %h } rd=%02d rs1=%02d { %h } rs2=%02d { %h } -> %h",
					$time, i, instruction, operation, operation, rd, rs_1, src1, rs_2, src2, actual
				);
			end else begin
				$error("[FAIL] %05t: mem[%02d] { %h } op=%3s { %h } rd=%02d rs1=%02d { %h } rs2=%02d { %h } -> expected=%h actual=%h",
					$time, i, instruction, operation, operation, rd, rs_1, src1, rs_2, src2, expected, actual
				);
			end
	end
end

endmodule: ProcessorTb
