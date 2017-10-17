
// `include "register.v"	/*寄存器模型*/
// `include "w_uaddr.v"	/*微地址生成器*/
// `include "w_uPC.v"	/*upc生成器*/
// `include "decode.v"	/*3-8译码器*/
// `include "alu.v"
module poco(clk,
	input  wire [23:0] in_rom,	/*ROM 数据输入*/
	input  wire 	   rst, 	/*重置设置 0为清空*/
	output wire [7:0]  out_rom,	/*ROM 地址输出*/
	output wire 	   out_clk,		/*时钟输出*/
	output wire [7:0]  out_ram,	/*RAM 地址输出*/
	inout  wire [7:0]  io_ram,	/*RAM 数据通路*/
	output wire        r_ram,	/*RAM 读信号线*/
	output wire        w_ram,	/*RAM 写信号线*/
)
assign  out_clk = clk;	//ROM数据缓存锁存信号
wire [7:0] dbus;/*CPU内部总线*/
wire [7:0] reg_ch_1_in; /*低写寄存器选择线*/
wire [7:0] reg_ch_1_out;/*低读寄存器选择线*/
wire [7:0] reg_ch_2_in; /*高写寄存器选择线*/
wire [7:0] reg_ch_2_out;/*高读寄存器选择线*/


decode decode_1_out(
.in 	(in_rom[15:13]),
.open	(in_rom[11]),
.out 	(reg_ch_1_out)
);
decode decode_1_in(
.in 	(in_rom[15:13]),
.open	(in_rom[12])
.out 	(reg_ch_1_in));
decode decode_2_out(
.in 	(in_rom[20:18]),
.open	(in_rom[16]),
.out 	(reg_ch_2_out));
decode decode_2_in(
.in 	(in_rom[20:18]),
.open	(in_rom[17]),
.out 	(reg_ch_2_in));

//实例化寄存器
register pc(/*PC寄存器*/
.clk		(clk),
.in			(dbus),
.out		(dbus)
.out_allow	(reg_ch_2_out[0]|reg_ch_1_out[0]),
.in_allow	(reg_ch_1_in[0] |reg_ch_2_in[0]),
.rst		(rst)
)
register ir(/*指令寄存器*/
.clk		(clk),
.in	  		(dbus),
.out		(dbus),
.out_allow	(reg_ch_2_out[1]|reg_ch_1_out[1]),
.in_allow	(reg_ch_1_in[1] | reg_ch_2_in[1]),
.rst		(rst)
)
register mar(/*MAR寄存器 接收总线的输入 输出只指向RAM的地址线*/
.clk		(clk),
.in			(dbus),
.out		(out_ram),
.out_allow	(reg_ch_2_out[2]|reg_ch_1_out[2]),
.in_allow	(reg_ch_1_in[2] |reg_ch_2_in[2]),
.rst		(rst)
)
register mdr(/*MDR寄存器TODO 重新设置与RAM进行数据交互*/
.clk		(clk),
.in			(dbus),
.out		(dbus),
.out_allow	(reg_ch_2_out[3]|reg_ch_1_out[3]),
.in_allow	(reg_ch_1_in[3] |reg_ch_2_in[3]),
.rst		(rst)
)
wire [7:0] state_to_alu;
wire [7:0] state_to_reg;
register state(/*状态寄存器*/
.clk		(clk),
.in			(state_to_reg),
.out		(state_to_alu),
.out_allow	(1),//TODO 待定
.in_allow	(), //TODO 待定
.rst		(rst)
)
wire [7:0] alu_in_a;
register falu(/*指定与ALU的in_a连接的寄存器 与MAR寄存器的设置有相同之处*/
.clk		(clk),
.in			(dbus),
.out		(alu_in_a),
.out_allow	(reg_ch_2_out[4]|reg_ch_1_out[4]),
.in_allow	(reg_ch_1_in[4] |reg_ch_2_in[4]),
.rst		(rst)
)
register fl(/*超长数据高位暂存区*/
.clk		(clk),
.in			(dbus),
.out		(dbus),
.out_allow	(reg_ch_2_out[5]|reg_ch_1_out[5]),
.in_allow	(reg_ch_1_in[5] |reg_ch_2_in[5]),
.rst		(rst)
)
register baseaddr(/*基址寄存器*/
.clk		(clk),
.in			(dbus),
.out		(dbus),
.out_allow	(reg_ch_2_out[6]|reg_ch_1_out[6]),
.in_allow	(reg_ch_1_in[6] |reg_ch_2_in[6]),
.rst		(rst)
)
register r0(/*普通数据寄存器*/
.clk		(clk),
.in			(dbus),
.out		(dbus),
.out_allow	(reg_ch_2_out[7]|reg_ch_1_out[7]),
.in_allow	(reg_ch_1_in[7] |reg_ch_2_in[7]),
.rst		(rst)
)

//实例化upc硬件
wire [7:0] _ua;
w_uaddr uaddr(
.clk	(clk),
.in_pc	(ir[7:4]),
.in_upc	(),//等待微程序输入
.op 	(),//等待微程序输入
.out 	(_ua)
)
w_uPC upc(
.clk	(clk),
.rst 	(rst),
.ld 	(),//TODO 由取出的微指令指定取指方式
.in 	(_ua),
.out 	(out_rom)/*ROM 地址输出*/
)

//实例化ALU
alu alu_8(
.clk 	(clk),
.op 	(in_rom[23:21]),/*选择要执行的操作*/
.in_a 	(alu_in_a),/*连接累加器*/
.in_b 	(dbus),/*连接BUS*/
.cin 	(state_to_alu[7]),/*进位标志位*/
.out	(dbus),/*连接到总线*/
.cout 	(state_to_reg[7])/*连接状态寄存器*/
)
endmodule