`default_nettype none
`timescale 1ps/1ps

module ProcessorTb;

logic clock = 0;
initial forever #5 clock = ~clock;

logic reset = 0;
initial #10 reset = 1;

Isa::Instruction instruction = 0;

Processor u_processor_dut(
	.i_clock(clock),
	.i_reset(reset),
	.i_instruction(instruction)
);

Isa::Instruction instruction_v [25:0] = '{
	'd25: 'b0,
	'd24: { Isa::AND, 10'd1023, 10'd1023, 10'd1023 },
	'd23: { Isa::SUB, 10'd1022, 10'd1022, 10'd1022 },
	'd22: { Isa::ADD, 10'd1021, 10'd1021, 10'd1021 },
	'd21: { Isa::OR,  10'd1020, 10'd1020, 10'd1020 },

	'd20: { Isa::OR,  10'd1022, 10'd1019, 10'd1018 },
	'd19: { Isa::ADD, 10'd1022, 10'd1019, 10'd1017 },
	'd18: { Isa::SUB, 10'd1022, 10'd1019, 10'd1016 },
	'd17: { Isa::AND, 10'd1022, 10'd1019, 10'd1015 },

	'd16: { Isa::AND, 10'd1014, 10'd1013, 10'd1012 },
	'd15: { Isa::ADD, 10'd1011, 10'd1010, 10'd1009 },
	'd14: { Isa::OR,  10'd1008, 10'd1007, 10'd1006 },
	'd13: { Isa::SUB, 10'd1005, 10'd1004, 10'd1003 },

	'd12: { Isa::OR,  10'd1012, 10'd1009, 10'd1002 },
	'd11: { Isa::AND, 10'd1006, 10'd1003, 10'd1001 },
	'd10: { Isa::SUB, 10'd1012, 10'd1006, 10'd1000 },
	'd9 : { Isa::ADD, 10'd1009, 10'd1003, 10'd999  },

	'd8 : { Isa:: ADD, 10'd995, 10'd996, 10'd998   },
	'd7 : { Isa:: ADD, 10'd997, 10'd998, 10'd998   },

	'd6 : { Isa:: AND, 10'd995, 10'd996, 10'd998   },
	'd5 : { Isa:: AND, 10'd997, 10'd998, 10'd998   },

	'd4 : { Isa:: OR, 10'd995, 10'd996, 10'd998    },
	'd3 : { Isa:: OR, 10'd997, 10'd998, 10'd998    },

	'd2 : { Isa:: SUB, 10'd995, 10'd996, 10'd998   },
	'd1 : { Isa:: SUB, 10'd997, 10'd998, 10'd998   },
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
			$display("[NOOP] %0t: instr[%0d] op=%s rd=%0d rs1=%0d rs2=%0d",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2
			);
			#1060 continue;
		end

		src1 = u_processor_dut.registers[instruction.rs_1];
		src2 = u_processor_dut.registers[instruction.rs_2];

		case (instruction.op_code)
			Isa::ADD: expected = src1 + src2;
			Isa::SUB: expected = src1 - src2;
			Isa::AND: expected = src1 & src2;
			Isa::OR : expected = src1 | src2;
			default:  expected = 'x;
		endcase

		// wait until the processor enters enters in the ALU_STORE state
		@(posedge clock iff (u_processor_dut.current_state == u_processor_dut.ALU_STORE));
		// then wait until the next clock edge, when the writing happens
		@(posedge clock);

		actual = u_processor_dut.registers[instruction.rd];

		if (expected === actual) begin
			$display("[PASS] %0t: instr[%0d] op=%s rd=%0d rs1=%0d rs2=%0d -> %h",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2, actual
			);
		end else begin
			$error("[FAIL] %0t: instr[%0d] op=%s rd=%0d rs1=%0d rs2=%0d -> expected=%h actual=%h",
				$time, i, instruction.op_code, instruction.rd, instruction.rs_1, instruction.rs_2, expected, actual
			);
		end
	end
end

endmodule: ProcessorTb
