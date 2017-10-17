module ALU_SUB(clk,in_a,in_b,cin,cout,out_sum,cout)
input clk, in_a, in_b, cin;
output out_sum , cout;
wire [7:0] in_a;
wire [7:0] in_b;
wire cin, t;
wire [7:0] out_sum;
wire cout;
wire [7:0] temp;
fan_1 FAN_1(
.a, (in_a),
.b, (in_b),
.cin,(cin)
//溢出判断
);
ALU_ADD add(
.in_a, (in_a),
.in_b, (temp),
.cin, (1'b0),
.out_sum, (out_sum),
.cout, (cout)
);
endmodule

module fan_1(a,b,cin,co_t)
input a,cin,co_t;
output b;
wire [7:0] a,b;
wire [7:0] temp;
wire [7:0] cin_t;
wire co_t;
cin_t[7:1] = 7'b000000;
assign cin_t[0] = cin;
assign temp = ~a;
ALU_ADD add(
.in_a, (temp),
.in_b, (cin),
.cin, (cin_t),
.out_sum, (b),
.cout, (co_t)
);
endmodule