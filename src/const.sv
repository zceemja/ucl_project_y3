// Global config

// Master clock frequency
`define MCLK_PLL_MUL 1
`define MCLK_PLL_DIV 50
// 50MHz * 3 / 25 = 6MHz

// UART Clock divider:
// UART0_DIV = MCLK_FREQ / (BAUD * 4) = 26
`define BAUD 9600
//`define UART0_DIV (50e6 * `MCLK_PLL_MUL / `MCLK_PLL_DIV) / (`BAUD * 4)
`define UART0_CLK_DIV 26

// Processor architecture
`define OISC
`define SYNTHESIS 
// Number of 16bit cells in ram 
//`define RAM_SIZE 8192 
`define RAM_SIZE 4096

// Add debugging hardware to processor
//`define DEBUG

`define ROMDIR "../../memory/build/"
`define RAMDIR "../../memory/build/"
