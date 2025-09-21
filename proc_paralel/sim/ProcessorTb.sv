`default_nettype none


module ProcessorTb();
parameter int CLOCK_TIME = 1;
logic clock = 0;
initial forever #CLOCK_TIME clock = ~clock;

logic reset = 0;
initial #2 reset = 1;

//Isa::Instruction instruction = 0;
localparam DATA_WIDTH = 16;
dual_port_ram_if #(.DATA_WIDTH(DATA_WIDTH)) u_if_dual_port_a(.clk(clock));
dual_port_ram_if #(.DATA_WIDTH(DATA_WIDTH)) u_if_dual_port_b(.clk(clock));
dual_port_ram #(.DATA_WIDTH(DATA_WIDTH)) u_dual_port_a
	(
		.clk(clock),
		.a(u_if_dual_port_a),
		.b(u_if_dual_port_b)
	);

Processor u_processor_dut(
	.i_clock(clock),
	.i_reset(reset),
	.mem_a(u_if_dual_port_a),
	.mem_b(u_if_dual_port_b)
);



Isa::AluPacket instruction_v [7:0] = '{
	'd0: 'hE210,
	'd6: 'hC210,
	'd5: 'hA210,
	'd4: 'h8210,
	'd3: 'h6210,
	'd2: 'h4210,
	'd1: 'h2210,
	'd7 : 'h0610
};

initial begin
	int next_address = 0;

	
	#5;
	foreach (instruction_v[i]) begin

		u_dual_port_a.mem[next_address] = instruction_v[i];
		next_address++;

		


	end
	// duas vezes o tempo de espera do clock
	#CLOCK_TIME;
	#CLOCK_TIME;
	u_processor_dut.rb.regs [0] = 30;
	u_processor_dut.rb.regs [1] = 10;
	u_processor_dut.rb.regs [1] = 20;
end

endmodule: ProcessorTb
