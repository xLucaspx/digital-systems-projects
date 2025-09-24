`default_nettype none
`timescale 1ps/1ps

// TODO: `timescale 1ns/1ps
// TODO: document testbench
// TODO: print test function, rotate function
module ProcessorTb;

logic clock = 0;
initial forever #5 clock = ~clock;

logic reset = 0;
initial #10 reset = 1;

Isa::Instruction instruction = 0; // TODO inst can have two formats

RamPort u_ram_port(.i_clock(clock));

SinglePortRam u_ram(
	.i_clock(clock),
	.ram_port(u_ram_port)
);

Processor u_processor_dut(
	.i_clock(clock),
	.i_reset(reset),
	.i_instruction(instruction),
	.read_ram(u_ram_port),
	.write_ram(u_ram_port)
);

Isa::Instruction instruction_v [21:0] = '{ // TODO inst can have two formats
	'd21: 'b0,
	'd20: { Isa::AND, 10'd15, 10'd15, 10'd15 },
	'd19: { Isa::MUL, 10'd14, 10'd14, 10'd14 },
	'd18: { Isa::ADD, 10'd13, 10'd13, 10'd13 },
	'd17: { Isa::OR,  10'd12, 10'd12, 10'd12 },
	'd16: { Isa::SHL, 10'd11, 10'd11, 10'd11 },
	'd15: { Isa::SHR, 10'd10, 10'd10, 10'd10 },

	'd14: 'b0,

	'd13: { Isa::OR,  10'd11, 10'd10, 10'd9  },
	'd12: { Isa::SHR, 10'd11, 10'd10, 10'd9  },
	'd11: { Isa::ADD, 10'd11, 10'd10, 10'd9  },
	'd10: { Isa::MUL, 10'd11, 10'd10, 10'd9  },
	'd9 : { Isa::SHL, 10'd11, 10'd10, 10'd9  },
	'd8 : { Isa::AND, 10'd11, 10'd10, 10'd9  },

	'd7 : { Isa::AND, 10'd14, 10'd13, 10'd12 },
	'd6 : { Isa::ADD, 10'd11, 10'd10, 10'd9  },
	'd5 : { Isa::OR,  10'd8,  10'd7,  10'd6  },
	'd4 : { Isa::MUL, 10'd5,  10'd4,  10'd3  },

	'd3 : { Isa::OR,  10'd12, 10'd9, 10'd2   },
	'd2 : { Isa::AND, 10'd6,  10'd3, 10'd1   },
	'd1 : { Isa::ADD, 10'd9,  10'd3, 10'd0   },

	// 'd6 : { Isa:: ADD, 10'd995, 10'd996, 10'd998 },
	// 'd5 : { Isa:: ADD, 10'd997, 10'd998, 10'd998 },

	// 'd4 : { Isa:: AND, 10'd995, 10'd996, 10'd998 },
	// 'd3 : { Isa:: AND, 10'd997, 10'd998, 10'd998 },

	// 'd2 : { Isa:: OR, 10'd995, 10'd996, 10'd998 },
	// 'd1 : { Isa:: OR, 10'd997, 10'd998, 10'd998 },

	'd0 : 'b0
};

initial foreach (u_processor_dut.registers[i]) u_processor_dut.registers[i] = $urandom;

initial begin
	foreach (instruction_v[i]) begin

		logic [Isa::REGISTER_SIZE - 1 : 0] src1;
		logic [Isa::REGISTER_SIZE - 1 : 0] src2;
		logic [Isa::REGISTER_SIZE - 1 : 0] expected;
		logic [Isa::REGISTER_SIZE - 1 : 0] actual;
		logic [$clog2(Isa::REGISTER_SIZE): 0] shift_amount;

		instruction = instruction_v[i];

		if (instruction == 'b0) begin
			#100
			$display("[NOOP] %05t: instr[%02d] op=%3s rd=%04d rs1=%04d rs2=%04d",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2
			);
			continue;
		end

		src1 = u_processor_dut.registers[instruction.rs_1];
		src2 = u_processor_dut.registers[instruction.rs_2];
		shift_amount = { 1'b0, src2[$clog2(Isa::REGISTER_SIZE) - 1 : 0] };

		case (instruction.op_code)
			Isa::ADD: expected = src1 + src2;
			Isa::MUL: expected = src1 * src2;
			Isa::AND: expected = src1 & src2;
			Isa::OR : expected = src1 | src2;
			Isa::SHL: expected = (src1 << shift_amount) | (src1 >> (Isa::REGISTER_SIZE - shift_amount));
			Isa::SHR: expected = (src1 >> shift_amount) | (src1 << (Isa::REGISTER_SIZE - shift_amount));
			default:  expected = 'x;
		endcase

		// wait until the processor exits the STORE state
		@(negedge clock iff (u_processor_dut.current_state == u_processor_dut.STORE));
		// then wait until the next clock edge to check the result
		@(negedge clock);

		actual = u_processor_dut.registers[instruction.rd];

		if (expected === actual) begin
			$display("[PASS] %05t: instr[%02d] op=%3s rd=%04d rs1=%04d rs2=%04d -> %h",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2, actual
			);
		end else begin
			$error("[FAIL] %05t: instr[%02d] op=%3s rd=%04d rs1=%04d rs2=%04d -> expected=%h actual=%h",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2, expected, actual
			);
		end
	end
end

endmodule: ProcessorTb
