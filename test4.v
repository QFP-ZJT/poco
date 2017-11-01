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
	input  wire[7:0]  keyboard, /*按键输入*/
	input  wire       interrupt, /*按键输入 1的时候阻塞*/
	input  wire       in_rom_efficient,/*rom 输入指令有效  为1时有效*/
	output wire[7:0]  addr_rom,/*ROM地址输出*/
	output wire		  out_clk,/*ROM锁存指令*/
	output wire		  wupc,	  /*设置ROM处于读状态*/
	output wire[39:0] led,	  /*led灯连接总线*/
    inout  wire[7:0]  dataram, /*连接ram*/ 
    output wire[7:0]  addr_ram,/*RAM地址输出*/
    output wire		  wram,	  /*设置RAM处于写状态*/
    output wire		  rram	  /*设置ROM处于读状态*/
);
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
	wire [7:0] irtoupc;		/*IR to UPC*/

	//设置时钟是否处于输入状态
	assign clk = run ? in_clk : 1'bz;				/*若run为true 则接入时钟，否则断开时钟*/
	// ROM 设置
	assign out_clk = ~clk;						/*cpuIR    考虑是否需要取反   更改*/
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
	// assign led[23:16] = addr_ram;//输出灯
	assign led[31:24] = addr_rom;

	// IO 控制区
	reg [7:0] in_keyboard;
	always@(negedge clk)
	begin
		in_keyboard <= keyboard;
	end
	assign dbus = (in_rom_e[10]==1'b0 && in_rom_e[9] == 1'b1) ? in_keyboard : 8'bz;//IN

	reg [7:0] led_reg;
	assign led[23:16] = led_reg;
	always@(negedge clk)
	begin 
		if(in_rom_e[10]==1'b1 && in_rom_e[9] == 1'b0)
			led_reg <= dbus;
	end


    /*寄存器写读控制器生成器*/
    wrcontroller wrcontroller(
        .reg_ch_l   (in_rom_e[15:13]), 	    /*低位指定的寄存器选择线	(24位微程序控制指令)*/
	    .reg_ch_h   (in_rom_e[20:18]), 	    /*高位指定的寄存器选择线*/
	    .l_wr       (in_rom_e[12:11]),	    /*低位指定的寄存器 写读控制器*/
        .h_wr       (in_rom_e[17:16]),      /*高位指定的寄存器 写读控制器*/
		.next		(in_rom_e[2:0]),		/*计数	PC转换	停机*/
	    .reg_ch_w   (reg_ch_w),             /*写寄存器选择线*/
	    .reg_ch_r	(reg_ch_r)              /*读寄存器选择线*/
    );

    /**
     *	ram 地址生成线
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
		.in_pc	(irtoupc),
		.reg_sta(reg_sta),
		.interrupt(interrupt),
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
		.rst		(rst),
		.aa			(led[39:32])
	);

    registerforoutput reg_mar(         //MAR寄存器
        .clk		(clk),
		.in			(dbus),
		.inc		(1'b0),
		.out		(dbus),
		.out_allow	(reg_ch_r[2]),		
		.in_allow	(reg_ch_w[2]),
		.rst		(rst),
        .out_direct      (addr_frommar)
    );

    registerforoutput reg_pc(         //PC寄存器
        .clk		(clk),
		.in			(dbus),
		.inc		(in_rom_e[8]),
		.out		(dbus),
		.out_allow	(reg_ch_r[0]),		
		.in_allow	(reg_ch_w[0]),
		.rst		(rst),
        .out_direct      (addr_frompc)
    );

	registerforoutput reg_ir(         //IR寄存器
        .clk		(clk),
		.in			(dbus),
		.inc		(1'b0),
		.out		(dbus),
		.out_allow	(reg_ch_r[1]),		
		.in_allow	(reg_ch_w[1]),
		.rst		(rst),
        .out_direct      (irtoupc)
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
        .controllerforstate (in_rom_e[7:6]),/*状态寄存器控制位*/
		.out		(toans)				/*送到ans寄存器中*/,
        .mem        (reg_sta)           /*状态寄存器输出*/
	);
endmodule



// 微程序设计指令的地址生成器   
module w_uPC(input clk,input rst,input ld,input [1:0] op,//下地址生成方式
			input [7:0] reg_sta, 						//状态寄存器
			input interrupt,							//中断
			input [7:0] in_upc,input [7:0] in_pc,output wire [7:0] out);
		/**
		*	rst = 0 清零
		*	rst = 1, ld = 0; 直传 out = in
		*		op[1:0] == 01 in_pc;
		*		op[1:0] == 10 in_upc;
		*	rst = 1, ld = 1,op[1:0] == 00; 计数
		*	可能的更改:reg直接输出
		*/
		wire [7:0] pctoupc;
		decode_7 decode(
			.in(in_pc),
			.out(pctoupc)
		);
		reg [7:0] value;
		always @(posedge clk) begin
			if (!rst)
				value <= 8'b0;	
			else begin
				case({ld,op[1:0]})	
					3'b100: value <= value + 1;
					3'b001: value <= pctoupc;//译码
					3'b010: value <= in_upc; //jump
					3'b000:begin//无条件跳转
							value <= 8'b0000_0011;
							end
					3'b011: begin//＝＝
							if(reg_sta[2]==1)//两个数字相等  继续向下运行
								value <= 8'b0;
							else
								value <= 8'b0000_0011;		//不相等跳转到MAR指定的位置上
							end
					3'b101: begin
								if(interrupt)
									value <= 8'b0000_0101;
								else
									value <= 8'b0000_0000;
							end
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
		always @(negedge clk) begin
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
    input wire [1:0] rwforram /*对ram输出还是接收数据*/,
    output wire [7:0] aa
    );

		/** 
		*	rst = 0   清零
		*	in_allow  锁存数据
		*	out_allow 输出数据
        *   rwforram[1] ioram 对外输出
        *   rwforram[0] ioram 对内输入
		*/
		reg  [7:0] mem;
		always @(negedge clk) begin
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
		assign aa = mem;
endmodule

/**
 *  for MAR IR PC 专用寄存器
 */
module registerforoutput(
	input clk, input [7:0] in, input wire inc, output wire [7:0] out,
	input out_allow,input in_allow,input rst, output wire [7:0] out_direct);

		/** 
		*	rst = 0   清零
		*	in_allow  锁存数据
		*	out_allow 输出数据
		*/
		reg  [7:0] mem;
		always @(negedge clk) begin
			if (!rst)
				mem <= 8'b00000000;
			else if (in_allow)
				mem <= in;
			if(inc)
				mem <= mem+1;
		end
        assign out_direct = mem;
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
    input wire [1:0] controllerforstate,/*状态寄存器控制器*/
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
			   /** 状态位含义
				* 0:	进位标志符 
				* 1:	借位标志符
				* 2:	结果为0 为1
				* 3:   补码运算正溢出
				* 4:   补码运算负溢出
				*/
		always @(*) begin
            if (!rst)
				mem <= 8'b0;
			case(op)//使用双符号位的补码进行运算
				3'b000:	begin       //加法
				 	case(controllerforstate)
					2'b00:begin
						{cout_add,out[7:0]} <= {in_a[7],in_a}+{in_b[7],in_b};
						if({cout_add,out[7]} == 2'b01) // 正溢
							mem[3] <= 1'b1;
						if({cout_add,out[7]} == 2'b10) //负溢
							mem[4] <= 1'b1;
						end
					2'b01:{mem[0],out[7:0]} <= {in_a}+{in_b};//记录进位
					2'b10:begin out[7:0] <= {in_a}+{in_b};//使用进位
							   out[7:0] <= out[7:0] + mem[0];
						 end
					2'b11:{mem[0],out[7:0]} <= {in_a}+{in_b}+{7'b0000000,mem[0]};//记录并使用进位
					endcase
					mem[2] <= ~equal;
					end
				3'b001:  begin       //减法
						{cout_sub,out[7:0]} <= {in_a[7],in_a}+{~in_b[7],~in_b}+9'd1;
						if({cout_add,out[7]} == 2'b01) // 正溢
							mem[3] <= 1'b1;
						if({cout_add,out[7]} == 2'b10) //负溢
							mem[4] <= 1'b1;
						mem[2] <= ~equal;
					end
				3'b010:  out[7:0] <= in_a*in_b;
				3'b011: begin out[7:0] <= ~in_b; 	 mem[2] <= ~equal; end
				3'b100: begin out[7:0] <= in_a^in_b; mem[2] <= ~equal; end
				3'b101: begin out[7:0] <= in_b+1;mem[2] <= ~equal; end
                3'b110: out[7:0] <= in_a / in_b;
				3'b111:  out[7:0] <= 8'bz;
			endcase	
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
    assign addr_ram = in_rom_e ? addr_frommar : addr_frompc;
endmodule



/**
 *  寄存器写读控制器    纯组合逻辑
 */
module wrcontroller(
    input [2:0] reg_ch_l, 	    /*低位指定的寄存器选择线	(24位微程序控制指令)*/
	input [2:0] reg_ch_h, 	    /*高位指定的寄存器选择线*/
	input [1:0] l_wr,	        /*低位指定的寄存器 写读控制器*/
    input [1:0] h_wr,           /*高位指定的寄存器 写读控制器*/
	input [2:0] next,		    /*根据下地址生成方式决定是否有效*/
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
	//                           计数        通过PC转换        停机
	assign reg_ch_w = (next == 3'b100 || next == 3'b001 || 3'b111) ? (reg_ch_l_w | reg_ch_h_w) : 8'b0; /*写线汇总*/
	assign reg_ch_r = (next == 3'b100 || next == 3'b001 || 3'b111) ? (reg_ch_l_r | reg_ch_h_r) : 8'b0;  /*读线汇总*/

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

/**
 *
 */
module decode_7(
	input [7:0] in,
	output reg [7:0] out);
	always @(*)
		case(in)
		8'b00110111: out <= 8'b10001000;	// 00110111 TO 136 	ALU_反_R1
8'b00010111: out <= 8'b01001111;	// 00010111 TO 79 	STORE_PC_ANS
8'b00110110: out <= 8'b01111010;	// 00110110 TO 122 	ALU_反_R0
8'b00010000: out <= 8'b00110100;	// 00010000 TO 52 	STORE_MAR_R0
8'b00010010: out <= 8'b00111010;	// 00010010 TO 58 	STORE_MAR_MAR
8'b00010001: out <= 8'b00110111;	// 00010001 TO 55 	STORE_MAR_R1
8'b00100111: out <= 8'b01101010;	// 00100111 TO 106 	R1--PC
8'b00100101: out <= 8'b01100110;	// 00100101 TO 102 	R1--LJ
8'b00001001: out <= 8'b00101011;	// 00001001 TO 43 	LOAD_NUM_R1
8'b00010110: out <= 8'b01001010;	// 00010110 TO 74 	STORE_PC_MAR
8'b00001000: out <= 8'b00101000;	// 00001000 TO 40 	LOAD_NUM_R0
8'b01100001: out <= 8'b10011011;	// 01100001 TO 155 	ALU_加RU_R0
8'b00110101: out <= 8'b10000110;	// 00110101 TO 134 	ALU_乘_R1
8'b01100000: out <= 8'b10010101;	// 01100000 TO 149 	ALU_加RU_R1
8'b00110100: out <= 8'b01111000;	// 00110100 TO 120 	ALU_乘_R0
8'b01000001: out <= 8'b10010111;	// 01000001 TO 151 	ALU_加R_R0
8'b01000000: out <= 8'b10010001;	// 01000000 TO 145 	ALU_加R_R1
8'b00100011: out <= 8'b01100010;	// 00100011 TO 98 	R0--PC
8'b00100001: out <= 8'b01011110;	// 00100001 TO 94 	R0--LJ
8'b00011000: out <= 8'b01010100;	// 00011000 TO 84 	STORE_NUM_MAR
8'b00100000: out <= 8'b01011100;	// 00100000 TO 92 	RO--MAR
8'b00111010: out <= 8'b01111110;	// 00111010 TO 126 	ALU_自增_R0
8'b00111011: out <= 8'b10001100;	// 00111011 TO 140 	ALU_自增_R1
8'b10000000: out <= 8'b00000000;	// 10000000 TO 0 	GETPC
8'b00100010: out <= 8'b01100000;	// 00100010 TO 96 	RO--R1
8'b01110110: out <= 8'b10100011;	// 01110110 TO 163 	IN_MAR
8'b00000101: out <= 8'b00011001;	// 00000101 TO 25 	LOAD_PC_R1
8'b01010000: out <= 8'b10010011;	// 01010000 TO 147 	ALU_加U_R1
8'b00000100: out <= 8'b00010100;	// 00000100 TO 20 	LOAD_PC_R0
8'b00100100: out <= 8'b01100100;	// 00100100 TO 100 	R1--MAR
8'b01010001: out <= 8'b10011001;	// 01010001 TO 153 	ALU_加U_R0
8'b00111000: out <= 8'b01111100;	// 00111000 TO 124 	ALU_异或_R0
8'b00111001: out <= 8'b10001010;	// 00111001 TO 138 	ALU_异或_R1
8'b00001011: out <= 8'b00110001;	// 00001011 TO 49 	LOAD_NUM_MAR
8'b00010101: out <= 8'b01000101;	// 00010101 TO 69 	STORE_PC_R1
8'b00010100: out <= 8'b01000000;	// 00010100 TO 64 	STORE_PC_R0
8'b00111101: out <= 8'b10001110;	// 00111101 TO 142 	ALU_除_R1
8'b00111100: out <= 8'b10000000;	// 00111100 TO 128 	ALU_除_R0
8'b00101011: out <= 8'b01110010;	// 00101011 TO 114 	LJ--PC
8'b01111011: out <= 8'b10101001;	// 01111011 TO 169 	OUT_MAR
8'b10000010: out <= 8'b00000101;	// 10000010 TO 5 	CH_INTERRUPT
8'b00101000: out <= 8'b01101100;	// 00101000 TO 108 	LJ--MAR
8'b01110101: out <= 8'b10011111;	// 01110101 TO 159 	IN_R1
8'b01110100: out <= 8'b10011101;	// 01110100 TO 157 	IN_R0
8'b01111010: out <= 8'b10101011;	// 01111010 TO 171 	OUT_ANS
8'b00000110: out <= 8'b00011110;	// 00000110 TO 30 	LOAD_PC_LJ
8'b10000001: out <= 8'b00000010;	// 10000001 TO 2 	GETMAR
8'b11110000: out <= 8'b10010000;	// 11110000 TO 144 	停机
8'b00000010: out <= 8'b00001110;	// 00000010 TO 14 	LOAD_MAR_LJ
8'b00110011: out <= 8'b10000100;	// 00110011 TO 132 	ALU_减_R1
8'b00110010: out <= 8'b01110110;	// 00110010 TO 118 	ALU_减_R0
8'b00000111: out <= 8'b00100011;	// 00000111 TO 35 	LOAD_PC_MAR
8'b00101010: out <= 8'b01110000;	// 00101010 TO 112 	LJ--R0
8'b10000100: out <= 8'b00000111;	// 10000100 TO 7 	JUMP_N
8'b00101001: out <= 8'b01101110;	// 00101001 TO 110 	LJ--R1
8'b00100110: out <= 8'b01101000;	// 00100110 TO 104 	R1--R0
8'b00000011: out <= 8'b00010001;	// 00000011 TO 17 	LOAD_MAR_MAR
8'b00001010: out <= 8'b00101110;	// 00001010 TO 46 	LOAD_NUM_LJ
8'b01111000: out <= 8'b10100101;	// 01111000 TO 165 	OUT_R0
8'b10000011: out <= 8'b00000110;	// 10000011 TO 6 	JUMP_E
8'b00011001: out <= 8'b01010111;	// 00011001 TO 87 	STORE_NUM_PC
8'b00110001: out <= 8'b10000010;	// 00110001 TO 130 	ALU_加_R1
8'b00110000: out <= 8'b01110100;	// 00110000 TO 116 	ALU_加_R0
8'b01110111: out <= 8'b10100001;	// 01110111 TO 161 	IN_LJ
8'b01111001: out <= 8'b10100111;	// 01111001 TO 167 	OUT_R1
8'b00000000: out <= 8'b00001000;	// 00000000 TO 8 	LOAD_MAR_R0
8'b00000001: out <= 8'b00001011;	// 00000001 TO 11 	LOAD_MAR_R1
8'b00010011: out <= 8'b00111101;	// 00010011 TO 61 	STORE_MAR_ANS
		endcase
endmodule