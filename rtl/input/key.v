`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/13 11:32:46
// Design Name: 
// Module Name: key
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


module key_xd(
    input clk,
    input rst_n,
    input key,
    output key_vld
    );

parameter DELAY = 2_500_000;    //20ms
parameter M = 1;

reg [21:0] cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 0;
    else if(key == M)
        if(cnt == DELAY - 1)
            cnt <= cnt ;
        else
            cnt <= cnt + 1;
    else
        cnt <= 0;
end

assign key_vld = (cnt == DELAY - 1)?1'b1:1'b0;

endmodule
