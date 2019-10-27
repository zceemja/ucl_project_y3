# UCL 3rd year project

## Performance characterisation of 8-bit RISC and OISC architectures

The aim is to compare similar characteristic RISC and OISC architectures to determinate advantages and trade-offs following points:
* Which processor is easier to implement and expand;
* Which processor requires less resources to implement;
* Which processor performs on common benchmark;

Possible application of both architectures could be use inside of microcontroller or SoC (System on a chip) systems similar to 8bit Atmel AVR or Mirochip PIC microcontrollers,
therefore processors must be capable of controlling and communicating with external modules such as UART and GPIO.

## Files Structure
This project based on Intel Quartus. Hardware is implemented in SystemVerilog.
Project directories:
* *src* - All HDL files,
* *src/risc* - HDL files specific to risc processor,
* *src/oisc* - HDL files specific to oisc processor,
* *src/blocks* - HDL files that are shared between both processors,
* *tools* - Implemented tools like compiler for designed architecture,
* *memory* - Instructions and machine code,
* *docs* - All documentation,
* *quartus* - Quartus generated IP files,
* *simulation* - ModelSim simulation files.

## Hardware Structure
The top level has 4 block:

_PLL_ 

Generates various frequences from main 50MHz crystal. Currenty 3 clock are generated:
* mclk - 1MHz master clock for processor and uart,
* fclk - 100MHz fast clock for sdram controller,
* aclk - 32,768kHz auxiliary clock for timers (to be implemented).


_SDRAM Block_ 

Includes sdram controller and fifo queues to synchonise data between mclk and fclk. It communicates with processor using 24bit address bus and 16bit data bus. It is up to processor to decide how to efficiantly store data in this memory.


_COM Block_

This include all external functions that might be useful for processor, e.g. UART, on board LED and DIP switch control. In future this might include timers or other communication methods. Processor communicates to this block via 8bit address bus and 8bit data bus. The table of addresses to function map will be added in the future. 

_Processor_ 

The processor itself. This desiged to have common interface so RISC and OISC processor and their variations could be simply swapped between without need to rewrite all project.


## Implementations

### FPGA
The hardware is tested on [DE0 Nano](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=165&No=593&PartNo=2) FPGA board.

### UART
Uses [Open Source Documented Verilog UART](https://github.com/freecores/osdvu) library. This is simple 1 file library without any hardware FIFO queues.

Pinout:
* *RX* - GPIO-0 Pin2 (GPIO_00)
* *TX* - GPIO-0 Pin4 (GPIO_01)

### SDRAM
Uses [sdram-controller](https://github.com/stffrdhrn/sdram-controller) library to communicate with sdram chip on DE0 Nano board.
