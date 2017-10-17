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
    /*寄存器写读控制器*/
	wire [7:0] reg_ch_w; 	/*写寄存器选择线*/
	wire [7:0] reg_ch_r;	/*读寄存器选择线*/

    /*状态寄存器输出总线*/
	wire [7:0] reg_sta;		/*状态连接线*/

    /*累加寄存器 定义输出连线*/
	wire [7:0] addtoalu;	/*累加器连接ALU*/
	wire [7:0] toans;		/*连接到结果寄存器*/
	
	//设置时钟是否处于输入状态
	assign clk = run ? in_clk : 1'bz;				/*若run为true 则接入时钟，否则断开时钟*/
	// ROM 设置
	assign out_clk = clk;						/*cpuIR    考虑是否需要取反   是演绎验证结果*/
	assign w_uPC = 1'b0;
	assign in_rom_e = in_rom_efficient ? in_rom : 24'b0;
    // RAM 设置
    //连接ram到dbus
    //assign dbus =  dataram;                     /* 实验二等待验证这种设计的正确性  引起太多错误  禁用*/
    //ram地址输入   in_rom_e[5] = 1的时候连接MAR
    wire [7:0] addr_frommar;
    wire [7:0] addr_frompc;
    // 写读控制
    assign wram = ~in_rom_e[4];
    assign rram = ~in_rom_e[3];

	// 临时输出显示
	assign led[7:0] = dbus;
	assign led[15:8] = addr_frompc;
	assign led[23:16] = addr_ram;

    /*寄存器写读控制器生成器*/
    wrcontroller wrcontroller(
        .reg_ch_l   (in_rom_e[15:13]), 	    /*低位指定的寄存器选择线	(24位微程序控制指令)*/
	    .reg_ch_h   (in_rom_e[20:18]), 	    /*高位指定的寄存器选择线*/
	    .l_wr       (in_rom_e[12:11]),	    /*低位指定的寄存器 写读控制器*/
        .h_wr       (in_rom_e[17:16]),      /*高位指定的寄存器 写读控制器*/
	    .reg_ch_w   (reg_ch_w),             /*写寄存器选择线*/
	    .reg_ch_r	(reg_ch_r)              /*读寄存器选择线*/
    );

    /**
     *
     */
     addrforram addrforram(
        .addr_frommar   (addr_frommar),
        .addr_frompc    (addr_frompc),    //ram 地址来源
        .in_rom_e       (in_rom_e[5]),             //选择信号
        .addr_ram       (addr_ram)  //地址输出
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

    registerforoutput reg_mar(         //MAR寄存器
        .clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[2]),		
		.in_allow	(reg_ch_w[2]),
		.rst		(rst),
        .toram      (addr_frommar)
    );

    registerforoutput reg_pc(         //PC寄存器
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

    /**
     * alu 运算功能   需要状态位的仅为标志
     */
	w_alu alu(							/*运算单元*/
		.clk		(clk),
        .rst        (rst),              /*清空*/
		.op			(in_rom_e[23:21]) 	/*选择要执行的操作*/,
		.in_a		(addtoalu)			/*连接累加器*/, 
		.in_b		(dbus)				/*连接BUS*/,
        .controllerforstate (in_rom_e[8:6]),/*状态寄存器控制位*/
		.out		(toans)				/*送到ans寄存器中*/,
        .mem        (reg_sta)           /*状态寄存器输出*/
	);
endmodule



// 微程序设计指令的地址生成器   乘法生成器
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
module registerforoutput(
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

// /**
//  * 为状态寄存器设置的
//  */
// module registerforstate(
// 	input clk, 
//     input in,
//     input in_allow,
//     output wire [7:0] out,
// 	input rst);

// 		/** 
// 		*	rst = 0   清零
// 		*	in_allow  锁存数据
// 		*	
// 		*/
		
// endmodule

/**
 * 组合逻辑的ALU设计电路
 * clk,op 选择要执行的操作,
 * in_a连接累加器, in_b连接BUS,cin进位标志位, out连接到总线,cout连接状态寄存器
 */
module w_alu (
	input clk, input rst,input [2:0] op/*选择要执行的操作*/,input [7:0] in_a/*连接累加器*/, input [7:0] in_b/*连接BUS*/,
    input wire [2:0] controllerforstate,/*状态寄存器控制器*/
	output reg [7:0] out/*连接到总线*/,output reg [7:0] mem/*状态寄存器的输出*/);
		/**
		*	op 000 加法
		*	op 001 减法
		*	op 010 乘法
		*	op 011 对in_b取非	
		*	op 100 in_a,in_b异或
		*	op 101 in_b,自增1     为PC服务
		*	op 110 备用
		*	op 111 不输出
        *
        *   状态寄存器 若结果全为0 则判断最终的结果的为1   即相等
		*/
        wire [7:0] in_allow;
        reg cout_add;reg cout_sub;
        wire equal;/*判断输出是否为全0*/
        assign equal = out[0] | out[1] | out[2] | out[3] | out[4] | out[5] | out[6] | out[7];
       decode decode(			/*低位指定的读寄存器*/
		.in 	(controllerforstate),
		.open	(1'b1),
		.out 	(in_allow));

		always @(*) begin
            if (!rst)
				mem <= 8'b0;
			case(op)
				3'b000:	 {cout_add,out[7:0]} <= in_a+in_b+mem[0];
				3'b001:  {cout_sub,out[7:0]} <= in_a-in_b-mem[1];//逻辑有点混乱
				3'b010:  out[7:0] <= in_a*in_b;
				3'b011:  out[7:0] <= ~in_b;
				3'b100:  out[7:0] <= in_a^in_b;
				3'b101:  out[7:0] <= in_b+1;
                3'b110:  out[7:0] <= in_b & in_a;
				3'b111:  out[7:0] <= 8'bzzzzzzzz;
			endcase	
            if (in_allow[0])
                mem[0] <= cout_add;
            if (in_allow[1])
                mem[1] <= cout_sub;
            if (in_allow[2])
                mem[2] <= ~equal;
            // if (in_allow[3])
            //     mem[3] <= in[3];
            // if (in_allow[4])
            //     mem[4] <= in[4];
            // if (in_allow[5])
            //     mem[5] <= in[5];
            // if (in_allow[6])
            //     mem[6] <= in[6];
        //   牺牲7号寄存器
		end
endmodule


/**
 * RAM 地址输出
 */
module addrforram(
    input [7:0] addr_frommar,
    input [7:0] addr_frompc,    //ram 地址来源
    input in_rom_e,             //选择信号
    output wire [7:0] addr_ram  //地址输出
    );
endmodule



/**
 *  寄存器写读控制器    纯组合逻辑
 */
module wrcontroller(
    input [2:0] reg_ch_l, 	    /*低位指定的寄存器选择线	(24位微程序控制指令)*/
	input [2:0] reg_ch_h, 	    /*高位指定的寄存器选择线*/
	input [1:0] l_wr,	        /*低位指定的寄存器 写读控制器*/
    input [1:0] h_wr,           /*高位指定的寄存器 写读控制器*/
	output wire [7:0] reg_ch_w, /*写寄存器选择线*/
	output wire [7:0] reg_ch_r	/*读寄存器选择线*/);

    wire [7:0] reg_ch_l_w; 	/*低位指定的写寄存器选择线	(24位微程序控制指令)*/
	wire [7:0] reg_ch_l_r;	/*低位指定的读寄存器选择线*/
	wire [7:0] reg_ch_h_w; 	/*高位指定的写寄存器选择线*/
	wire [7:0] reg_ch_h_r;	/*高位指定的读寄存器选择线*/

    decode decode_l_r(			/*低位指定的读寄存器*/
		.in 	(reg_ch_l),
		.open	(l_wr[0]),
		.out 	(reg_ch_l_r)
	);
	decode decode_l_w(			/*低位指定的写寄存器*/
		.in 	(reg_ch_l),
		.open	(l_wr[1]),
		.out 	(reg_ch_l_w)
	);
	decode decode_2_r(			/*高位指定的读寄存器*/
		.in 	(reg_ch_h),
		.open	(h_wr[0]),
		.out 	(reg_ch_h_r)
	);
	decode decode_2_w(			/*高位指定的写寄存器*/
		.in 	(reg_ch_h),
		.open	(h_wr[1]),
		.out 	(reg_ch_h_w)
	);
    // 寄存器状态控制器
	assign reg_ch_w = reg_ch_l_w | reg_ch_h_w ; /*写线汇总*/
	assign reg_ch_r = reg_ch_l_r | reg_ch_h_r;  /*读线汇总*/

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