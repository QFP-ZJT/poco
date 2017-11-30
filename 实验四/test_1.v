`include "register.v"
`include "chooseforalu.v"
`include "composer.v"
`include "alu.v"
`include "cu.v"
module test_1(
    input clk_con,
    input clk_sin,
    input choose,
    input rst,
    output [7:0] addrforram,
    input  [13:0] key, 
    output [44:0] led,
    inout  [7:0] dataforram,
    output  ram_w,
    output  ram_r
);
    wire clk;
    wire [3:0] slow;
    wire quick;
    wire [14:0] op;
    wire [7:0] inregister;   //连接寄存器和dataforram
    wire [7:0] r0_a;        //register 连接 chooseforalu
    wire [7:0] data_a;
    wire [7:0] r1_b;
    wire [7:0] pc_b;
    wire [7:0] a_alu;
    wire [7:0] b_alu;
    wire [7:0] ir_cu;
    reg  [7:0] mem;
    
    assign clk = (choose) ? clk_con : clk_sin;
	//assign clk = clk_con;
    // assign mem <= op[0] ? dataforram : mem;
    // assign data_a = mem;
    // assign dataforram = op[1] ? mem : b'bz;
    
    assign data_a = op[0] ? dataforram : 8'bz;
    
    assign dataforram = op[1] ? inregister : 8'bz;
    
    //assign data_a = dataforram;
    assign ram_w = ~op[1];
    assign ram_r = ~op[0];

    assign led[39:32] = a_alu;
    assign led[31:24] = b_alu;
    assign led[15:8] = pc_b;
    assign led[7:0] = addrforram;

	// assign led[23:16] = dataforram;
    assign led[44:41] = slow;
    assign led[40] = quick;
    composer composer(
        .clk    (clk),
        .rst    (rst),
        .slow   (slow),
        .quick  (quick)
    );

    cu cu(
        .ir     (ir_cu),
        .slow   (slow),
        .quick  (quick),
        .op     (op)
    ); 

    register r0(
        .cpr (op[6]),
        .clk (clk),
        .rst (rst),
        .in  (inregister),
        .out (r0_a)
    );
    register r1(
        .cpr (op[5]),
        .clk (clk),
        .rst (rst),
        .in  (inregister),
        .out (r1_b)
    );
    register pc(
        .cpr (op[4]),
        .clk (clk),
        .rst (rst),
        .in  (inregister),
        .out (pc_b)
    );
    register ir(
        .cpr (op[3]),
        .clk (clk),
        .rst (rst),
        .in  (inregister),
        .out (ir_cu)
    );
    register mar(
        .cpr (op[2]),
        .clk (clk),
        .rst (rst),
        .in  (inregister),
        .out (addrforram)
    );
    chooseforalu a(
        .clk (clk),
        .in_A   (op[10]),
        .in_B   (op[9]),
        .A(data_a),
        .B(r0_a),
        .out (a_alu)
    );
    chooseforalu b(
        .clk (clk),
        .A   (pc_b),
        .B   (r1_b),
        .in_A(op[8]),
        .in_B(op[7]),
        .out (b_alu)
    );
    alu alu(
        .clk (clk),
        .op  (op[14:11]),
        .A   (a_alu),
        .B   (b_alu),
        .out (inregister)
    );
endmodule