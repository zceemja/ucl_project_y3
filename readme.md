# UCL 3rd year project

## Performance characterisation of 8-bit RISC and OISC architectures

The aim is to compare similar characteristic RISC and OISC architectures to determinate advantages and trade-offs following points:
* Which processor is easier to implement and expand;
* Which processor requires less resources to implement;
* Which processor performs on common benchmark;
Possible application of both architectures could be use inside of microcontroller or SoC (System on a chip) systems similar to 8bit Atmel AVR or Mirochip PIC microcontrollers, therefore processors must be capable of controlling and communicating with external modules such as UART\footnote{Universal asynchronous receiver-transmitter} and GPIO (General Purpose Input/Output).

## Project Structure
This project based on Intel Quartus. Hardware is implemented in SystemVerilog.
Project directories:
* *src* - All HDL files,
* *src/risc* - HDL files specific to risc processor,
* *src/oisc* - HDL files specific to oisc processor,
* *src/blocks* - HDL files that are shared between both processors,
* *tools* - Implemented tools like compiler for designed architecture,
* *memory* - Instructions and machine code,
* *docs* - All documentation,
* *simulation* - ModelSim simulation files.


