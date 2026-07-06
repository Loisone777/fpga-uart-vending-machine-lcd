`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/11 10:10:03
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input clk,
    input rst_n,
    input rx,
    output reg [7:0]data_out,
    output reg valid            //数据接收完毕使能信号
    );
    
parameter SYSCLKHZ = 125_000_000;   //系统时钟
parameter BAUD = 115200;    //波特率
parameter DELAY = SYSCLKHZ/BAUD;    //接收1bit所需时钟数

parameter IDLE = 4'b0001;
parameter START = 4'b0010;
parameter RESEV = 4'b0100;  //8bit数据接收
parameter STOP = 4'b1000;   //停止位

reg [11:0]cnt;
reg [3:0]cnt_bit;
reg [1:0]rx_temp;       //检测下降沿
reg [3:0]state_c,state_n;

wire idl2s1_start ;
wire s12s2_start  ;
wire s22s3_start  ;
wire s32idl_start  ;

//第一段：同步时序always模块，格式化描述次态寄存器迁移到现态寄存器(不需更改）
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

//第二段：组合逻辑always模块，描述状态转移条件判断
always@(*)begin
    case(state_c)
        IDLE:begin
            if(idl2s1_start)begin
                state_n = START;
            end
            else begin
                state_n = state_c;
            end
            end
        START:begin
            if(s12s2_start)begin
                state_n = RESEV;
            end
            else begin
                state_n = state_c;
            end
            end
        RESEV:begin
            if(s22s3_start)begin
                state_n = STOP;
            end
            else begin
                state_n = state_c;
            end
            end
        STOP:begin
            if(s32idl_start)begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
            end
        default:begin
            state_n = IDLE;
        end
    endcase
end

//第三段：设计转移条件
assign idl2s1_start  = state_c==IDLE && rx_temp==2'b10;
assign s12s2_start = state_c==START  && cnt>=DELAY-1;
assign s22s3_start = state_c==RESEV  && cnt_bit==8 && cnt>=DELAY-1;
assign s32idl_start  = state_c==STOP && rx_temp==2'b11 || cnt>=DELAY-1;

//第四段：同步时序always模块，格式化描述寄存器输出（可有多个输出）
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <=0;      //初始化
        cnt_bit <=0;
        rx_temp <=0;
        data_out <=0;
        valid <=0;
    end
    else begin
        case(state_c)
            IDLE:begin
                cnt <=1'b0;
                cnt_bit <=1'b0;
                rx_temp <={rx_temp[0],rx};
                data_out <=data_out;
                valid <=1'b0;
            end
            START:begin
                if(cnt >= DELAY-1)
                    cnt <= 0;
                else
                    cnt <= cnt+1;
                cnt_bit<=0;
                data_out<=data_out;
                valid<=0;
            end
            RESEV:begin
                if(cnt>=DELAY-1)
                    cnt<=0;
                else
                    cnt<=cnt+1;
                if(cnt==(DELAY>>1))begin
                    cnt_bit<=cnt_bit+1;
                    data_out<={rx,data_out[7:1]};
                end
                else begin
                    cnt_bit <= cnt_bit;
                    data_out <= data_out;
                end
                valid<=0;
                rx_temp<={rx_temp[0],rx};
            end
            STOP:begin
                if(cnt>=DELAY-1)
                    cnt<=0;
                else
                    cnt<=cnt+1;
                rx_temp<={rx_temp[0],rx};
                data_out <= data_out;
                cnt_bit <= 0;
                if(cnt==0)
                    valid<=1;
                else
                    valid<=0;
            end
            default:begin
                cnt <=1'b0;
                cnt_bit <=1'b0;
                rx_temp <={rx_temp[0],rx};
                data_out <=data_out;
                valid <=1'b0;
            end
        endcase
    end
end
endmodule
