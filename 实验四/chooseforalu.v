module chooseforalu(
    input clk,
    input [7:0] A,
    input [7:0] B,
    input in_A,
    input in_B,
    output wire [7:0] out
);
    assign out = (in_A==1'b1) ? A : B;
endmodule