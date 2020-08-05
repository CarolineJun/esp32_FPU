`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2020 08:35:52 PM
// Design Name: 
// Module Name: qspi_slave
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


module qspi_slave
#(
parameter data_width = 8,
parameter addr_width = 32,
parameter dummy      = 4
)
(
//QSPI
input I_qspi_clk,
input I_qspi_cs,
inout IO_qspi_io0,
inout IO_qspi_io1,
inout IO_qspi_io2,
inout IO_qspi_io3,
//RAMr
output [addr_width - 1: 0] o_addr,
output [data_width - 1: 0] o_data,
input  [data_width - 1: 0] i_data,
output                     o_valid
);

//INSTRUCTIONS 
localparam INS_QWrite_Quad = 8'b00110010; //32H,QSPI写指令
localparam INS_FRead_Quad = 8'b01101011; //6BH,QSPI读指令

//register of output
reg [addr_width-1:0] R_o_addr;
reg [data_width-1:0] R_o_data;
reg                  R_o_valid;

assign o_addr = R_o_addr;
assign o_data = {R_o_data[7:4],IO_qspi_io3,IO_qspi_io2,IO_qspi_io1,IO_qspi_io0};
assign o_valid = R_o_valid;
 
//QSPI IO
reg R_qspi_io0;
reg R_qspi_io1;
reg R_qspi_io2;
reg R_qspi_io3;
reg R_qspi_io0_en;
reg R_qspi_io1_en;
reg R_qspi_io2_en;
reg R_qspi_io3_en;

assign IO_qspi_io0 = R_qspi_io0_en ? R_qspi_io0 : 1'bz;
assign IO_qspi_io1 = R_qspi_io1_en ? R_qspi_io1 : 1'bz;
assign IO_qspi_io2 = R_qspi_io2_en ? R_qspi_io2 : 1'bz;
assign IO_qspi_io3 = R_qspi_io3_en ? R_qspi_io3 : 1'bz;


// I/O enable
////////////////////////////////////////////////////////////////////////////////////////////
//inout 端口三态门使能 (0:input , 1:output)
always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if (I_qspi_cs)
    begin
        R_qspi_io0_en <= 0;
        R_qspi_io1_en <= 0;
        R_qspi_io2_en <= 0;
        R_qspi_io3_en <= 0;        
    end
    else
    begin
        if((count >= 19) && (R_INS == INS_FRead_Quad))
        begin
            R_qspi_io0_en <= 1;
            R_qspi_io1_en <= 1;
            R_qspi_io2_en <= 1;
            R_qspi_io3_en <= 1;
        end
        else
        begin
            R_qspi_io0_en <= 0;
            R_qspi_io1_en <= 0;
            R_qspi_io2_en <= 0;
            R_qspi_io3_en <= 0;        
        end
    end   
end

/////////////////////////////////////////////////////////////////////////
//count:通信周期时钟计数器
////////////////////////////////////////////////////////////////////////
reg [7:0] count;
always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        count <= 0;
    end
    else
    begin
        count <= count + 1;
    end
end

/////////////////////////////////////////////////////////////////
// R_INS :8位指令接收寄存器
////////////////////////////////////////////////////////////////
reg [7:0] R_INS;
always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if ( I_qspi_cs)
    begin
        R_INS <= 0;
    end
    else
    begin
        if(count < 8 )
        begin
            R_INS[7 - count] <= IO_qspi_io0;
        end
    end
end


///////////////////////////////////////////////////////////////
//32位指令接收寄存器
//////////////////////////////////////////////////////////////
reg [31:0] R_addr;
always @(posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        R_addr <= 0;
    end
    else
    begin
        if ((count >= 8) && (count < 16) )
        begin
            R_addr[31:28] <= R_addr[27:24];
            R_addr[27:24] <= R_addr[23:20];
            R_addr[23:20] <= R_addr[19:16];
            R_addr[19:16] <= R_addr[15:12];
            R_addr[15:12] <= R_addr[11:8 ];
            R_addr[11:8 ] <= R_addr[7 :4 ];
            R_addr[7 :4 ] <= R_addr[3 :0 ];
            R_addr[3 :0 ] <= {IO_qspi_io3,IO_qspi_io2,IO_qspi_io1,IO_qspi_io0};
        end
    end        
end

reg addr_add;
always @(posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_clk)
    begin
        addr_add <= 0;
    end
    else
    begin
        if ( (count >= 20 ) && (R_INS == INS_QWrite_Quad))
        begin
            addr_add <= !addr_add;
        end
        else if ((count >= 17) && (R_INS == INS_FRead_Quad))
        begin
            addr_add <= !addr_add;        
        end
        else
        begin
            addr_add <= 0;
        end
    end    
end

always @(posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        R_o_addr <= 0;
    end
    else
    begin
        if(count == 15)
        begin
            R_o_addr <= {R_addr[27:0],IO_qspi_io3,IO_qspi_io2,IO_qspi_io1,IO_qspi_io0};
        end
        else if((count >= 18) && (addr_add))
        begin
            R_o_addr <= R_o_addr + 1;
        end
    end    
end

//////////////////////////////////////////////////////////////////////////////////
//Write
/////////////////////////////////////////////////////////////////////////////////
reg write_H;
always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        write_H <= 0;
    end
    else
    begin
        if ((count >= 20) && (R_INS == INS_QWrite_Quad ))
            write_H <= !write_H;
        else 
            write_H <= 0; 
    end
end

always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        R_o_valid <= 0;
    end
    else
    begin
        if ((count >= 21) && (R_INS == INS_QWrite_Quad ))
            R_o_valid <= !R_o_valid;
        else 
            R_o_valid <= 0; 
    end
end

always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        R_o_data [7:0] <= 0;
    end
    else
    begin
        if ((count >= 20) && (R_INS == INS_QWrite_Quad ))
        begin
            if (write_H)
                R_o_data[3:0] <= {IO_qspi_io3,IO_qspi_io2,IO_qspi_io1,IO_qspi_io0} ;
            else 
                R_o_data[7:4] <= {IO_qspi_io3,IO_qspi_io2,IO_qspi_io1,IO_qspi_io0} ;
        end
        else
            R_o_data [7:0] <= 0;  
    end
end

//////////////////////////////////////////////////////////////////////////////////
//Read
/////////////////////////////////////////////////////////////////////////////////
reg read_H;
always @ (posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if(I_qspi_cs)
    begin
        read_H <= 0;
    end
    else
    begin
        if ((R_INS == INS_FRead_Quad )&&(count >= 19 ))
            read_H <= !read_H;
        else 
            read_H <= 0; 
    end
end
always @(posedge I_qspi_clk or posedge I_qspi_cs)
begin
    if (I_qspi_cs)
    begin
        R_qspi_io0 <= 0;
        R_qspi_io1 <= 0;
        R_qspi_io2 <= 0;
        R_qspi_io3 <= 0;    
    end
    else
    begin
        if ((R_INS == INS_FRead_Quad )&&(count >= 19 ))
        begin
            if (read_H)
            begin
                R_qspi_io0 <= i_data[0];
                R_qspi_io1 <= i_data[1];
                R_qspi_io2 <= i_data[2];
                R_qspi_io3 <= i_data[3];
            end
            else
            begin
                R_qspi_io0 <= i_data[4];
                R_qspi_io1 <= i_data[5];
                R_qspi_io2 <= i_data[6];
                R_qspi_io3 <= i_data[7];
            end
        end
        else
        begin
            R_qspi_io0 <= 0;
            R_qspi_io1 <= 0;
            R_qspi_io2 <= 0;
            R_qspi_io3 <= 0;
        end
    end
end
endmodule
