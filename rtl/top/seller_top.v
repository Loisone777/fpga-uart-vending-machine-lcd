`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/15 10:55:12
// Design Name: 
// Module Name: seller_top
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


module seller_top(
	input              clk        ,
	input              rst_n      ,
	input              key_done   ,
	input      [1:0]   key_num    ,   //0增1减
	input              rx         ,	
	output             tx         ,
	output             signal_done,
	output             led1        ,
	output             led2        ,
	output             led3,
	output             led4,
	output             led,
	output             lcd_rst     ,//LCD硬件复位
    output             CSX         ,//片选信号
    output             DCX         ,//LCD指令/数据信号（低电平指令，高电平参数/数据）
    output             WRX         ,//LCD写  上升沿写数据
    output             RWX         ,//LCD读  上升沿读数据
    output             BL          ,////背光信号  点亮LCD
    output     [15:0]  data_lcd     //输入给LCD的数据
);

wire key_done_vld;
wire [1:0]key_num_vld;
wire key_up_valid;
wire key_down_valid;
wire valid;
wire en;

wire [7:0]uart_in;
wire [7:0]uart_out;
wire [7:0]lcd_flag;


assign key_num_vld[0]=key_up_valid;
assign key_num_vld[1]=key_down_valid;

assign signal_done=key_done_vld;
    
seller uu1(
	.clk        (clk     ),
	.rst_n      (rst_n   ),
	.key_done   (key_done_vld),
	.key_num    (key_num_vld ),   //0增1减
	.uart_in    (uart_in ),	
	.uart_out   (uart_out),
	.en         (en),
	.led1        (led1     ),
	.led2        (led2     ),
	.led3        (led3     ),
	.led4        (led4     ),
	.led        (led     )  ,
	.lcd_flag      (lcd_flag)
);

uart_rx uu2(
   .clk         (clk     ),
   .rst_n       (rst_n   ),
   .rx          (rx      ),
   .data_out    (uart_in    ),
   .valid       (valid      )            //数据接收完毕使能信号
);


uart_tx uu3(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (uart_out ),
    .en         (en    ),
    .TX         (TX       ),
    .done       ( )            //数据接收完毕使能信
);

key_xd uu4_done(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .key        (key_done),
    .key_vld    (key_done_vld)
);

key_xd uu4_up(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .key        (key_num[0]),
    .key_vld    (key_up_vld)
);

key_xd uu4_down(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .key        (key_num[1]),
    .key_vld    (key_down_vld)
);

reg [15:0] dout0    ;//RAM中的图像数据
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        dout0 <= 0;
    else case(lcd_flag)
        8'b00000001:dout0<=douta0;
        8'b00000010:dout0<=douta1;
        8'b00000100:dout0<=douta2;
       // 8'b00001000:dout0<=douta3;
        default:dout0<=0;
    endcase
end

wire [16:0]addr0;
wire [15:0]douta0;
wire [15:0]douta1;
wire [15:0]douta2;

blk_mem_gen_0 uu6_0 (
  .clka(clk),    // input wire clka
  .ena(lcd_flag[0]),      // input wire ena
  .addra(addr0),  // input wire [16 : 0] addra
  .douta(douta0)  // output wire [15 : 0] douta
); 

blk_mem_gen_1 uu6_1 (
  .clka(clk),    // input wire clka
  .ena(lcd_flag[1]),      // input wire ena
  .addra(addr0),  // input wire [16 : 0] addra
  .douta(douta1)  // output wire [15 : 0] douta
);

blk_mem_gen_2 uu6_2 (
  .clka(clk),    // input wire clka
  .ena(lcd_flag[2]),      // input wire ena
  .addra(addr0),  // input wire [16 : 0] addra
  .douta(douta2)  // output wire [15 : 0] douta
);

//blk_mem_gen_3 uu6_3 (
//  .clka(clk),    // input wire clka
//  .ena(lcd_flag[3]),      // input wire ena
//  .addra(addr0),  // input wire [16 : 0] addra
//  .douta(douta3)  // output wire [15 : 0] douta
//);

lcd_display display0(
    .sys_clk     (clk  ),
    .sys_rst_n   (rst_n),
    .data_flag   (lcd_flag), //RAM中的数据已经写满标志（开始传输数据到LCD）
    .ram_data    ({dout0[4:0],dout0[10:5],dout0[15:11]} ),//RAM中的图像数据
    .lcd_rst     (lcd_rst  ),//LCD硬件复位
    .CSX         (CSX      ),//片选信号
    .DCX         (DCX      ),//LCD指令/数据信号（低电平指令，高电平参数/数据）
    .WRX         (WRX      ),//LCD写  上升沿写数据
    .RWX         (RWX      ),//LCD读  上升沿读数据
    .BL          (BL       ),////背光信号  点亮LCD
    .data_lcd    (data_lcd ),//输入给LCD的数据
    .addrb       (addr0    ) //RAM的读地址    
); 
endmodule
