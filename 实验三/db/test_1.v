/** 
 * ʱ�ӿ���ROM�������������ָ��
 * ��ǰʵ��Ķ������ģ��
 */
module test_1(
	input  wire		  in_clk, /*ʱ������Դ*/
	input  wire		  rst,    /*���ָ��  Ϊ0ʱ�����*/
	input  wire 	  run,	  /*�Ƿ�������״̬*/
	input  wire[23:0] in_rom, /*ROM�ڴ����*/
	output wire[7:0]  addr_rom,/*ROM��ַ���*/
	output wire		  out_clk,/*ROM����ָ��*/
	output wire		  wupc,	  /*����ROM���ڶ�״̬*/
	output wire[31:0]  led	  /*led����������*/
);
	/**
	 *    led[7:0]		����dbus
	 *	  led[15:8]		����upc
	 *	  led[23:16]	����state
	 */



	/*���߶���*/
	wire [7:0] dbus;		/*CPU�ڲ�����*/

	wire clk;
	wire [7:0] reg_ch_l_w; 	/*��λָ����д�Ĵ���ѡ����	(24λ΢�������ָ��)*/
	wire [7:0] reg_ch_l_r;	/*��λָ���Ķ��Ĵ���ѡ����*/
	wire [7:0] reg_ch_h_w; 	/*��λָ����д�Ĵ���ѡ����*/
	wire [7:0] reg_ch_h_r;	/*��λָ���Ķ��Ĵ���ѡ����*/
	wire [7:0] reg_ch_w; 	/*д�Ĵ���ѡ����*/
	wire [7:0] reg_ch_r;	/*���Ĵ���ѡ����*/
	/**
	 *	reg_sta   0   
	 *           cin  
	 */
	wire [7:0] toreg_sta;		/*״̬������*/
	wire [7:0] fromreg_sta;		/*״̬������*/
	wire [7:0] reg_sta_w; 	/*д�Ĵ���ѡ����*/
	wire [7:0] reg_sta_r;	/*���Ĵ���ѡ����*/

	wire [7:0] addtoalu;	/*�ۼ�������ALU*/
	wire [7:0] toans;		/*���ӵ�����Ĵ���*/
	
	//����ʱ���Ƿ�������״̬
	assign clk = run ? in_clk : 1'bz;				/*��runΪtrue �����ʱ�ӣ�����Ͽ�ʱ��*/
	// ROM ����
	assign out_clk = clk;						/*cpuIR    �����Ƿ���Ҫȡ��*/
	assign w_uPC = 1'b0;
	// �Ĵ���״̬������
	assign reg_ch_w = reg_ch_l_w & reg_ch_h_w ; /*д�߻���*/
	assign reg_ch_r = reg_ch_l_r & reg_ch_h_r;  /*���߻���*/
	// ��ʱ�����ʾ
	assign led[7:0] = dbus;
	

	/*�Ĵ�����ѡȡ*/
	decode decode_l_r(			/*��λָ���Ķ��Ĵ���*/
		.in 	(in_rom[15:13]),
		.open	(in_rom[11]),
		.out 	(reg_ch_l_r)
	);
	decode decode_l_w(			/*��λָ����д�Ĵ���*/
		.in 	(in_rom[15:13]),
		.open	(in_rom[12]),
		.out 	(reg_ch_l_w)
	);
	decode decode_2_r(			/*��λָ���Ķ��Ĵ���*/
		.in 	(in_rom[20:18]),
		.open	(in_rom[16]),
		.out 	(reg_ch_h_r)
	);
	decode decode_2_w(			/*��λָ����д�Ĵ���*/
		.in 	(in_rom[20:18]),
		.open	(in_rom[17]),
		.out 	(reg_ch_h_w)
	);

	/**
	 * upc��ַ���� 
	 */
	w_uPC upc(
		.clk	(clk),
		.rst	(rst),
		.ld		(in_rom[2]),
		.op		(in_rom[1:0]),
		.in_upc	(in_rom[20:13]),
		.in_pc	(4'b0),
		.out	(addr_rom)
	);

	/*
	 *  �Ĵ����ı��
	 *	PC(0) IR(1) MAR(2) MDR(3) ״̬�Ĵ��� �ۼ���(4) ���ݼĴ���(5) ��ַ�Ĵ���(6) R0(7)
	 */
	register reg_add(			/*�ۼӼĴ���*/
		.clk		(clk),
		.in			(dbus),
		.out		(addtoalu),
		.out_allow	(reg_ch_r[4]),
		.in_allow	(reg_ch_w[4]),
		.rst		(rst)
	);

	register reg_ans(			/*�������Ĵ���*/
		.clk		(clk),
		.in			(toans),
		.out		(dbus),
		.out_allow	(reg_ch_r[5]),
		.in_allow	(reg_ch_w[5]),
		.rst		(rst)
	);

	register reg_state(			/*״̬�Ĵ��� TODO */
		.clk		(clk),
		.in			(toreg_sta),
		.out		(fromreg_sta),
		.out_allow	(1'b1),			//Ӧ����op��������  �е��� TODO
		.in_allow	(1'b0),
		.rst		(rst)
	);

	register reg_mdr(				//��ʱ���õ�MDR��ROM��ץȡ����
		.clk		(clk),
		.in			(in_rom[10:3]),
		.out		(dbus),
		.out_allow	(reg_ch_r[3]),		
		.in_allow	(reg_ch_w[3]),
		.rst		(rst)
	);

	register reg_r0(				//ͨ�üĴ���R0
		.clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[7]),		
		.in_allow	(reg_ch_w[7]),
		.rst		(rst)
	);

	register reg_r1(				//ͨ�üĴ���R1
		.clk		(clk),
		.in			(dbus),
		.out		(dbus),
		.out_allow	(reg_ch_r[6]),		
		.in_allow	(reg_ch_w[6]),
		.rst		(rst)
	);

	w_alu alu(							/*���㵥Ԫ*/
		.clk		(clk),
		.op			(in_rom[23:21]) 	/*ѡ��Ҫִ�еĲ���*/,
		.in_a		(addtoalu)			/*�����ۼ���*/, 
		.in_b		(dbus)				/*����BUS*/,
		.cin		(fromreg_sta[0])	/*��λ��־λ*/, 
		.out		(toans)				/*�͵�ans�Ĵ�����*/,
		.cout		(toreg_sta[0])		/*����״̬�Ĵ���*/
	);

endmodule

// ΢�������ָ��ĵ�ַ������
module w_uPC(input clk,input rst,input ld,input [1:0] op,
			input [7:0] in_upc,input [3:0] in_pc,output wire [7:0] out);
		/**
		*	rst = 0 ����
		*	rst = 1, ld = 0; ֱ�� out = in
		*		op[1:0] == 01 in_pc;
		*		op[1:0] == 10 in_upc;
		*	rst = 1, ld = 1,op[1:0] == 00; ����
		*	���ܵĸ���:regֱ�����
		*/
		
		reg [7:0] value;
		always @(posedge clk) begin
			if (!rst)
				assign value = 8'b00000000;	
			else begin
				case({ld,op[1:0]})
					3'b100: value <= value + 1;
					3'b001: value <= 8'b0;//�ȴ�pcת��
					3'b010: value <= in_upc;
				endcase
			end
		end
		assign out = value;
endmodule


/**
 *	��ͨ�Ĵ������ģ��
 */
module register(
	input clk, input [7:0] in, output wire [7:0] out,
	input out_allow,input in_allow,input rst);

		/** 
		*	rst = 0   ����
		*	in_allow  ��������
		*	out_allow �������
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
 * ����߼���ALU��Ƶ�·
 * clk,op ѡ��Ҫִ�еĲ���,
 * in_a�����ۼ���, in_b����BUS,cin��λ��־λ, out���ӵ�����,cout����״̬�Ĵ���
 */
module w_alu (
	input clk, input [2:0] op/*ѡ��Ҫִ�еĲ���*/,input [7:0] in_a/*�����ۼ���*/, input [7:0] in_b/*����BUS*/,
	input cin/*��λ��־λ*/,output reg [7:0] out/*���ӵ�����*/,output wire cout/*����״̬�Ĵ���*/);
		/**
		*	op 000 �ӷ�
		*	op 001 ����
		*	op 010 �˷�
		*	op 011 ��in_bȡ��	
		*	op 100 in_a,in_b���
		*	op 101 in_b,����1     ΪPC����
		*	op 110 ����
		*	op 111 �����
		*/

		always @(*) begin
			case(op)
				3'b000:	assign {cout,out[7:0]} = in_a+in_b+cin;
				3'b001: assign {cout,out[7:0]} = in_a-in_b-cin;//�߼��е����
				3'b010: assign out[7:0] = in_a*in_b;
				3'b011: assign out[7:0] = ~in_b;
				3'b100: assign out[7:0] = in_a^in_b;
				3'b101: assign out[7:0] = in_b+1;
				3'b111: assign out[7:0] = 8'bzzzzzzzz;
			endcase	
		end
endmodule

/**
 *	������  �� - ��   ���ҽ���openΪ1��ʱ��
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