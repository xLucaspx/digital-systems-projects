module dual_port_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input logic clk,
    dual_port_ram_if.MEM a,
    dual_port_ram_if.MEM b
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Port A operations
    always_ff @(posedge clk) begin
        
    end

    assign a.rdata = mem[a.addr];

    // Port B operations
    always_ff @(posedge clk) begin
        if (b.en) begin
            if (b.we)
                mem[b.addr] <= b.wdata;
        end
        if (a.en) begin
            if (a.we)
                mem[a.addr] <= a.wdata;
        end
    end

    assign b.rdata = mem[b.addr];

endmodule