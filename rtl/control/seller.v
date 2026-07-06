`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/14 14:57:07
// Design Name: 
// Module Name: seller
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


module	seller(
	input              clk        ,
	input              rst_n      ,
	input              key_done   ,
	input      [1:0]   key_num    ,   //0Ôö1¼õ
	input      [7:0]   uart_in    ,	
	output reg [7:0]   uart_out   ,
	output reg         en         ,
	output reg         led         ,
	output reg         led1         ,
	output reg         led2         ,
	output reg         led3         ,
	output reg         led4         ,
	output reg [7:0]   lcd_flag
);

parameter SYSCLK = 125_000_000;
parameter BAUD = 115200;

parameter IDLE      = 4'b00001;
parameter CHOOSE    = 4'b00010;
parameter NUM       = 4'b00100;
parameter STOP      = 4'b01000;
parameter GET       = 5'b10000;

reg [31:0]sum;
reg [31:0]sum_out;

reg [31:0]key_cnt;

reg [4:0] state_c;
reg [4:0] state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state_c <= IDLE;
    else 
        state_c <= state_n;
end

always@(*) begin
	 if(!rst_n)
		state_n  = IDLE;
	else case(state_c)
            IDLE    :begin 
                      if(uart_in == 8'h11)
                            state_n = CHOOSE;
                      else state_n = IDLE	;
                     end
            CHOOSE  :begin
                       if(uart_in == 8'h22)
                            state_n = STOP ;
                       else if(uart_in >= 8'h31 && uart_in<=8'h0f)
                            state_n = NUM;
                       else if(uart_in == 8'h33)
                            state_n = IDLE;
                       else state_n = CHOOSE;
                     end
            NUM 	 :begin	
                       if(key_done) begin
                           if(uart_in == 8'h33)
                                state_n = IDLE;
                            else if(uart_in == 8'h55)
                                state_n = CHOOSE;
                       end
                       else state_n = NUM ;
                      end
            STOP	  :begin	
                       if(uart_in == 8'h44)
                           state_n = GET ;
                       else if(uart_in == 8'h33)
                            state_n = IDLE;
                       else state_n = STOP ;
                      end
            GET       :begin	
                       if(uart_in == 8'h16)
                           state_n = IDLE ;
                       else state_n = GET ;
                      end
            default   :state_n = IDLE ;
		endcase
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sum_out <= 0;
        key_cnt <= 0;
        en <= 0;
        sum <= 0;
        led <= 0;
        led1 <= 0;
        led2 <= 0;
        led3 <= 0;
        led4 <= 0;
        lcd_flag <= 0;
    end
    else begin
        case(state_c)
            IDLE:begin
                sum_out <= 0;
                key_cnt <= 0;
                sum <= 0;
                en <= 0;
                uart_out <= 8'h00;
                led <= 0;
                led1 <= 0;
                led2 <= 0;
                led3 <= 0;
                led4 <= 0;
                lcd_flag <= 8'b00000001;
            end
            CHOOSE:begin
                sum_out <= sum_out;
                key_cnt <= 0;
                en <= 0;
                uart_out <= 8'h00;
                led <= 0;
                led1 <= 1;
                led2 <= 0;
                led3 <= 0;
                led4 <= 0;
                case (uart_in)
                    8'h31 : begin
                        lcd_flag <= 8'b00000010;
                        sum = 12;
                    end
                    8'h02 : begin
                        lcd_flag <= 8'b00000100;
                        sum = 14;
                    end
                    8'h03 : sum = 12;
                    8'h04 : sum = 15; 
                    8'h05 : sum = 14;
                    8'h06 : sum = 14;
                    8'h07 : sum = 16;
                    8'h08 : sum = 12;
                    8'h09 : sum = 16;
                    8'h0a : sum = 14;
                    8'h0b : sum = 9;
                    8'h0c : sum = 9;
                    8'h0d : sum = 15;
                    8'h0e : sum = 12;
                    8'h0f : sum = 14;
                endcase
            end
            NUM:begin
                uart_out <= 8'h00;
                en <= 0;
                led <= 0;
                led1 <= 0;
                led2 <= 1;
                led3 <= 0;
                led4 <= 0;
                if(key_done)begin
                    sum_out <= sum_out + sum * (key_cnt+1);
                end
                else if(key_num[0])begin
                    if(key_cnt == 8'hff)
                        key_cnt <= key_cnt;
                    else   
                        key_cnt <= key_cnt+1; 
                end
                else if(key_num[1])begin
                    if(key_cnt == 8'h00)
                        key_cnt <= key_cnt;
                    else   
                        key_cnt <= key_cnt-1; 
                end
                else begin
                    key_cnt <= key_cnt;
                    sum <= sum;
                end
            end
            STOP:begin
                lcd_flag <= 8'b00001000;
                sum_out <= 0;
                key_cnt <= 0;
                sum <= sum;
                uart_out <= 8'h00;
                en <= 0;
                led <= 0;
                led3 <= 1;
                led2 <= 0;
                led1 <= 0;
                led4 <= 0;
            end
            GET:begin
                sum_out <= 0;
                key_cnt <= 0;
                sum <= 0;
                en <= 1;
                uart_out <= 8'h15;
                led <= 1;
                led4 <= 1;
                led2 <= 0;
                led3 <= 0;
                led1 <= 0;
            end
            default:begin
                sum_out <= 0;
                key_cnt <= 0;
                sum <= 0;
                led <= 0;
                en <= 0;
                uart_out <= 8'h00;
            end
        endcase
    end
end        

endmodule
