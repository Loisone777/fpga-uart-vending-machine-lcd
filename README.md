# FPGA UART-Controlled Vending Machine with LCD Display

A Verilog-based FPGA vending-machine controller that combines UART communication, debounced push-button input, finite-state-machine (FSM) control, LED status indication, and LCD product-image display.

The design receives control commands through UART, allows quantity adjustment through push buttons, moves through the transaction flow using an FSM, sends a response through UART, and selects LCD images through Xilinx Block Memory Generator IP cores.

## Features

- UART receiver and transmitter configured for **115200 baud**
- FSM-based vending transaction control
- UART-based transaction and product-selection commands
- Push-button input for quantity increase, decrease, and confirmation
- Button-debounce interface through the `key_xd` module
- Four LED state indicators plus a transaction/output LED
- LCD initialization and RGB565-format image output
- Three Xilinx Block Memory Generator IP instances for product-image storage
- RTL testbenches for seller-control and button-related verification

## Design Overview

```text
                         ┌─────────────┐
                         │  UART RX    │
                         └──────┬──────┘
                                │ uart_in[7:0]
                                ▼
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│ Push Buttons│ ───────► │   key_xd    │ ───────► │   seller    │
│ done/up/down│          │  debounce   │          │ FSM/control │
└─────────────┘          └─────────────┘          └──────┬──────┘
                                                         │
                     ┌───────────────────────────────────┼────────────────────────────┐
                     │                                   │                            │
                     ▼                                   ▼                            ▼
              ┌─────────────┐                      ┌─────────────┐            ┌─────────────┐
              │  UART TX    │                      │ LEDs/status │            │  lcd_flag   │
              └─────────────┘                      └─────────────┘            └──────┬──────┘
                                                                                       │
                                                                                       ▼
                                                                             ┌───────────────────┐
                                                                             │ BRAM Image IP x3  │
                                                                             └─────────┬─────────┘
                                                                                       │ ram_data
                                                                                       ▼
                                                                             ┌───────────────────┐
                                                                             │   lcd_display     │
                                                                             └─────────┬─────────┘
                                                                                       │
                                                                                       ▼
                                                                                     LCD Panel
```

## Repository Structure

```text
.
├── constraints/
│   └── FPGA board constraint files (.xdc)
│
├── ip/
│   └── Vivado IP cores
│       ├── blk_mem_gen_0
│       ├── blk_mem_gen_1
│       └── blk_mem_gen_2
│
├── rtl/
│   ├── seller_top.v
│   ├── seller.v
│   ├── seller_key.v
│   ├── uart_rx.v
│   ├── uart_tx.v
│   └── lcd_display.v
│
└── tb/
    └── seller_tb.v
```

> **Important:** `seller_top.v` instantiates a `key_xd` debounce module. Keep `key_xd.v` in `rtl/` as well, or include it in the Vivado project from its original location. The current RTL also instantiates three Vivado Block Memory Generator IP cores: `blk_mem_gen_0`, `blk_mem_gen_1`, and `blk_mem_gen_2`.

## Main Modules

| Module | Role |
|---|---|
| `seller_top.v` | Top-level integration module. Connects UART, button inputs, seller FSM, LCD controller, BRAM image IP, and LED outputs. |
| `seller.v` | Core vending-machine controller. Implements the transaction FSM, quantity handling, LED status control, UART response control, and LCD image-selection flags. |
| `uart_rx.v` | UART receiver that samples serial input and outputs received bytes through `data_out[7:0]`. |
| `uart_tx.v` | UART transmitter that serializes `data[7:0]` when enabled. |
| `lcd_display.v` | LCD initialization and display controller. Reads image data from BRAM and drives LCD control/data signals. |
| `seller_key.v` | Button-related simulation file that instantiates `seller` and `key_xd`. This file is used as a testbench-style module rather than a synthesizable top-level module. |
| `seller_tb.v` | Main simulation testbench for the seller FSM and UART transmitter. |
| `key_xd.v` | Required debounce module used by `seller_top.v` and `seller_key.v`. Add this source file to `rtl/` if it is not already present. |

## FSM Behavior

The `seller` module uses the following states:

| State | Description |
|---|---|
| `IDLE` | Default state. Clears outputs and displays the default LCD image. Waits for the start command. |
| `CHOOSE` | Accepts product-selection input and sets the corresponding price/image flag. |
| `NUM` | Allows quantity adjustment using the up/down buttons. The confirmation button stores the current selection. |
| `STOP` | Transaction waiting/stop stage. |
| `GET` | Output stage. Enables UART transmission and asserts transaction-complete LED outputs. |

## UART Command Values Used by the Current RTL

| Hex value | Current FSM action |
|---|---|
| `8'h11` | Enter `CHOOSE` from `IDLE` |
| `8'h22` | Enter `STOP` from `CHOOSE` |
| `8'h33` | Return to `IDLE` from selected states |
| `8'h44` | Enter `GET` from `STOP` |
| `8'h55` | Return to `CHOOSE` from `NUM` after confirmation |
| `8'h16` | Return to `IDLE` from `GET` |
| Product code values | Used in `CHOOSE` to determine price and, for selected codes, LCD image flags |

The RTL currently configures UART timing with:

```verilog
parameter SYSCLK = 125_000_000;
parameter BAUD   = 115200;
```

## LCD and Image Storage

The top module selects one of three BRAM outputs using `lcd_flag`:

| `lcd_flag` | Selected image memory |
|---|---|
| `8'b00000001` | `blk_mem_gen_0` |
| `8'b00000010` | `blk_mem_gen_1` |
| `8'b00000100` | `blk_mem_gen_2` |

`lcd_display.v` drives the LCD interface signals:

- `lcd_rst`: LCD hardware reset
- `CSX`: chip select
- `DCX`: command/data select
- `WRX`: write strobe
- `RWX`: read/write control
- `BL`: backlight control
- `data_lcd[15:0]`: LCD pixel/command data

The LCD image data is read from BRAM and reordered before being sent to the display controller.

## Build in Vivado

1. Create a new RTL project in Xilinx Vivado.
2. Add all Verilog source files under `rtl/`.
3. Add `key_xd.v` if it is stored outside the current repository folder.
4. Add the Block Memory Generator IP cores under `ip/`.
5. Add the board constraint file from `constraints/`.
6. Set `seller_top` as the synthesis top module.
7. Confirm that the following module/IP dependencies resolve successfully:
   - `key_xd`
   - `blk_mem_gen_0`
   - `blk_mem_gen_1`
   - `blk_mem_gen_2`
8. Run synthesis, implementation, and bitstream generation.
9. Program the FPGA and connect the UART interface and LCD hardware.

## Simulation

### Seller FSM Simulation

1. Add all RTL source files required by `seller_tb.v`.
2. Add `tb/seller_tb.v` as a simulation source.
3. Set `seller_tb` as the simulation top module.
4. Run behavioral simulation.
5. Inspect these signals in the waveform viewer:
   - `uart_in`
   - `uart_out`
   - `key_done`
   - `key_num`
   - `en`
   - `led`, `led1`, `led2`, `led3`, `led4`
   - internal FSM state signals in `seller`

The provided testbench exercises a sequence that enters the selection state, adjusts quantity, confirms selections, enters the stop state, and triggers the output state.

### Button/Debounce Simulation

`seller_key.v` can be used to observe the behavior of the `key_xd` debounce module. It requires `key_xd.v` to be added to the simulation sources.

## Hardware Interface Summary

| Interface | Signals |
|---|---|
| Clock/reset | `clk`, `rst_n` |
| UART | `rx`, `tx` |
| Buttons | `key_done`, `key_num[1:0]` |
| Status outputs | `signal_done`, `led`, `led1`, `led2`, `led3`, `led4` |
| LCD | `lcd_rst`, `CSX`, `DCX`, `WRX`, `RWX`, `BL`, `data_lcd[15:0]` |

## Known Integration Items to Check

Before publishing or recreating the project on another computer, verify the following items:

- Add the missing `key_xd.v` source file to the repository or document where it is obtained.
- Confirm that the three `blk_mem_gen_*` Vivado IP cores and any image initialization files are included in `ip/`.
- Confirm that the `.xdc` file matches the actual FPGA board, clock input, UART pins, push buttons, LED pins, and LCD pins.
- In `seller_top.v`, check the UART transmitter port connection. The top-level output port is named `tx`, while the current UART TX instance uses `.TX(TX)`. This should be verified and corrected to the intended signal name if necessary.
- In `seller_top.v`, check the button-valid signal names. The declared wires are `key_up_valid` and `key_down_valid`, while the instances use `key_up_vld` and `key_down_vld`. Use consistent names before synthesis.
- In `seller.v`, review the product-selection condition `uart_in >= 8'h31 && uart_in <= 8'h0f`; as written, the lower bound is greater than the upper bound. Confirm the intended command range.
- In `lcd_display.v`, `data_flag` is declared as a 1-bit input while `seller_top.v` connects the 8-bit `lcd_flag` bus. Confirm whether the LCD controller should receive a single valid bit or the full image-selection bus.

## Future Improvements

- Add a documented UART command protocol with command names and response bytes.
- Add product inventory tracking and out-of-stock handling.
- Add payment, balance, or credit validation logic.
- Add a self-checking SystemVerilog testbench with assertions and expected-output checks.
- Add waveform screenshots and hardware demonstration images.
- Add a Vivado TCL script to recreate the complete project automatically.
- Add a `docs/` folder with a block diagram, state-transition diagram, board connections, and LCD image-generation instructions.
