module register(
    input cpr,
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);
    always@(posedge clk)
        if(!rst)
            out <= 8'b0;
        else if(cpr)
            out <= in;
endmodule