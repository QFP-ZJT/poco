module t_poco;
wire [23:0] in_rom,	/*ROM 数据输入*/
wire 	    rst, 	/*重置设置 0为清空*/
wire [7:0]  out_rom,	/*ROM 地址输出*/
wire 	    out_clk,		/*时钟输出*/
wire [7:0]  out_ram,	/*RAM 地址输出*/
wire [7:0]  io_ram,	/*RAM 数据通路*/
wire        r_ram,	/*RAM 读信号线*/
wire        w_ram,	/*RAM 写信号线*/
endmodule