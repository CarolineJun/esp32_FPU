`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2020 01:35:13 PM
// Design Name: 
// Module Name: qspi_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module qspi_adder#(
parameter addr_width = 8
)(
input clk,
input rst_n,
//RAM

output reg [addr_width-1:0] addr,
input [7:0]data_in,
output reg [7:0] data_out,
output reg wen
);

//registers & wire
reg [9:0] count;
wire [7:0] rcount;
assign rcount = count[9:2];


always @(posedge clk,negedge rst_n)
begin
    if (!rst_n)
        count <= 0;
    else
    begin
        if (rcount < 32)
            count <= count + 1;
        else
            count <= 0;
    end
end

//addr: RAM地址端
always @(posedge clk,negedge rst_n)
begin
    if (!rst_n)
        addr <= 0;
    else
    begin
        if (rcount < 32)
            addr <= rcount;
        else
            addr <= 0;
    end
end

//mem: 8位数据寄存器组，储存 0x 00 0 x 0F 的数据同时进行加 5 操作
reg [7:0] mem [0:15];
integer i;
always @(posedge clk,negedge rst_n)
begin
    if (!rst_n)
    begin
        for (i=0;i<15;i=i+1)
            mem[i] <= 0;
        end
    else
    if ((rcount < 16)&&(count[1:0] == 2'b11))
        mem[rcount] <= data_in + 5;
end


//data_out:从 mem 中进行数据输出
always @(posedge clk,negedge rst_n)
begin
    if (!rst_n)
        data_out <= 0;
    else
        if (rcount >= 16 && rcount < 32)
            data_out <= mem[rcount-16];
        else
            data_out <= 0;
end

//wen: RAM写使能
always @(posedge clk,negedge rst_n)
begin
    if (!rst_n)
    begin
        wen <= 0;
    end
    else
    begin
        if ((rcount >= 16)&&(rcount < 32))
            wen <= 1;
        else
            wen <= 0;
    end
end
endmodule
