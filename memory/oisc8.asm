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
  ;ALU1 sieve2@0
  MEM0 ADD
  ;ALU0 sieve2@1
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

%macro COPY 1  ; copy current pointer to memory %1
  STACK MEMLO
  STACK MEMHI
  MEMP %1
  ALU0 STACK  ; can't use 2 memory operations at once.
  MEMHI ALU0
  ALU0 STACK
  MEMLO ALU0
%endmacro


section .data 2x3x8192
DBE 1
intro_text: DB 0x1B,"c",0x1B,"[HBooting ",0x1B,"[1m",0x1B,"[36m","OISC",0x1B,"[0m system..",LFCR,0
generalbuf: DBE 1
generalbuf2: DBE 1
sieve_x:  DBE 1
sieve_x2: DBE 1
sieve_y:  DBE 1
sieve_y2: DBE 1
sieve1: DBE 1
sieve_arr: DBE 16

section .text 2x3x2048
	REG0 intro_text@0
	REG1 intro_text@1
	CALL print_string


	;; test mul_u16
    MEMP generalbuf
    REG0 60001@0   ; num1 lo
	REG1 60001@1  ; num1 hi
	MEMLO 344@0   ; num2 lo
	MEMHI 344@1  ; num2 hi
    MEMLO
	CALL mod_u16
    CALL print_u16
    JUMP forever
	;REG0 MEMLO
    ;CALL print_hex
	;REG0 MEMHI
    ;CALL print_hex
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

mod_u16:
;;  Russian Peasant Multiplication
;;  https://stackoverflow.com/questions/2566010
;;  {reg1,reg0} = {reg1,reg0} % *generalbuf{memhi,memlo}
  %def $a0,REG0
  %def $a1,REG1
  %def $b0,MEMLO
  %def $b1,MEMHI
  %def $x0,MEMLO
  %def $x1,MEMHI
  
  COPY generalbuf2
  ; X = B
  STACK $a0
  STACK $a1
  ALU0 $a1  ; \
  ALU1 1    ; |
  $a1 SRL   ; |
  ALU0 $a0  ; | A >> 1 (divide by 2)
  STACK ROR ; |
  ALU0 SRL  ; |
  ALU1 STACK; |
  $a0 OR    ; /
  ; Do while (X <= A/2)
.while_a_start:
  ALU0 $x1
  ALU1 $a1
  BGT .while_a_end
  BLT .while_a_0
  ALU0 $x0
  ALU1 $a0
  BGE .while_a_end
.while_a_0:
  ALU0 $x0   ; \
  ALU1 1     ; |
  $x0 SLL    ; |
  STACK ROL  ; |  x <<= 1
  ALU0 $x1   ; |
  ALU0 SLL   ; |
  ALU1 STACK ; |
  $x1 OR     ; /
  JUMP .while_a_start
.while_a_end:
  ;JUMP forever
  $a1 STACK 
  $a0 STACK  ; restore a
.while_b_start:
  MEMP generalbuf
  ;PRINTREG
  ; Do while (A >= B)
  ALU0 $a1           
  ALU1 $b1
  BLT .while_b_end
  BGT .while_b_0
  ALU0 $a0
  ALU1 $b0
  BLT .while_b_end
.while_b_0:
  MEMP generalbuf2
  ; Check if A >= X
  ALU0 $a1
  ALU1 $x1
  BLT .next
  BGT .a_ge_x
  ALU0 $a0
  ALU1 $x0
  BLT .next
.a_ge_x:
  ;PRINTREG
  ALU0 $a0
  ALU1 $x0
  $a0 SUB  ; \
  ALU0 $a1 ; | A -= X
  ALU1 $x1 ; |
  $a1 SBC  ; /
.next:
  ; X >>= 1
  ALU0 $x1
  ALU1 1
  $x1 SRL
  STACK ROR
  ALU0 $x0
  ALU0 SRL
  ALU1 STACK
  $x0 OR
  BRPZ .check_null,$x1
  ; Back to while loop
  JUMP .while_b_start
.check_null:
  BRPZ .while_b_end,$x0
  JUMP .while_b_start
.while_b_end:
  RET

calc_sieve:
;; Sieve of Atkin
;  %def $xl,MEMLO
;  %def $xh,MEMHI
;  %def $x2l,REG0
;  %def $x2h,REG1
;  %def $yl,MEMLO
;  %def $yh,MEMHI
;  %def $y2l,REG0
;  %def $y2h,REG1
;  
;  ; loop x setup
;  MEMP sieve_x
;  $xl 1 ; 
;  $xh 0 ; x=1
;.loopx:
;  COPY sieve_x2  ; temp copy x to x2
;  REG0 $xl
;  REG1 $xh
;  CALL mul_u16
;  ALU1 0
;  ALU0 REG1
;  BRP .endp1
;  BRZ  EQ	; if x^2 >= 2^16
;  ALU0 REG0
;  BRZ  EQ	; if x^2 >= 2^16
;
;  ; loop y setup
;  MEMP sieve_y
;  $yl 1 ;
;  $yh 0 ; y=1
;.loopy:
;  COPY sieve_y2 ; temp copy y to y2
;  REG0 $yl
;  REG1 $yh
;  CALL mul_u16
;  ALU1 0
;  ALU0 REG1
;  BRP .loopxe
;  BRZ  EQ	; if y^2 >= 2^16
;  ALU0 REG0
;  BRZ  EQ	; if y^2 >= 2^16
;
;  ; ==================
;  ; Start of Main loop
;  ; ==================
;
;  ;MEMP sieve1
;  
;  %def $nh,MEMHI
;  %def $nl,MEMLO
;  %def $tmp,MEMLO
;.c1:
;  MEMP sieve_x2
;  COPY sieve1  ; copy x^2 to n
;  REG0 4
;  REG1 0
;  CALL mul_u16  ; x^2 * 0x0004
;  ALU0 REG1 ; \
;  ALU1 0	; |
;  BRP .c2	; | checking if 4*x^2 overflow
;  BRZ EQ	; |
;  ALU0 REG0	; |
;  BRZ EQ	; /
;  ; n += y^2
;  REG0 $nl
;  REG1 $nh
;  MEMP sieve_y2
;  ALU0 REG0  ; $nl
;  ALU1 MEMLO ; $y2l
;  REG0 ADD
;  ALU0 REG1
;  ALU1 MEMHI
;  REG1 ADC
;  ALU0 ADDC ; \
;  ALU1 0    ; | chcek for 4*x^2+y^2 oveflow
;  BNE .c2   ; /
;  
;
;  %def $n,REG0; to be deleted
;  ALU0 REG0
;  ALU1 4
;  STACK MULLO
;  ALU0 MULHI ; \
;  ALU1 0     ; | Checking if 4x^2 > 255
;  ALU1 EQ    ; / 
;  ALU0 STACK
;  BRPZ .c2,ALU1 ; if mulhi != 0: goto .c2
;  ALU1 REG1  
;  $n ADD  ; n = mullo( low{4*x^2} ) + y^2
;  ALU0 ADDC  ; \
;  ALU1 0     ; | Checking if 4x^2+y^2 > 255
;  BNE .c2    ; /
;  ALU0 $n    ; MEMHI := n
;  ALU1 12
;  $tmp MOD
;  ALU0 $tmp
;  ALU1 1
;  BEQ .c1r    ; n%12 == 1
;  ALU0 $tmp
;  ALU1 5
;  BEQ .c1r    ; n%12 == 5
;  JUMP .c2
;.c1r:
;  CALL xorSieveArray
;  MEMP sieve1
;.c2:
;  ALU0 REG0
;  ALU1 3
;  STACK MULLO
;  ALU0 MULHI ; \
;  ALU1 0     ; | Checking if 3x^2 > 255
;  ALU1 EQ    ; /
;  ALU0 STACK
;  BRPZ .c3,ALU1
;  ALU1 REG1
;  STACK ADD
;  ALU0 ADDC  ; \
;  ALU1 0     ; | Checking if 3x^2+y^2 > 255 
;  ALU1 EQ	 ; /
;  ALU0 STACK 
;  BRPZ .c3,ALU1 
;  $n   ALU0 ; MEMHI := n
;  ALU1 12
;  ALU0 MOD
;  ALU1 7
;  BNE .c3
;  CALL xorSieveArray
;.c3:
;  ;MEMP sieve
;  ;ALU1 $y ; y
;  ;ALU0 $x ; x
;  BLE .loopye ; Function needs x>y
;
;  MEMP sieve1
;  ALU0 REG0
;  ALU1 3
;  $tmp MULHI ; MEMLO := HIGH(3x^2)
;  ALU0 MULLO
;  ALU1 REG1
;  $n SUB   ; MEMHI := LOW(3x^2)-y^2
;  ALU0 $tmp
;  ALU1 0x00
;  ALU0 SBC   ; ALU0 := HIGH(3x^2)-CARRY(y^2)
;  BNE .c4    ; ALU0 != 0x00: goto .c4
;  ALU0 $n    ; \
;  ALU1 12    ; |
;  ALU0 MOD   ; | Checking if n%12 != 11
;  ALU1 11    ; |
;  BNE .c4    ; /
;  CALL xorSieveArray
;.c4:
;  ;MEMP sieve
;  ; ================
;  ; End of main loop
;  ; ================
;.loopye:
;  MEMP sieve_y
;  ALU0 $yl  ; \
;  ALU1 1    ; |
;  $yl ADD   ; |  y++
;  ALU1 ADDC ; |
;  ALU0 $yh  ; |
;  $yh ADD   ; /
;  JUMP .loopy
;.loopxe:
;  MEMP sieve_x
;  ALU0 $xl  ; \
;  ALU1 1    ; |
;  $xl ADD   ; |  x++
;  ALU1 ADDC ; |
;  ALU0 $xh  ; |
;  $xh ADD   ; /
;  JUMP .loopx
;  ; =============
;  ; End of part 1
;  ; =============
;.endp1:
;  ; now lets reject squares
;  %def $r,REG0
;  %def $r2,REG1
;  $r 5 ; r:=5
;.loopr:
;  ALU0 $r
;  ALU1 $r
;  $r2  MULLO ; reg1 := r^2
;  ALU0 MULHI
;  ALU1 0x00
;  BNE .endp2 ; end if r^2 > 255
;  ; accessing mem cell
;  STACK REG0
;  CALC_SIEVE_POINTER REG0,REG0,.hi,'R'
;  ALU1 MEMLO
;  JUMP .x1
;.hi:
;  ALU1 MEMHI
;.x1:
;  ALU0 REG0
;  REG0 STACK
;  BRPZ .loopre,AND ; if sieve[r] = 0
;  ; loopi
;  STACK $r; reg0 := r
;  REG0 $r2 ; i := r^2
;.loopi:
;  STACK REG0
;  CALC_SIEVE_POINTER REG0,REG0,.x2hi,'D'
;  ALU0 REG0
;  ALU1 0xFF
;  ALU0 XOR  ; invert REG0
;  ALU1 MEMLO
;  MEMLO AND ; set sieve[i] = 0
;  JUMP .x2
;.x2hi:
;  ALU0 REG0
;  ALU1 0xFF
;  ALU0 XOR  ; invert REG0
;  ALU1 MEMHI
;  MEMHI AND ; set sieve[i] = 0
;.x2:
;  REG0 STACK
;.loopie:
;  ALU0 REG0
;  ALU1 REG1
;  REG0 ADD
;  BRPZ .loopi,ADDC  ; if not overflow
;  $r STACK ; restoring stack for r
;
;.loopre:
;  ALU0 $r
;  ALU1 1
;  $r   ADD   ; r ++
;  JUMP .loopr
;.endp2:
  RET 


xorSieveArray:
  ; n := memhi
  ; sieve[n;16] ^= 1<<n%16
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

mul_u16:
  ; m1H, m1L, m2H, m2L, MEMHI, MEMLO, REG1, REG0
  ; answer = {MEMHI, MEMLO, REG1, REG0}
  %def $m1H,REG1 
  %def $m2H,MEMHI  
  %def $m1L,REG0
  %def $m2L,MEMLO 

  %def $res3,MEMLO ;REG0
  %def $res2,MEMHI ;REG1
  %def $res1,REG0  ;MEMLO
  %def $res0,REG1  ;MEMHI
  ;MEMP generalbuf
  ;REG0 -> m1L
  ;REG1 -> m2L
  
  ALU0 $m2L
  ALU1 $m2H
  STACK ALU1 ;m2H
  STACK $m1L
  STACK ALU0 ;m2L
  STACK $m1H ;m1H
  STACK ALU0 ;m2L
  STACK $m1L
  ALU0 $m1H

  $res2 MULLO
  $res3 MULHI
  ALU0 STACK ;m1L
  ALU1 STACK ;m2L
  $res0 MULLO
  $res1 MULHI

  ALU0 STACK ;m1H
  ALU1 STACK ;m2L
  STACK MULHI
  ALU0 MULLO
  ALU1 $res1
  $res1 ADD
  ALU0 STACK
  ALU1 $res2
  $res2 ADC
  ALU1 ADDC
  ALU0 $res3
  $res3 ADD

  ALU0 STACK ;m1L
  ALU1 STACK ;m2H
  STACK MULHI
  ALU0 MULLO
  ALU1 $res1
  $res1 ADD
  ALU0 $res2
  ALU1 STACK
  $res2 ADC
  ALU0 ADDC
  ALU1 $res3
  $res3 ADD

  RET

bin2digit:
  ; Converts U16 to digit
  ; Adopted from http:;www.avr-asm-tutorial.net/avr_en/calc/CONVERT.html#bin2bcd
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
