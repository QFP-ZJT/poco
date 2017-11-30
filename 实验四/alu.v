module alu(
    input clk,
    input [7:0] A,
    input [7:0] B,
    input [3:0] op,
    output reg [7:0] out
);
    always@(*)
    begin
        case(op)
            4'b0000:   out <= A;
            4'b0001:   out <= B;
            4'b0010:   out <= B + 1;
            4'b0011:   out <= A+B;
            4'b0100:   out <= A-B;
            4'b0101:   out <= A^B;
            4'b0110:   out <= A + 1;
            4'b0111:   out <= A - 1;
            4'b1000:   out <= A&B;
            4'b1001:   out <= A|B;
            4'b1010:   out <= ~A;
            4'b1011:   out <= A*B;
            4'b1100:   out <= A/B;
            4'b1101:   out <= B - 1;
            4'b1111:   out <= 8'bz;
        endcase
    end
endmodule