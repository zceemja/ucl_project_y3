b1111_0010 // 0x0000
0x0008
b1011_0000 // 0x0003 func AddAllBy1
b1011_0100 // 0x0004
b1011_1000 // 0x0005
b1011_1100 // 0x0006
b1111_0001 // 0x0007

COPY r0 0x15 // 0x0008
COPY r2 r0   // 0x000a
COPY r1 0x0a // 0x000b

b1111_0000 // 0x000d Call AddAllBy1
0x0003
ADD  r0 r1 // 0x000f
COPY r0 r2 // 0x0010
SUB  r0 r1 
COPY r0 r2
AND  r0 r1
COPY r0 r2
OR  r0 r1
COPY r0 r2
XOR  r0 r1
COPY r0 r2
COPY r0 100
MUL  r0 r1
b1011_1110 // Load ALU_HI to r3
COPY r0 r2
DIV  r0 r1
b1011_1110
DIV  r1 r2
b1011_1110
b1011_0000 // &r0++
b1011_0000 // &r0++
b1011_0001 // &r0--
b1011_0001 // &r0--

b1101_0000 // Branch to 0x000f if r1 == 0
0x00000f   
COPY r3 40h
b1101_1110 // Branch to 0x000f if r1 >= 41h
0x41000f   
b1101_1101 // Branch to 0x000f if r1 > 40h
0x40000f   
b1101_1110 // Branch to 0x000f if r1 >= 40h
0x40000f   

COPY r0 32h 
COPY r1 4fh
b1010_0001  // Store 32 to high memory
b1010_0111  // Store 4f to low 000001h
0x010000
COPY r0 0
COPY r1 r0
b1010_0000
0x010000
b1010_0010
0x010000

// Testing COM
b1100_0010
ffh

// Testing Stack
COPY r0 11h
COPY r1 22h
COPY r2 33h
COPY r3 44h
b1100_0000  // PUSH r0
b1100_0100  // PUSH r1
b1100_1000  // PUSH r2
b1100_1100  // PUSH r3
COPY r3 55h
b1100_1100  // PUSH r2

COPY r0 00h
b1100_0001 // POP r2
b1100_0001 // POP r2
b1100_0001 // POP r2
b1100_0001 // POP r2
b1100_0001 // POP r2



b1111_0010 // Reset
0x0000
