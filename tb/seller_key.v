`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/16 14:13:15
// Design Name: 
// Module Name: seller_key
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


module seller_key();

seller i1(
	.clk        (clk     ),
	.rst_n      (rst_n   ),
	.key_done   (key_done),
	.key_num    (key_num ),   //0Ôö1¼õ
	.uart_in    (uart_in ),	
	.uart_out   (uart_out),
	.en         (en      ),
	.led        (led     ) ,
	.led1       (led1    )  ,
	.led2       (led2    )  ,
	.led3       (led3    )  ,
	.led4       (led4    )  
);

reg              clk     ;
reg              rst_n   ;
wire              key_done;
reg      [1:0]   key_num ; //0Ôö1¼õ
reg      [7:0]   uart_in ;
wire     [7:0]   uart_out;
wire             en      ;
wire             led     ;
wire             led1    ;
wire             led2    ;
wire             led3    ;
wire             led4    ;

reg key;

key_xd i2(
    .clk        (clk     ),
    .rst_n      (rst_n   ),
    .key        (key),
    . key_vld   ( key_done)
);
    
 initial begin
    clk=0;
    rst_n=0;
    #100 rst_n=1;
end

always #1 clk=~clk;

initial begin
    key=0;
    #(150*25)
    key=1;
    #(10*25)
    key=0;
    #(150*25)
    key=1;
    #(10*25)
    key=0;
end  
endmodule
