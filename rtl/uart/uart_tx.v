`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/12 09:05:11
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    input clk,
    input rst_n,
    input [7:0]data,
    input en,
    output reg TX,
    output reg done            //数据接收完毕使能信
    );
parameter SYSCLK=125_000_000;
parameter BAUD=115200;
parameter DELAY=SYSCLK/BAUD; 

parameter IDLE= 4'b0001;//空闲 高
parameter START=4'b0010; //起始2'b10
parameter SEND= 4'b0100;//8bit数据接收
parameter STOP= 4'b1000;//停止位 高
 
reg [31:0]cnt;
reg [3:0]cnt_bit; 
reg [7:0]TX_TEMP;
reg [1:0]en_temp;         
reg[3:0] state_c,state_n; 
 
 //第一段
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

//第二段
always@(*)begin
    if(!rst_n)begin
        state_n <= IDLE;
    end
    else begin 
        case(state_c)
            IDLE:begin
                if(en_temp==2'b01)begin
                    state_n = START;
                end
                else begin
                    state_n = IDLE;
                end
            end
            START:begin
                if(cnt>=DELAY-1)begin
                    state_n = SEND;
                end
                else begin
                    state_n = START;
                end
            end
            SEND:begin
                if(cnt_bit>=7&&cnt>=DELAY-1)begin
                    state_n = STOP;
                end
                else begin
                    state_n = SEND;
                end
            end
            STOP:begin
                if( cnt>=DELAY-1)begin
                    state_n = IDLE;
                end
                else begin
                    state_n =STOP;
                end
            end
            default:begin
                state_n = IDLE;
            end
        endcase
    end  
end

//第三段
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin      
        cnt<=0;
        cnt_bit<=0;
        TX<=1'b1;
        done<=0;
        TX_TEMP<=0;
        en_temp<=2'b0;
    end
    else begin
        case(state_c)
            IDLE:begin
                cnt<=0;
                cnt_bit<=0;
                TX<=1'b1;
                done<=0;
                TX_TEMP<=data;
                en_temp<={en_temp[0],en};
            end
            START:begin
                if(cnt>=DELAY-1)
                    cnt<=0;
                else begin
                    cnt<=cnt+1;
                    TX_TEMP<=TX_TEMP;
                    TX<=1'b0;
                    en_temp<={en_temp[0],en};
                    done<=0;
                    cnt_bit<=0;
                end
            end 
            SEND:begin
                if(cnt>=DELAY-1)begin
                    cnt<=0;
                    cnt_bit<=cnt_bit+1;
                end
                else begin
                    cnt<=cnt+1;
                    cnt_bit<=cnt_bit;
                end
                TX<=TX_TEMP[cnt_bit];
                en_temp<={en_temp[0],en};
                done<=0;
            end
            STOP:begin
                if(cnt>=DELAY-1)
                    cnt<=0;
                else
                    cnt<=cnt+1;
                TX<=1'b1;
                en_temp<={en_temp[0],en};
                TX_TEMP<=0;
                if(cnt==0)
                    done<=1;
                else
                    done<=0;
            end
            default:begin
                cnt<=0;
                cnt_bit<=0;
                TX<=1'b1;
                done<=0;
                TX_TEMP<=data;
                en_temp<={en_temp[0],en};
            end
         endcase
     end
end
endmodule
