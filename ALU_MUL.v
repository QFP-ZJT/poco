module ALU_MUL(mul_a, mul_b, mul_out);
// 期望的是乘法阵列的方式实现的
input [7:0] mul_a, mul_b;
output [15:0] mul_out;
assign mul_out = mul_b * mul_a;
endmodule