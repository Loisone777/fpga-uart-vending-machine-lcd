`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/15 15:55:50
// Design Name: 
// Module Name: seller_tb
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


module seller_tb( );

seller i1(
	.clk        (clk     ),
	.rst_n      (rst_n   ),
	.key_done   (key_done),
	.key_num    (key_num ),   //0增1减
	.uart_in    (uart_in ),	
	.uart_out   (uart_out),
	.en         (en      ),
	.led        (led     ) ,
	.led1       (led1    )  ,
	.led2       (led2    )  ,
	.led3       (led3    )  ,
	.led4       (led4    )  
);

uart_tx i2(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (uart_out ),
    .en         (en    ),
    .TX         (TX       ),
    .done       ( )            //数据接收完毕使能信
);

reg              clk     ;
reg              rst_n   ;
reg              key_done;
reg      [1:0]   key_num ; //0增1减
reg      [7:0]   uart_in ;
wire     [7:0]   uart_out;
wire             en      ;
wire             led     ;
wire             led1    ;
wire             led2    ;
wire             led3    ;
wire             led4    ;

initial begin
    clk=0;
    rst_n=0;
    #100 rst_n=1;
end

always #1 clk=~clk;

initial begin
    key_done=0;
    key_num=0;
    #150
    uart_in=8'h11;
   
    #150
    uart_in=8'h01;
    #50
    key_num[0]=1;
    #10
    key_num[0]=0;
    #50
    key_num[1]=1;
    #10
    key_num[1]=0;
    #150
    key_done=1;
    uart_in=8'h55;
    #10
    key_done=0;
    
    #150
    uart_in=8'h02;
    #150
    key_done=1;
    uart_in=8'h55;
    #10
    key_done=0;
    
    #150
    uart_in=8'h22;
    
    #150
    uart_in=8'h44;
end

endmodule
