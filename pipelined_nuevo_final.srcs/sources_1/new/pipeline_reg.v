module pipeline_reg #(
    parameter WIDTH = 32,
    parameter RESET_VALUE = 0,
    parameter FLUSH_VALUE = 0
)(
    input clk,
    input reset,
    input en,
    input flush,

    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

always @(posedge clk or posedge reset) begin
    if(reset)
        q <= RESET_VALUE;
    else if(flush)
        q <= FLUSH_VALUE;
    else if(en)
        q <= d;
end

endmodule