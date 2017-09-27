module ALU_ADD (in_a/*连接累加器*/, in_b/*连接BUS*/, cin/*进位标志位*/, out_sum/*连接到总线*/, cout/*连接状态寄存器*/)
// 输入输出定义
input in_a, in_b, cin;
output out_sum , cout;
wire [7:0] in_a;
wire [7:0] in_b;
wire cin, t;
wire [7:0] out_sum;
wire cout;
//我其实只是想记录一下怎么实例化模块   你相信吗？
adder8 ADDER(//实例化8位加法器
.a 		(in_a),
.b      (in_b),
.cin    (cin),
.sum    (out_sum),//output
.co     (cout)  //output
);
endmodule

//加法器
module adder8 (
//input:
a,
b,
cin, //carry in
//output:
sum, //sum of a and b
co //carry out
);
input [7:0] a;
input [7:0] b;
input cin;
output wire [7:0] sum;
output wire co;
wire c0, c1, c2, c3, c4, c5, c6, c7, c8;
wire g0, g1, g2, g3, g4, g5, g6, g7;
wire p0, p1, p2, p3, p4, p5, p6, p7;
wire s0, s1, s2, s3, s4, s5, s6, s7;
assign g0=a[0]&b[0];
assign g1=a[1]&b[1];
assign g2=a[2]&b[2];
assign g3=a[3]&b[3];
assign g4=a[4]&b[4];
assign g5=a[5]&b[5];
assign g6=a[6]&b[6];
assign g7=a[7]&b[7];
assign p0=a[0]|b[0];
assign p1=a[1]|b[1];
assign p2=a[2]|b[2];
assign p3=a[3]|b[3];
assign p4=a[4]|b[4];
assign p5=a[5]|b[5];
assign p6=a[6]|b[6];
assign p7=a[7]|b[7];
assign c0=cin;
assign c1=g0|p0&c0;
assign c2=g1|p1&c1;
assign c3=g2|p2&c2;
assign c4=g3|p3&c3;
assign c5=g4|p4&c4;
assign c6=g5|p5&c5;
assign c7=g6|p6&c6;
assign c8=g7|p7&c7;
assign s0=a[0]^b[0]^c0;
assign s1=a[1]^b[1]^c1;
assign s2=a[2]^b[2]^c2;
assign s3=a[3]^b[3]^c3;
assign s4=a[4]^b[4]^c4;
assign s5=a[5]^b[5]^c5;
assign s6=a[6]^b[6]^c6;
assign s7=a[7]^b[7]^c7;
assign sum = {s7,s6,s5,s4,s3,s2,s1,s0};
assign co = c8;
endmodule