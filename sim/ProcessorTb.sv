`default_nettype none
`timescale 1ps/1ps

// TODO: `timescale 1ns/1ps
// TODO: document testbench
module ProcessorTb;

logic clock = 0;
initial forever #5 clock = ~clock;

logic reset = 0;
initial #10 reset = 1;

Isa::Instruction instruction = 0; // TODO inst can have two formats

// RamPort u_ram_port(.i_clock(clock));

// SinglePortRam u_ram(
// 	.i_clock(clock),
// 	.ram_port(u_ram_port)
// );

Processor u_processor_dut(
	.i_clock(clock),
	.i_reset(reset),
	.i_instruction(instruction)
);

Isa::Instruction instruction_v [26:0] = '{ // TODO inst can have two formats
	'd26: 'b0,
	'd25: { Isa::AND, 10'd1023, 10'd1023, 10'd1023 },
	'd24: { Isa::MUL, 10'd1022, 10'd1022, 10'd1022 },
	'd23: { Isa::ADD, 10'd1021, 10'd1021, 10'd1021 },
	'd22: { Isa::OR,  10'd1020, 10'd1020, 10'd1020 },
	'd21: { Isa::SHL, 10'd1019, 10'd1019, 10'd1019 },
	'd20: { Isa::SHR, 10'd1018, 10'd1018, 10'd1018 },

	'd19: { Isa::OR,  10'd1022, 10'd1019, 10'd1018 },
	'd18: { Isa::SHR, 10'd1022, 10'd1019, 10'd1017 },
	'd17: { Isa::ADD, 10'd1022, 10'd1019, 10'd1016 },
	'd16: { Isa::MUL, 10'd1022, 10'd1019, 10'd1015 },
	'd15: { Isa::SHL, 10'd1022, 10'd1019, 10'd1014 },
	'd14: { Isa::AND, 10'd1022, 10'd1019, 10'd1013 },

	'd13: { Isa::AND, 10'd1014, 10'd1013, 10'd1012 },
	'd12: { Isa::ADD, 10'd1011, 10'd1010, 10'd1009 },
	'd11: { Isa::OR,  10'd1008, 10'd1007, 10'd1006 },
	'd10: { Isa::MUL, 10'd1005, 10'd1004, 10'd1003 },

	'd9 : { Isa::OR,  10'd1012, 10'd1009, 10'd1002 },
	'd8 : { Isa::AND, 10'd1006, 10'd1003, 10'd1001 },
	'd7 : { Isa::ADD, 10'd1009, 10'd1003, 10'd999  },

	'd6 : { Isa:: ADD, 10'd995, 10'd996, 10'd998 },
	'd5 : { Isa:: ADD, 10'd997, 10'd998, 10'd998 },

	'd4 : { Isa:: AND, 10'd995, 10'd996, 10'd998 },
	'd3 : { Isa:: AND, 10'd997, 10'd998, 10'd998 },

	'd2 : { Isa:: OR, 10'd995, 10'd996, 10'd998 },
	'd1 : { Isa:: OR, 10'd997, 10'd998, 10'd998 },

	'd0 : 'b0
};

initial foreach (u_processor_dut.registers[i]) u_processor_dut.registers[i] = $urandom;

initial begin
	foreach (instruction_v[i]) begin

		logic [Isa::REGISTER_SIZE - 1 : 0] src1;
		logic [Isa::REGISTER_SIZE - 1 : 0] src2;
		logic [Isa::REGISTER_SIZE - 1 : 0] expected;
		logic [Isa::REGISTER_SIZE - 1 : 0] actual;

		instruction = instruction_v[i];

		if (instruction == 'b0) begin
			$display("[NOOP] %05t: instr[%02d] op=%3s rd=%04d rs1=%04d rs2=%04d",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2
			);
			continue; // TODO check if we really must wait #1060;
		end

		src1 = u_processor_dut.registers[instruction.rs_1];
		src2 = u_processor_dut.registers[instruction.rs_2];

		case (instruction.op_code)
			Isa::ADD: expected = src1 + src2;
			Isa::MUL: expected = src1 * src2;
			Isa::AND: expected = src1 & src2;
			Isa::OR : expected = src1 | src2;
			Isa::SHL: expected = src1 << src2[$clog2(Isa::REGISTER_SIZE) - 1 : 0];
			Isa::SHR: expected = src1 >> src2[$clog2(Isa::REGISTER_SIZE) - 1 : 0];
			default:  expected = 'x;
		endcase

		// wait until the processor enters enters in the ALU_STORE state
		@(posedge clock iff (u_processor_dut.current_state == u_processor_dut.STORE));
		// then wait until the next clock edge, when the writing happens
		@(posedge clock);

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
