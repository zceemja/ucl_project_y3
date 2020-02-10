%define COM_UARTF 	0x03
%define COM_UARTW 	0x05
%define COM_UARTR 	0x04
%define COM_LED 	0x06
%define COM_DIP 	0x08
%define COM_UARTIN 	0x09
%define LF          0x0a
%define CR          0x0d
%define LFCR        0x0a0d
%define COM_UART_TRANS 	0b0000_0001
%define COM_UART_RECV 	0b0000_0010
%define COM_UART_ECHO 	0b0000_0100
%define COM_UART_RR 	0b0000_1000 ; Read Ready

%macro MEMP 1
	MEM1 %1@1
	MEM0 %1@0
%endmacro

%macro BRP 1
	BR1 %1@1
	BR0 %1@0
%endmacro

%macro RET 0
	BR0 STACK
	BR1 STACK
	BRZ NULL
%endmacro

%macro CALL 1
    BRP %1 
    STACK %%return@1
    STACK %%return@0
    BRZ NULL
%%return:
%endmacro

%macro JUMP 1
	BRP %1
	BRZ NULL
%endmacro

%macro BRPZ 2
	BRP %1
	BRZ %2
%endmacro

%macro PRINTMEM 0
	REG0 LWHI
	CALL print_hex
	REG0 LWLO
	CALL print_hex
	REG0 0x20
	CALL print_char
%endmacro

%macro PRINTREG 0
  STACK REG0
  STACK REG0
  REG0 REG1
  CALL print_hex
  REG0 STACK
  CALL print_hex
  REG0 0x20
  CALL print_char
  REG0 LWHI
  CALL print_hex
  REG0 LWLO
  CALL print_hex
  CALL println
  REG0 STACK
%endmacro

; ==================
; Jump on conditions
; ==================
%macro BGT 1
  BRPZ %1,LE
%endmacro
%macro BLT 1
  BRPZ %1,GE
%endmacro
%macro BGE 1
  BRPZ %1,LT
%endmacro
%macro BLE 1
  BRPZ %1,GT
%endmacro
%macro BEQ 1
  BRPZ %1,NE
%endmacro
%macro BNE 1
  BRPZ %1,EQ
%endmacro

%macro CALC_SIEVE_POINTER 4
  ; args: [value of n] [shifted value to store to] [jump label] [debug letter]
  ;
  ;; start debug
  ;STACK REG0
  ;REG0 %4
  ;CALL print_char
  ;REG0 STACK
  ;STACK REG0
  ;REG0 %1
  ;CALL print_u8
  ;REG0 0x20
  ;CALL print_char
  ;REG0 STACK
  ;; stop debug
  ALU0 %1
  STACK ALU0
  ALU1 16
  ALU0 DIV
  ALU1 sieve2@0
  MEM0 ADD
  ALU0 sieve2@1
  ALU1 0x00
  MEM1 ADC  ; Memory pointer ready
  ALU0 STACK
  ALU1 16
  ALU1 MOD
  ALU0 1
  %2 SLL 
  ALU0 8   ; if n%16 >= 8
  BGE %3  ; is high byte memhi
%endmacro

section .data 2x3x8192
DBE 1
intro_text: DB 0x1B,"c",0x1B,"[HBooting ",0x1B,"[1m",0x1B,"[36m","OISC",0x1B,"[0m system..",LFCR,0
generalbuf: DBE 1
sieve:  DBE 1
sieve1: DBE 1
sieve2: DBE 16
section .text 2x3x2048
	REG0 intro_text@0
	REG1 intro_text@1
	CALL print_string
    ;ALU0 0x44
	;ALU1 0x44
	;REG0 NE
	;CALL print_hex
	;ALU0 0x33
	;ALU1 0x00
	;REG0 NE
	;CALL print_hex
	;CALL println
	
	REG0 '@'
	CALL print_char
    CALL calc_sieve
	REG0 '@'
	CALL print_char
	CALL println
	;JUMP forever
	REG0 0
.print_sieve:
	CALC_SIEVE_POINTER REG0,REG1,.hi,'x'
    ALU0 MEMLO
    JUMP .next
.hi:
    ALU0 MEMHI
.next:
    ALU1 REG1
	BRPZ .noprint,AND
	STACK REG0
	CALL print_u8
	REG0 0x20
	CALL print_char
	REG0 STACK
.noprint:
    ALU1 1
	ALU0 REG0
	REG0 ADD
    BRPZ forever,REG0
	JUMP .print_sieve
;    REG0 0
;hex_test:
;    ALU0 REG0
;	ALU1 1
;	REG0 ADD
;	CALL print_hex
;	REG1 REG0
;	REG0 0x20
;	CALL print_char
;	REG0 REG1
;    BRPZ .end,REG0
;	JUMP hex_test
;.end:
forever:
	JUMP forever	


calc_sieve:
;; Sieve of Atkin
  MEMP sieve
  MEMHI 1; x
.loopx:
  ALU0 MEMHI
  ALU1 MEMHI
  REG0 MULLO  ; x^2
  ;STACK MULHI
  ; print x
  ;STACK REG0
  ;REG0 'x'
  ;CALL print_char
  ;REG0 STACK
  ;STACK REG0
  ;CALL print_u8
  ;REG0 0x20
  ;CALL print_char
  ;ALU0 MULHI
  ;ALU1 0
  ;REG0 STACK
  ;; end print x

  ;ALU0 STACK
  ALU0 MULHI
  ALU1 0
  BNE .endp1 ; if x^2 > 255
  MEMLO 1; y
.loopy:
  ALU0 MEMLO
  ALU1 MEMLO
  REG1 MULLO  ; y^2

  ;STACK MULHI
  ;STACK REG0
  ;REG0 'y'
  ;CALL print_char
  ;REG0 REG1
  ;CALL print_u8
  ;REG0 0x20
  ;CALL print_char
  ;REG0 STACK

  ;ALU0 STACK
  ALU0 MULHI
  ALU1 0
  BNE .loopxe ; if y^2 > 255
  ; ==================
  ; Start of Main loop
  ; ==================
  ; At this point reg0 := x^2, reg1 := y^2
  MEMP sieve1
.c1:
  ALU0 REG0
  ALU1 4
  STACK MULLO
  ALU0 MULHI ; \
  ALU1 0     ; | Checking if 4x^2 > 255
  ALU1 EQ    ; / 
  ALU0 STACK
  BRPZ .c2,ALU1 ; if mulhi != 0: goto .c2
  ALU1 REG1  
  MEMHI ADD  ; n = mullo( low{4*x^2} ) + y^2
  ALU0 ADDC  ; \
  ALU1 0     ; | Checking if 4x^2+y^2 > 255
  BNE .c2    ; /
  ALU0 MEMHI ; MEMHI := n
  ALU1 12
  MEMLO MOD
  ALU0 MEMLO
  ALU1 1
  BEQ .c1r    ; n%12 == 1
  ALU0 MEMLO
  ALU1 5
  BEQ .c1r    ; n%12 == 5
  JUMP .c2
.c1r:
  CALL xorSieveArray
  MEMP sieve1
.c2:
  ALU0 REG0
  ALU1 3
  STACK MULLO
  ALU0 MULHI ; \
  ALU1 0     ; | Checking if 3x^2 > 255
  ALU1 EQ    ; /
  ALU0 STACK
  BRPZ .c3,ALU1
  ALU1 REG1
  STACK ADD
  ALU0 ADDC  ; \
  ALU1 0     ; | Checking if 3x^2+y^2 > 255 
  ALU1 EQ	 ; /
  ALU0 STACK 
  BRPZ .c3,ALU1 
  MEMHI ALU0 ; MEMHI := n
  ALU1 12
  ALU0 MOD
  ALU1 7
  BNE .c3
  CALL xorSieveArray
.c3:
  MEMP sieve
  ALU1 MEMLO ; y
  ALU0 MEMHI ; x
  BLE .loopye ; Function needs x>y

  MEMP sieve1
  ALU0 REG0
  ALU1 3
  MEMLO MULHI ; MEMLO := HIGH(3x^2)
  ALU0 MULLO
  ALU1 REG1
  MEMHI SUB   ; MEMHI := LOW(3x^2)-y^2
  ALU0 MEMLO  
  ALU1 0x00
  ALU0 SBC   ; ALU0 := HIGH(3x^2)-CARRY(y^2)
  BNE .c4    ; ALU0 != 0x00: goto .c4
  ALU0 MEMHI ; \
  ALU1 12    ; |
  ALU0 MOD   ; | Checking if n%12 != 11
  ALU1 11    ; |
  BNE .c4    ; /
  CALL xorSieveArray
.c4:
  MEMP sieve
  ; ================
  ; End of main loop
  ; ================
.loopye:
  ALU0 MEMLO
  ALU1 1
  MEMLO ADD ; y++
  JUMP .loopy
.loopxe:
  ALU0 MEMHI
  ALU1 1
  MEMHI ADD ; x++
  JUMP .loopx
.endp1:
  ; now lets reject squares
  REG0 5 ; r:=5
.loopr:
  ALU0 REG0
  ALU1 REG0
  REG1 MULLO ; reg1 := r^2
  ALU0 MULHI
  ALU1 0x00
  BNE .endp2 ; end if r^2 > 255
  ; accessing mem cell
  STACK REG0
  CALC_SIEVE_POINTER REG0,REG0,.hi,'R'
  ALU1 MEMLO
  JUMP .x1
.hi:
  ALU1 MEMHI
.x1:
  ALU0 REG0
  REG0 STACK
  BRPZ .loopre,AND ; if sieve[r] = 0
  ; loopi
  STACK REG0; reg0 := r
  REG0 REG1 ; i := r^2
.loopi:
  STACK REG0
  CALC_SIEVE_POINTER REG0,REG0,.x2hi,'D'
  ALU0 REG0
  ALU1 0xFF
  ALU0 XOR  ; invert REG0
  ALU1 MEMLO
  MEMLO AND ; set sieve[i] = 0
  JUMP .x2
.x2hi:
  ALU0 REG0
  ALU1 0xFF
  ALU0 XOR  ; invert REG0
  ALU1 MEMHI
  MEMHI AND ; set sieve[i] = 0
.x2:
  REG0 STACK
.loopie:
  ALU0 REG0
  ALU1 REG1
  REG0 ADD
  BRPZ .loopi,ADDC  ; if not overflow
  REG0 STACK ; restoring stack for r

.loopre:
  ALU0 REG0
  ALU1 1
  REG0 ADD   ; r ++
  JUMP .loopr
.endp2:
  RET 


xorSieveArray:
  ; n := memhi
  ; sieve[n//16] ^= 1<<n%16
  STACK REG0
  REG0 MEMHI
  CALL print_u8
  REG0 0x20
  CALL print_char
  ALU0 MEMHI
  ALU1 16
  REG0 DIV 
  CALL print_u8
  REG0 0x20
  CALL print_char

  CALC_SIEVE_POINTER MEMHI,REG0,.hi,'A'
  ;; debug
  STACK REG0
  REG0 'L'
  CALL print_char
  REG0 MEMLO
  CALL print_bin
  REG0 '^'
  CALL print_char
  REG0 STACK
  CALL print_bin
  ;; debug end
  ALU0 MEMLO
  ALU1 REG0
  MEMLO XOR
  JUMP .done
.hi:
  ;; debug
  STACK REG0
  REG0 'H'
  CALL print_char
  REG0 MEMHI
  CALL print_bin
  REG0 '^'
  CALL print_char
  REG0 STACK
  CALL print_bin
  ;; debug end
  ALU0 MEMHI
  ALU1 REG0
  MEMHI XOR
.done:
  ;; debug
  STACK XOR
  REG0 '='
  CALL print_char
  REG0 STACK
  CALL print_bin
  CALL println
  ;; debug end
  REG0 STACK
  RET

bin2digit:
  ; Converts U16 to digit
  ; Adopted from http://www.avr-asm-tutorial.net/avr_en/calc/CONVERT.html#bin2bcd
  ; Digit {reg1 reg0} Place in 10^n generalbuf
  ; Memory pointer must be set to generalbuf
  STACK 0
.a: 
  ALU0 REG1
  ALU1 LWHI
  BLT .c
  BGT .b
  ALU0 REG0
  ALU1 LWLO
  BLT .c
.b:
  ALU0 REG0
  ALU1 LWLO
  REG0 SUB

  ALU0 REG1
  ALU1 LWHI
  REG1 SBC
  ALU0 STACK
  ALU1 1
  STACK ADD
  JUMP .a
.c:
  SWLO REG0
  REG0 STACK
  SWHI REG0
  REG0 LWLO
  RET 

print_u16:
  ; Prints U16 in {reg1 reg0}
  STACK REG0
  STACK REG1
  MEMP generalbuf
  SWHI 10000@1
  SWLO 10000@0 ; 10000 in hex
  CALL bin2digit
  ALU0 48
  ALU1 LWHI
  STACK REG0
  REG0 ADD
  CALL print_char
  REG0 STACK

  SWHI 1000@1 
  SWLO 1000@0
  CALL bin2digit
  ALU0 48
  ALU1 LWHI
  STACK REG0
  REG0 ADD
  CALL print_char
  REG0 STACK

  SWHI 0
  SWLO 100
  CALL bin2digit
  ALU0 48
  ALU1 LWHI
  STACK REG0
  REG0 ADD
  CALL print_char
  REG0 STACK

  ALU0 REG0
  ALU1 100
  REG1 MOD
  ALU1 10
  ALU0 REG0
  STACK MOD
  ALU1 MOD
  ALU0 REG1
  ALU0 SUB
  ALU1 10
  ALU0 DIV
  ALU1 48
  REG0 ADD
  CALL print_char
  ALU0 STACK
  ALU1 48
  REG0 ADD
  CALL print_char
  REG1 STACK
  REG0 STACK
  RET

print_u8:
  ; print u8 in reg0
  ; a = 128%10 = 8
  ; a = 128%100 - a // 10 = 2
  ; a = 128%1000 - a // 100 = 1
  STACK REG1
  REG1 REG0
  ALU1 10
  ALU0 REG0
  ALU0 MOD  ; ALU0 = reg0%10
  STACK ALU0
  REG0 ALU0
  ALU0 REG1
  BRPZ .p3,GE
  ALU1 100 
  ALU0 REG1
  ALU0 MOD
  ALU1 STACK
  STACK ALU1
  ALU0 SUB
  ALU1 10
  ALU1 DIV
  STACK ALU1
  ALU0 REG1
  ALU1 100
  BRPZ .p2,GE
  ALU1 200
  BRPZ .p1,GE
  REG0 '2'
  CALL print_char
  JUMP .p2
  .p1:
  REG0 '1'
  CALL print_char
  .p2:
  ALU0 48
  ALU1 STACK 
  REG0 ADD
  CALl print_char
  .p3:
  ALU0 48
  ALU1 STACK 
  REG0 ADD
  CALl print_char
  REG0 REG1
  REG1 STACK
  RET

print_bin:
; print reg0 as binary
  STACK REG0
  STACK REG1
  REG1 REG0  ; Making copy
  ALU0 0b1000_0000
.start:
  ALU1 REG1
  STACK ALU0
  BRPZ .print0,AND
.print1:
  REG0 '1'
  CALL print_char
  JUMP .end
.print0:
  REG0 '0'
  CALL print_char
.end:
  ALU1 1
  ALU0 STACK
  ALU0 SRL
  BRPZ .done,ALU0
  REG0 REG1
  JUMP .start
.done:
  REG1 STACK
  REG0 STACK
  RET


print_hex:
  ; prints reg0 as hex
  STACK REG0
  STACK REG1
  REG1 REG0
  ALU1 4
  ALU0 REG0
  ALU1 SRL
  ALU0 10
  BRPZ .p0,GT 
  ALU0 48
  JUMP .p1
.p0:
  ALU0 55
.p1:
  REG0 ADD
  CALL print_char
  REG0 REG1
  ALU0 0b0000_1111
  ALU1 REG0 
  ALU1 AND
  ALU0 10
  BRPZ .p2,GT
  ALU0 48
  JUMP .p3
.p2:
  ALU0 55
.p3:
  REG0 ADD
  CALL print_char
  REG1 STACK
  REG0 STACK
  RET

println:
  STACK REG0
  REG0 LF
  CALL print_char
  REG0 CR
  CALL print_char
  REG0 STACK
  RET

print_string:
  ; prints string in memory location {reg0, reg1}
.st:
  MEM0 REG0
  MEM1 REG1
  BRPZ .end,LWHI
  COMA COM_UARTR
  BRP  .loop0
  ALU0 COM_UART_RECV
.loop0:
  ALU1 COMD
  ALU1 AND
  BRZ  NE
  COMA COM_UARTW
  COMD LWHI
  BRPZ .end,LWLO
  COMA COM_UARTR
  BRP .loop1
.loop1:
  ALU1 COMD
  ALU1 AND
  BRZ  NE
  COMA COM_UARTW
  COMD LWLO
  ALU0 REG0
  ALU1 1
  REG0 ADD
  ALU1 ADDC
  ALU0 REG1
  REG1 ADD
  JUMP .st
.end:
  RET

print_char:
  ; prints char in reg0
  COMA COM_UARTR
  BRP  .loop0
  ALU0 COM_UART_RECV
.loop0:
  ALU1 COMD
  ALU1 AND
  BRZ  NE
  COMA COM_UARTW
  COMD REG0
  RET

read_char:
  ; waits for char and stores that in reg0
  COMA COM_UARTR
  ALU0 0b0000_1000
  BRP .loop
.loop:
  ALU1 COMD
  BRZ AND
  COMA COM_UARTIN
  REG0 COMD
  RET
