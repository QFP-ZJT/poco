module composer(
    input clk,
    input rst,
    output wire [3:0] slow,
    output wire quick
);
    wire t1,t2,t3,t4,w1;
    reg[2:0] count_t;
    always@(posedge clk)
		begin
		  if(!rst)begin
			count_t <= 3'b000;
		  end
		  else 
		  count_t <= count_t + 1;
		end
    assign t1 = (count_t[1:0]==2'b00) ? 1'b1 : 1'b0;
    assign t2 = (count_t[1:0]==2'b01) ? 1'b1 : 1'b0;
    assign t3 = (count_t[1:0]==2'b10) ? 1'b1 : 1'b0;
    assign t4 = (count_t[1:0]==2'b11) ? 1'b1 : 1'b0;
    assign w1 = (count_t[2]==1'b0) ? 1'b1 : 1'b0;
    assign slow = {t1,t2,t3,t4};
    assign quick = w1;
    
endmodule