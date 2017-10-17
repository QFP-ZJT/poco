module DRAM(DataBus/*数据总线*/,AddressBus/*地址总线*/,ReadRAM/*读控制*/,WriteRAM/*写控制*/);
/*面向RAM设计的*/
inout [31:0]DataBus;
 
input [9:0]AddressBus;
input ReadRAM,WriteRAM;
 
reg [31:0]RAM[0:1023];
 
parameter insfile="InstructionFile.txt",
datafile="DataFile.txt";
 
initial
begin
$readmemh(insfile,RAM,0);
$readmemh(datafile,RAM,512);
end
 
assign DataBus=(ReadRAM==1)? RAM[AddressBus]:32'bz;
 
always @(WriteRAM or DataBus)
if(WriteRAM)
RAM[AddressBus] =DataBus;
Endmodule
 
//仅仅为了说明inout端口用法，真实的CPU描述远非如此
module CPU(DataBus,AddressBus,ReadRAM，WriteRAM,Clock,Reset);
inout [31:0]DataBus;
 
output [9:0]AddressBus;
output ReadRAM，WriteRAM;
input Clock,Reset;
 
reg [31:0]DataRead;
 
assign DataBus=(WriteRAM==1)?DataWrite:32'bz;
 
always @(ReadRAM)
if(ReadRAM)
DataRead=DataBus;
 
//CPU中以后的代码就是用DataRead和DataWrite来完成和RAM的数据交换
endmodule