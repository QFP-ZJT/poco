/**
 * 模块描述
 * 时钟上升沿锁存数据
 * 个人觉得不需要清零，没有设置清零端
 * 输入:		时钟脉冲
 *			8位wire类型的in_data(数据)
 *			1位wire类型的cin(初始进位)
 *			1位wire类型的lock_in_data	 (输入数据锁存控制信号)
 *			1位wire类型的lock_out_data(输出数据锁存控制信号)
 * 输出:		8位wire类型的out_data(数据)
 *			1位wire类型的cout(溢出判断)
 */
module ALU_ADD (clk/*时钟*/, in_data/*8位输入数据*/, cin, out_data,cout, lock_in_data,lock_out_data)
// 输入输出定义
input clk, in_data, cin, lock_in_data, lock_out_data;
output out_data, cout;
// 线网和寄存器声明
wire [7:0] in_data;
wire [7:0] out_data;
wire cin, cout, lock_in_data, lock_out_data;

wire[7:0] sum;//连接并行加法模块
wire[7:0] co  //连接并行加法模块
reg [7:0] reg_A;   		//A数据
reg [7:0] reg_out_data; //结果数据
reg reg_cout;

//数据流描述
assign out_data = reg_out_data;
assign cout = reg_cout;

//模块连接
adder8 ADDER(//实例化8位加法器
.a 		(reg_A),
.b      (in_data),
.cin    (cin),
.sum    (sum),//output
.co     (co)  //output
);

//行为描述
always @(posedge clk) begin    // TODO 此出的begin  end  是否可以换成fork  join  换成并行的结构？？？？
	if (lock_in_data) begin
		reg_A <= in_data;
	end
	if (lock_out_data) begin
		reg_out_data <= sum;   //结果缓存
		reg_cout <= co;  //溢出位缓存
	end
end
endmodule




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