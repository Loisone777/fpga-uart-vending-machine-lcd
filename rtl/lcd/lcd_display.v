`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/16 14:42:56
// Design Name: 
// Module Name: lcd_display
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


module lcd_display(
    input   wire        sys_clk     ,
    input   wire        sys_rst_n   ,
    input   wire        data_flag   , //RAM中的数据已经写满标志（开始传输数据到LCD）
    input   wire [15:0] ram_data    ,//RAM中的图像数据
    output  reg         lcd_rst     ,//LCD硬件复位
    output  wire        CSX         ,//片选信号
    output  reg         DCX         ,//LCD指令/数据信号（低电平指令，高电平参数/数据）
    output  reg         WRX         ,//LCD写  上升沿写数据
    output  wire        RWX         ,//LCD读  上升沿读数据
    output  reg         BL          ,////背光信号  点亮LCD
    output  reg [15:0]  data_lcd    ,//输入给LCD的数据
    output  reg [16:0]  addrb        //RAM的读地址    
    );
      
assign  RWX = 1;
parameter   CNT_CLK_MAX = 20,//分频
            DATA_MAX = 76806;//图像数据的个数
reg     [4:0]   cnt_clk;
reg     [31:0]  cnt_bit;   
localparam  IDLE    = 11'b000_0000_0001,
            INIT    = 11'b000_0000_0010,//初始化
            XULIE   = 11'b000_0000_0100,//序列选择 LCD扫描方式
            WAIT_KEY= 11'b000_0000_1000,// 等待RAM写完数据
            PIC_X   = 11'b000_0001_0000, //确定显示区域X
            PIC_Y   = 11'b000_0010_0000, //确定显示区域Y
            WRITE   = 11'b000_0100_0000, //填充数据命令
            DATA    = 11'b000_1000_0000,//传输数据
            SLEEP   = 11'b001_0000_0000,//关闭睡眠模式
            DELAY   = 11'b010_0000_0000, //延时120ms
            DISP    = 11'b100_0000_0000;//将LCD中的GRAM的数据传到显示屏上
reg [10:0]   cure_state;
reg [10:0]   next_state;

assign  CSX = (cure_state == XULIE || cure_state == PIC_X || cure_state == PIC_Y || 
                cure_state == WRITE || cure_state == DATA || cure_state == SLEEP || 
                cure_state == DISP || cure_state == INIT) ? 0 : 1;

parameter   CNT_DELAY_MAX = 125_100_00;
reg     [23:0]  cnt_100ms;
reg     [23:0]  cnt_120ms;
parameter   CNT_DELAY_120 = 150_100_00;

always @(posedge sys_clk)
    if(!sys_rst_n)
        addrb <= 'd0;
    else if(cure_state == DATA)begin
        if(addrb == DATA_MAX && cnt_clk == CNT_CLK_MAX - 1)
            addrb <= 'd0;
        else if(cnt_clk == CNT_CLK_MAX - 1)
            addrb <= addrb + 1;
        else 
            addrb <= addrb;
    end 
    else 
        addrb <= 'd0;
        
always @(posedge sys_clk)
    if(!sys_rst_n)
        BL <= 0;
    else if(cure_state == DISP && cnt_clk == CNT_CLK_MAX - 1)
        BL <= 1;
    else 
        BL <= BL;
always @(posedge sys_clk)
    if(!sys_rst_n)
        cnt_120ms <= 'd0;
    else if(cnt_120ms == CNT_DELAY_120 - 1)
        cnt_120ms <= cnt_120ms;
    else if(cure_state == DELAY)
        cnt_120ms <= cnt_120ms  + 1;
        
//LCD复位需要持续100ms
always @(posedge sys_clk)
    if(!sys_rst_n)
        cnt_100ms <= 'd0;
    else if(cnt_100ms == CNT_DELAY_MAX - 1)
        cnt_100ms <= cnt_100ms;
    else 
        cnt_100ms <= cnt_100ms  + 1;
        
always @(posedge sys_clk)
    if(!sys_rst_n)
        lcd_rst <= 0;
    //else if(cnt_100ms == CNT_DELAY_MAX - 1)
    //    lcd_rst <= 1;
    else 
        lcd_rst <= 1;
        
always @(posedge sys_clk)
    if(!sys_rst_n)
        cure_state <= IDLE;
    else 
        cure_state <= next_state;
        
always @(*)
    case(cure_state)
        IDLE    :begin
            if(cnt_100ms == CNT_DELAY_MAX - 1)
                next_state = INIT;
            else 
                next_state = IDLE;
        end 
        INIT:begin
            if(cnt_bit == 76 && cnt_clk == CNT_CLK_MAX - 1)
                next_state = XULIE;
            else 
                next_state = INIT;
        end 
        XULIE   :begin
            if(cnt_bit == 1 && cnt_clk == CNT_CLK_MAX - 1)
                next_state = WAIT_KEY;
            else 
                next_state = XULIE;
        end 
        WAIT_KEY:begin
            if(data_flag)
                next_state = PIC_X;
            else 
                next_state = WAIT_KEY;
        end 
        PIC_X   :begin
            if(cnt_bit == 4 && cnt_clk == CNT_CLK_MAX - 1)
                next_state = PIC_Y;
            else 
                next_state = PIC_X;
        end 
        PIC_Y   :begin
            if(cnt_bit == 4 && cnt_clk == CNT_CLK_MAX - 1)
                next_state = WRITE;
            else 
                next_state = PIC_Y;
        end 
        WRITE   :begin
            if(cnt_clk == CNT_CLK_MAX - 1)
                next_state = DATA;
            else 
                next_state = WRITE;
        end 
        DATA    :begin
            if(cnt_bit == DATA_MAX && cnt_clk == CNT_CLK_MAX - 1)
                next_state = SLEEP;
            else 
                next_state = DATA;
        end 
        SLEEP:begin
            if(cnt_clk == CNT_CLK_MAX - 1)
                next_state = DELAY;
            else 
                next_state = SLEEP;
        end 
        DELAY:begin
            if(cnt_120ms == CNT_DELAY_120 - 1)  
                next_state = DISP;
            else 
                next_state = DELAY;
        end 
        DISP:begin
            if(cnt_clk == CNT_CLK_MAX - 1)
                next_state = WAIT_KEY;
            else 
                next_state = DISP;
        end 
        default:next_state = IDLE;
    endcase
     
always @(posedge sys_clk)
    if(!sys_rst_n)begin
        cnt_clk <= 'd0;
        cnt_bit <= 'd0;
    end 
    else 
        case(cure_state)
            IDLE,WAIT_KEY,DELAY:begin
                cnt_clk <= 'd0;
                cnt_bit <= 'd0;
            end
            INIT:begin
                if(cnt_clk == CNT_CLK_MAX - 1)begin
                    if(cnt_bit == 76)begin
                        cnt_bit <= 'd0;
                        cnt_clk <= 'd0;
                    end 
                    else begin
                        cnt_bit <= cnt_bit + 1;
                        cnt_clk <= 'd0;
                    end 
                end 
                else begin
                    cnt_clk <= cnt_clk + 1;
                    cnt_bit <= cnt_bit;
                end 
            end 
            XULIE:begin
                if(cnt_clk == CNT_CLK_MAX - 1)begin
                    if(cnt_bit == 1)begin
                        cnt_bit <= 'd0;
                        cnt_clk <= 'd0;
                    end 
                    else begin
                        cnt_bit <= cnt_bit + 1;
                        cnt_clk <= 'd0;
                    end 
                end 
                else begin
                    cnt_clk <= cnt_clk + 1;
                    cnt_bit <= cnt_bit;
                end 
            end 
            PIC_X,PIC_Y:begin
                if(cnt_clk == CNT_CLK_MAX - 1)begin
                    if(cnt_bit == 4)begin
                        cnt_bit <= 'd0;
                        cnt_clk <= 'd0;
                    end 
                    else begin
                        cnt_bit <= cnt_bit + 1;
                        cnt_clk <= 'd0;
                    end 
                end 
                else begin
                    cnt_clk <= cnt_clk + 1;
                    cnt_bit <= cnt_bit;
                end 
            end   
            WRITE,SLEEP,DISP:begin
                cnt_bit <= 'd0;
                if(cnt_clk == CNT_CLK_MAX - 1)
                    cnt_clk <= 'd0;
                else 
                    cnt_clk <= cnt_clk + 1;
            end 
            DATA:begin
                if(cnt_clk == CNT_CLK_MAX - 1)begin
                    if(cnt_bit == DATA_MAX)begin
                        cnt_bit <= 'd0;
                        cnt_clk <= 'd0;
                    end 
                    else begin
                        cnt_bit <= cnt_bit + 1;
                        cnt_clk <= 'd0;
                    end 
                end 
                else begin
                    cnt_clk <= cnt_clk + 1;
                    cnt_bit <= cnt_bit;
                end 
            end   
            default:begin
                cnt_clk <= 'd0;
                cnt_bit <= 'd0;
            end
        endcase
            
always @(posedge sys_clk)
    if(!sys_rst_n)
        WRX <= 1;
    else 
        case(cure_state)
            IDLE,WAIT_KEY,DELAY:WRX <= 1;
            XULIE:begin
                if(cnt_bit == 0 && cnt_clk >= (CNT_CLK_MAX/4 - 1) && cnt_clk <= (CNT_CLK_MAX/4*3 - 1))
                    WRX <= 1;
                else if(cnt_bit == 1 && cnt_clk >= (CNT_CLK_MAX/4 - 1))
                    WRX <= 1;
                else 
                    WRX <= 0;
            end 
            PIC_X,PIC_Y,WRITE,DATA,INIT:begin
                if(cnt_clk >= (CNT_CLK_MAX/4 - 1) && cnt_clk <= (CNT_CLK_MAX/4*3 - 1))
                    WRX <= 1;
                else 
                    WRX <= 0;
            end 
            SLEEP,DISP:begin
                if(cnt_clk >= (CNT_CLK_MAX/4 - 1))
                    WRX <= 1;
                else 
                    WRX <= 0;
            end 
            default:WRX <= 1;
        endcase 
        
always @(posedge sys_clk)
    if(!sys_rst_n)
        DCX <= 1;
    else 
        case(cure_state)
            IDLE,WAIT_KEY,DELAY:DCX <= 1;
            INIT:begin
                case(cnt_bit)
                    0,4,9,13,19,21,24,26,28,31,33,35,38,41,43,45,61:DCX <= 0;
                    default:DCX <= 1;
                endcase 
            end 
            XULIE,PIC_X,PIC_Y:begin
                if(cnt_bit == 0)
                    DCX <= 0;
                else
                    DCX <= 1;
            end 
            WRITE,SLEEP,DISP:DCX <= 0;
            DATA:DCX <= 1;  
            default:DCX <= 1;
        endcase 
        
always @(posedge sys_clk)
    if(!sys_rst_n)
        data_lcd <= 'd0;
    else 
        case(cure_state)
            IDLE,WAIT_KEY,DELAY:data_lcd <= 'd0;
            INIT:begin
                case(cnt_bit)
                    0: data_lcd <= 16'h00cf; //
                    1: data_lcd <= 16'h0;
                    2: data_lcd <= 16'h00c9;
                    3: data_lcd <= 16'h0030;
                    4: data_lcd <= 16'h00ed;//
                    5: data_lcd <= 16'h0064;
                    6: data_lcd <= 16'h0003;
                    7: data_lcd <= 16'h0012;
                    8: data_lcd <= 16'h0081;
                    9: data_lcd <= 16'h00e8;//
                    10:data_lcd <= 16'h0085;
                    11:data_lcd <= 16'h0010;
                    12:data_lcd <= 16'h007a;
                    13:data_lcd <= 16'h00cb;//
                    14:data_lcd <= 16'h0039;
                    15:data_lcd <= 16'h002c;
                    16:data_lcd <= 16'h0;
                    17:data_lcd <= 16'h0034;
                    18:data_lcd <= 16'h0002;
                    19:data_lcd <= 16'h00f7;//
                    20:data_lcd <= 16'h0020;
                    21:data_lcd <= 16'h00ea;//
                    22:data_lcd <= 16'h0;
                    23:data_lcd <= 16'h0;
                    24:data_lcd <= 16'h00c0;//
                    25:data_lcd <= 16'h001b;
                    26:data_lcd <= 16'h00c1;//
                    27:data_lcd <= 16'h0;
                    28:data_lcd <= 16'h00c5;//
                    29:data_lcd <= 16'h0030;
                    30:data_lcd <= 16'h0030;
                    31:data_lcd <= 16'h00c7;//
                    32:data_lcd <= 16'h00b7;
                    33:data_lcd <= 16'h003a;//
                    34:data_lcd <= 16'h0055;
                    35:data_lcd <= 16'h00b1;//
                    36:data_lcd <= 16'h0;
                    37:data_lcd <= 16'h001a;
                    38:data_lcd <= 16'h00b6;//
                    39:data_lcd <= 16'h000a;
                    40:data_lcd <= 16'h00a2;
                    41:data_lcd <= 16'h00f2;//
                    42:data_lcd <= 16'h0;
                    43:data_lcd <= 16'h0026;//
                    44:data_lcd <= 16'h0001;
                    45:data_lcd <= 16'h00e0;//
                    46:data_lcd <= 16'h000f;
                    47:data_lcd <= 16'h002a;
                    48:data_lcd <= 16'h0028;
                    49:data_lcd <= 16'h0008;
                    50:data_lcd <= 16'h000e;
                    51:data_lcd <= 16'h0008;
                    52:data_lcd <= 16'h0054;
                    53:data_lcd <= 16'h00a9;
                    54:data_lcd <= 16'h0043;
                    55:data_lcd <= 16'h000a;
                    56:data_lcd <= 16'h000f;
                    57:data_lcd <= 16'h0;
                    58:data_lcd <= 16'h0;
                    59:data_lcd <= 16'h0;
                    60:data_lcd <= 16'h0;
                    61:data_lcd <= 16'h00e1;//
                    62:data_lcd <= 16'h0;
                    63:data_lcd <= 16'h0015;
                    64:data_lcd <= 16'h0017;
                    65:data_lcd <= 16'h0007;
                    66:data_lcd <= 16'h0011;
                    67:data_lcd <= 16'h0006;
                    68:data_lcd <= 16'h002b;
                    69:data_lcd <= 16'h0056;
                    70:data_lcd <= 16'h003c;
                    71:data_lcd <= 16'h0005;
                    72:data_lcd <= 16'h0010;
                    73:data_lcd <= 16'h000f;
                    74:data_lcd <= 16'h003f;
                    75:data_lcd <= 16'h003f;
                    76:data_lcd <= 16'h000f;
                    default:data_lcd <= 'd0;
                endcase 
            end 
            XULIE:begin
                if(cnt_bit == 0)
                    data_lcd <= 16'h0036;
                else 
                    data_lcd <= 16'h0000;
            end 
            PIC_X:begin
                if(cnt_bit == 0)
                    data_lcd <= 16'h002a;
                else if(cnt_bit == 1 || cnt_bit == 2 || cnt_bit == 3)
                    data_lcd <= 16'h0;
                else 
                    data_lcd <= 16'h00ef;
            end 
            PIC_Y:begin
                if(cnt_bit == 0)
                    data_lcd <= 16'h002b;
                else if(cnt_bit == 1 || cnt_bit == 2)
                    data_lcd <= 16'h0;
                else if(cnt_bit == 3)
                    data_lcd <= 16'h0001;   
                else
                    data_lcd <= 16'h003f;
            end 
            WRITE:data_lcd <= 16'h002c;
            DATA:data_lcd <= ram_data;
            SLEEP:data_lcd <= 16'h0011;
            DISP:data_lcd <= 16'h0029;
            default:data_lcd <= 'd0;
        endcase

endmodule
