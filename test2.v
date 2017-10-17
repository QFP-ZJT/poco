/** 
 * 时钟控制ROM读完成算数运算指令
 * 当前实验的顶层设计模型
 * 继承实验一
 */
module test_1(
	input  wire		  in_clk, /*时钟输入源*/
	input  wire		  rst,    /*清空指令  为0时，清空*/
	input  wire 	  run,	  /*是否处于运行状态*/
	input  wire[23:0] in_rom, /*ROM内存读入*/
	input  wire       in_rom_efficient,/*rom 输入指令有效  为1时有效*/
	output wire[7:0]  addr_rom,/*ROM地址输出*/
	output wire		  out_clk,/*ROM锁存指令*/
	output wire		  wupc,	  /*设置ROM处于读状态*/
	output wire[31:0] led,	  /*led灯连接总线*/
    inout  wire[7:0]  dataram, /*连接ram*/ 
    output wire[7:0]  addr_ram,/*RAM地址输出*/
    output wire		  wram,	  /*设置RAM处于写状态*/
    output wire		  rram	  /*设置ROM处于读状态*/
);
	/**
	 *    led[7:0]		连接dbus
	 *	  led[15:8]		连接upc
	 *	  led[23:16]	连接state
	 */



	/*总线定义*/
	wire [7:0] dbus;		/*CPU内部总线*/
    /*定义有效的rom指令输入*/
	wire [23:0] in_rom_e;
	wire clk;
	wire [7:0] reg_ch_l_w; 	/*低位指定的写寄存器选择线	(24位微程序控制指令)*/
	wire [7:0] reg_ch_l_r;	/*低位指定的读寄存器选择线*/
	wire [7:0] reg_ch_h_w; 	/*高位指定的写寄存器选择线*/
	wire [7:0] reg_ch_h_r;	/*高位指定的读寄存器选择线*/
	wire [7:0] reg_ch_w; 	/*写寄存器选择线*/
	wire [7:0] reg_ch_r;	/*读寄存器选择线*/
	/**
	 *	reg_sta   0   
	 *           cin  
	 */
	wire [7:0] toreg_sta;		/*状态连接线*/
	wire [7:0] fromreg_sta;		/*状态连接线*/
	wire [7:0] reg_sta_w; 	/*写寄存器选择线*/
	wire [7:0] reg_sta_r;	/*读寄存器选择线*/

	wire [7:0] addtoalu;	/*累加器连接ALU*/
	wire [7:0] toans;		/*连接到结果寄存器*/
	
	//设置时钟是否处于输入状态
	assign clk = run ? in_clk : 1'bz;				/*若run为true 则接入时钟，否则断开时钟*/
	// ROM 设置
	assign out_clk = clk;						/*cpuIR    考虑是否需要取反   是演绎验证结果*/
	assign w_uPC = 1'b0;
	assign in_rom_e = in_rom_efficient ? in_rom : 24'b000000000000000000000000;
	// 寄存器状态控制器
	assign reg_ch_w = reg_ch_l_w | reg_ch_h_w ; /*写线汇总*/
	assign reg_ch_r = reg_ch_l_r | reg_ch_h_r;  /*读线汇总*/
    // RAM 设置
    //连接ram到dbus
    //assign dbus =  dataram;                     /* 实验二等待验证这种设计的正确性  引起太多错误  禁用*/
    //ram地址输入   in_rom_e[5] = 1的时候连接MAR
    wire [7:0] addr_frommar;
    wire [7:0] addr_frompc;
    assign addr_ram = (in_rom_e[5]) ? addr_frommar : addr_frompc;
    // 读写控制
    assign wram = ~in_rom_e[4];
    assign rram = ~in_rom_e[3];
	// 临时输出显示
	assign led[7:0] = dbus;
	assign led[15:8] = addr_frompc;
	assign led[23:16] = addr_ram;

	/*寄存器的选取*/
	decode decode_l_r(			/*低位指定的读寄存器*/
		.in 	(in_rom_e[15:13]),
		.open	(in_rom_e[11]),
		.out 	(reg_ch_l_r)
	);
	decode decode_l_w(			/*低位指定的写寄存器*/
		.in 	(in_rom_e[15:13]),
		.open	(in_rom_e[12]),
		.out 	(reg_ch_l_w)
	);
	decode decode_2_r(			/*高位指定的读寄存器*/
		.in 	(in_rom_e[20:18]),
		.open	(in_rom_e[16]),
		.out 	(reg_ch_h_r)
	);
	decode decode_2_w(			/*高位指定的写寄存器*/
		.in 	(in_rom_e[20:18]),
		.open	(in_rom_e[17]),
		.out 	(reg_ch_h_w)
	);

	/**
	 * upc地址生成 
	 */
	w_uPC upc(
		.clk	(clk),
		.rst	(rst),
		.ld		(in_rom_e[2]),
		.op		(in_rom_e[1:0]),
		.in_upc	(in_rom_e[20:13]),
		.in_pc	(4'b0000),
		.out	(addr_rom)
	);

	/*
	 *  寄存器的编号
	 *	PC(0) IR(1) MAR(2) MDR(3) 状态寄存器 累加器(4) 数据寄存器(5) 基址寄存器(6) R0(7)
	 */
	register reg_add(			/*累加寄存器*/
		.clk		(clk),
		.in			(dbus),
		.out		(addtoalu),
		.out_allow	(1'b1),
		.in_allow	(reg_ch_w[4]),
		.rst		(rst)
	);

	register reg_ans(			/*结果锁存寄存器*/
		.clk		(clk),
		.in			(toans),
		.out		(dbus),
		.out_allow	(reg_ch_r[5]),
		.in_allow	(reg_ch_w[5]),
		.rst		(rst)
	);

	register reg_state(			/*状态寄存器 TODO */
		.clk		(clk),
		.in			(toreg_sta),
		.out		(fromreg_sta),
		.out_allow	(1'b1),			//应该由op命令计算出  有点晕 TODO
		.in_allow	(1'b0),
		.rst		(rst)
	);

	registerformdr reg_mdr(				//实验一 临时设置的MDR从ROM中抓取数据
                                    //实验二 mdr的数据来源为RAM TODO 更改 暂时取消
		.clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[3]),		
		.in_allow	(reg_ch_w[3]),
		.ioram		(dataram),
		.rwforram	(in_rom_e[4:3]),
		.rst		(rst)
	);

    registerformar reg_mar(         //MAR寄存器
        .clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[2]),		
		.in_allow	(reg_ch_w[2]),
		.rst		(rst),
        .toram      (addr_frommar)
    );

     registerformar reg_pc(         //PC寄存器
        .clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[0]),		
		.in_allow	(reg_ch_w[0]),
		.rst		(rst),
        .toram      (addr_frompc)
    );

	register reg_r0(				//通用寄存器R0
		.clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[7]),		
		.in_allow	(reg_ch_w[7]),
		.rst		(rst)
	);

	register reg_r1(				//通用寄存器R1
		.clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[6]),		
		.in_allow	(reg_ch_w[6]),
		.rst		(rst)
	);

	w_alu alu(							/*运算单元*/
		.clk		(clk),
		.op			(in_rom_e[23:21]) 	/*选择要执行的操作*/,
		.in_a		(addtoalu)			/*连接累加器*/, 
		.in_b		(dbus)				/*连接BUS*/,
		.cin		(fromreg_sta[0])	/*进位标志位*/, 
		.out		(toans)				/*送到ans寄存器中*/,
		.cout		(toreg_sta[0])		/*连接状态寄存器*/
	);


endmodule



// 微程序设计指令的地址生成器
module w_uPC(input clk,input rst,input ld,input [1:0] op,
			input [7:0] in_upc,input [3:0] in_pc,output wire [7:0] out);
		/**
		*	rst = 0 清零
		*	rst = 1, ld = 0; 直传 out = in
		*		op[1:0] == 01 in_pc;
		*		op[1:0] == 10 in_upc;
		*	rst = 1, ld = 1,op[1:0] == 00; 计数
		*	可能的更改:reg直接输出
		*/
		
		reg [7:0] value;
		always @(posedge clk) begin
			if (!rst)
				value <= 8'b00000000;	
			else begin
				case({ld,op[1:0]})
					3'b100: value <= value + 1;
					3'b001: value <= 8'b0;//等待pc转换
					3'b010: value <= in_upc;
				endcase
			end
		end
		assign out = value;
endmodule


/**
 *	普通寄存器设计模型
 */
module register(
	input clk, input [7:0] in, output wire [7:0] out,
	input out_allow,input in_allow,input rst);

		/** 
		*	rst = 0   清零
		*	in_allow  锁存数据
		*	out_allow 输出数据
		*/
		reg  [7:0] mem;
		always @(posedge clk) begin
			if (!rst)
				mem <= 8'b00000000;
			else if (in_allow)
				mem <= in;
		end

		assign out = out_allow ? mem : 8'bzzzzzzzz;
endmodule

/** 
 *  MDR专用寄存器 http://blog.sina.com.cn/s/blog_7bf0c30f0100tedd.html
 */
module registerformdr(
	input clk, input [7:0] in, output wire [7:0] out,
	input out_allow,input in_allow,input rst,
    inout wire [7:0] ioram/*连接ram*/,
    input wire [1:0] rwforram /*对ram输出还是接收数据*/
    );

		/** 
		*	rst = 0   清零
		*	in_allow  锁存数据
		*	out_allow 输出数据
        *   rwforram[1] ioram 对外输出
        *   rwforram[0] ioram 对内输入
		*/
		reg  [7:0] mem;
		always @(posedge clk) begin
			if (!rst)
				mem <= 8'b0;
			else if (in_allow)
				mem <= in;
			else if (rwforram[0]) //read ram
				mem <= ioram;
		end
		assign out = out_allow ? mem : 8'bzzzzzzzz;

		//写 ram
		assign ioram = rwforram[1] ? mem : 8'bz;
		
endmodule

/**
 *  for MAR 专用寄存器
 */
module registerformar(
	input clk, input [7:0] in, output wire [7:0] out,
	input out_allow,input in_allow,input rst, output wire [7:0] toram);

		/** 
		*	rst = 0   清零
		*	in_allow  锁存数据
		*	out_allow 输出数据
		*/
		reg  [7:0] mem;
		always @(posedge clk) begin
			if (!rst)
				mem <= 8'b00000000;
			else if (in_allow)
				mem <= in;
		end
        assign toram = mem;
		assign out = out_allow ? mem : 8'bzzzzzzzz;
endmodule

/**
 * 组合逻辑的ALU设计电路
 * clk,op 选择要执行的操作,
 * in_a连接累加器, in_b连接BUS,cin进位标志位, out连接到总线,cout连接状态寄存器
 */
module w_alu (
	input clk, input [2:0] op/*选择要执行的操作*/,input [7:0] in_a/*连接累加器*/, input [7:0] in_b/*连接BUS*/,
	input cin/*进位标志位*/,output reg [7:0] out/*连接到总线*/,output reg cout/*连接状态寄存器*/);
		/**
		*	op 000 加法
		*	op 001 减法
		*	op 010 乘法
		*	op 011 对in_b取非	
		*	op 100 in_a,in_b异或
		*	op 101 in_b,自增1     为PC服务
		*	op 110 备用
		*	op 111 不输出
		*/

		always @(*) begin
			case(op)
				3'b000:	 {cout,out[7:0]} <= in_a+in_b+cin;
				3'b001:  {cout,out[7:0]} <= in_a-in_b-cin;//逻辑有点混乱
				3'b010:  out[7:0] <= in_a*in_b;
				3'b011:  out[7:0] <= ~in_b;
				3'b100:  out[7:0] <= in_a^in_b;
				3'b101:  out[7:0] <= in_b+1;
				3'b111:  out[7:0] <= 8'bzzzzzzzz;
			endcase	
		end
endmodule

/**
 *	译码器  三 - 八   当且仅当open为1的时候
 */
module decode(
	input [2:0] in,
	input open,
	output reg [7:0] out);
	always @(*)
		if (open)
			case(in)
			3'b000:  out <= 8'b00000001;
			3'b001:  out <= 8'b00000010;
			3'b010:  out <= 8'b00000100;
			3'b011:  out <= 8'b00001000;
			3'b100:  out <= 8'b00010000;
			3'b101:  out <= 8'b00100000;
			3'b110:  out <= 8'b01000000;
			3'b111:  out <= 8'b10000000;
			endcase
		else
			out <= 8'b00000000;
endmodule