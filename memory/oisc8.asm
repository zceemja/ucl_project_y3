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
    STACK REG0
	REG0 LWHI
	CALL print_hex
	REG0 LWLO
	CALL print_hex
	REG0 0x20
	CALL print_char
	REG0 STACK
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
  REG0 STACK
%endmacro

%macro PRINTREGLN 0
  STACK REG0
  STACK REG0
  REG0 REG1
  CALL print_hex
  REG0 STACK
  CALL print_hex
  ;REG0 0x20
  ;CALL print_char
  ;REG0 LWHI
  ;CALL print_hex
  ;REG0 LWLO
  ;CALL print_hex
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


section .data depth=4096,width=2
DBE 1
intro_text: DB "\x1Bc\x1B[2J\x1B[HBooting \x1B[1m\x1B[36mOISC\x1B[0m system\r\n",0
generalbuf: DBE 1
generalbuf2: DBE 1
generalbuf3: DBE 1
sieve_x:  DBE 1
sieve_x2: DBE 1
sieve_y:  DBE 1
sieve_y2: DBE 1
sieve1: DBE 1
sieve_arr: DBE 16
memend: DBE 1

section .text depth=3072,width=2,bin_width=13,parity=2,fill_bits=27648
	REG0 intro_text@0
	REG1 intro_text@1
	CALL print_string

	;; test mul_u16
    ;MEMP generalbuf
    ;MEMLO 60059@0   ; num1 lo
	;MEMHI 60059@1   ; num1 hi
    ;MEMP generalbuf2
    ;MEMLO 60   ; num1 lo
	;MEMHI 0   ; num1 hi
	;CALL div_u16
	;STACK REG0
	;STACK REG1
    ;MEMP generalbuf3
	;REG0 MEMLO
	;REG1 MEMHI
    ;CALL print_u16
	;REG0 '.'
	;CALL print_char
	;REG1 STACK
	;REG0 STACK
    ;CALL print_u16
    ;JUMP forever
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
    ;MEMP memend
	;MEMLO 0x04
	REG0 '@'
	CALL print_char
    CALL clean_ram 
	REG0 '@'
	CALL print_char
    CALL calc_sieve
	REG0 '@'
	CALL print_char
	;JUMP forever

	CALL println

	REG0 0
	REG1 0
.print_sieve:
    ; Set memory pointer
    ALU0 memend@0
	ALU1 REG0
    MEM0 ADD
    ALU0 memend@1
	ALU1 REG1
    MEM1 ADC

    ; check for overflow
    ALU0 MEM1
    ALU1 0x0e
    BGT .done
	
	STACK REG0
	STACK REG1
	BR0 MEMHI
	STACK BR0
	BR0 MEMLO
	STACK BR0

    ; now is loop for every bit in memory
    MEMP generalbuf3
	MEMLO 16
	MEMHI 0
	CALL mul_u16
	
	BR0 STACK
	MEMLO BR0
	
    MEMHI 1
.print_loop0:
    ALU0 MEMHI
	ALU1 MEMLO
	BRPZ .z0,AND
	;; This number is prime
	
	CALL print_u16
	CALL println
    MEMP generalbuf3
	;PRINTREG
    ;JUMP .d0
.z0:
	;CALL print_u16
	;PRINTREG
	;; This number is not prime
.d0:
	ALU1 1
	ALU0 MEMHI
    MEMHI SLL
    ALU0 REG0
	REG0 ADD
	ALU0 REG1
	ALU1 0
	REG1 ADC
	BRPZ .print_loop0e,MEMHI
	JUMP .print_loop0
.print_loop0e:
    BR0 STACK
    MEMLO BR0
    MEMHI 1
	;PRINTREG

.print_loop1:
    ALU0 MEMHI
	ALU1 MEMLO
	BRPZ .z1,AND
	;; This number is prime
	CALL print_u16
	CALL println
    MEMP generalbuf3
    JUMP .d1
.z1:
	;PRINTREG
	;CALL print_u16
	;; This number is not prime
.d1:
	ALU1 1
	ALU0 MEMHI
    MEMHI SLL
	BRPZ .print_loop1e,MEMHI
    ALU0 REG0
	REG0 ADD
	ALU0 REG1
	ALU1 0
	REG1 ADC
	JUMP .print_loop1
.print_loop1e:

	REG1 STACK
	REG0 STACK
    ALU0 REG0 
	ALU1 1
	REG0 ADD
	ALU0 REG1
	ALU1 0
	REG1 ADC
	JUMP .print_sieve
.done:
	REG0 '@'
	CALL print_char
	JUMP forever


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

clean_ram:
	MEMP memend
.loop:
	MEMLO 0x00
	MEMHI 0x00
    ALU0 1
	ALU1 MEM0
    MEM0 ADD
    ALU0 0
	ALU1 MEM1
    MEM1 ADC

    ALU0 MEM1
    ALU1 0x0e
    BGT .done
	JUMP .loop
.done:
    RET

log2n_u8:
;; Only for 2^n numbers
  REG1 0
  ALU1 1
.loop:
  BRPZ .done,REG0
  ALU0 REG0
  REG0 SRL
  ALU0 REG1
  REG1 ADD
  JUMP .loop
.done:
  RET
  

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

%macro SLL16 3
  ALU0 %2
  ALU1 %1  ; multiply by 2
  %2 SLL
  STACK ROL

  ALU0 %3  ; multiply by 2 with carry
  ALU0 SLL
  ALU1 STACK
  %3 OR
%endmacro

div_u16:
;; Divide 16bit by 16bit (can be expanded)
;; source: https://en.wikipedia.org/wiki/Division_algorithm#Integer_division_(unsigned)_with_remainder
;; generalbuf3 = generalbuf / generalbuf2; reg1,reg0 => reminder


  %def $Nl,MEMLO  ; \
  %def $Nh,MEMHI  ; / generalbuf
  %def $Dl,MEMLO  ; \
  %def $Dh,MEMHI  ; / generalbuf2
  %def $Ql,MEMLO  ; \
  %def $Qh,MEMHI  ; / generalbuf3
  %def $Rl,REG0
  %def $Rh,REG1
  
  $Rl 0
  $Rh 0
  MEMP generalbuf3
  MEMLO 0
  MEMHI 0

  STACK 0b1000_0000  ; put 0
.for_start0:
  SLL16 1,$Rl,$Rh
  ;; Finding N(i)
  ALU0 STACK
  STACK ALU0
  MEMP generalbuf
  ALU1 $Nh
  BRPZ .z0,AND  ; Nl & i == 0
  ALU0 0b0000_0001
  ALU1 $Rl
  $Rl OR   ; R(0) = N(i) = 1
  JUMP .check0
.z0:
  ALU0 0b1111_1110
  ALU1 $Rl
  $Rl AND  ; R(0) = N(i) = 0
.check0:  ; if R >= D
  MEMP generalbuf2
  ALU0 $Rh
  ALU1 $Dh
  BLT .for_end0
  BGT .sub0
  ALU0 $Rl
  ALU1 $Dl
  BLT .for_end0
.sub0:
  ALU0 $Rl
  ALU1 $Dl
  $Rl SUB
  ALU0 $Rh
  ALU1 $Dh
  $Rh SBC
  MEMP generalbuf3
  ALU0 $Qh    ; Q(i) = 1
  ALU1 STACK
  STACK ALU1
  $Qh OR
.for_end0:
  ALU0 STACK
  ALU1 1
  ALU0 SRL
  BRPZ .done0,ALU0
  STACK ALU0
  JUMP .for_start0
.done0:
  STACK 0b1000_0000  ; put 0
.for_start1:
  SLL16 1,$Rl,$Rh
  ;; Finding N(i)
  ALU0 STACK
  STACK ALU0
  MEMP generalbuf
  ALU1 $Nl
  BRPZ .z1,AND
  ALU0 0b0000_0001
  ALU1 $Rl
  $Rl OR   ; R(0) = N(i) = 1
  JUMP .check1
.z1:
  ALU0 0b1111_1110
  ALU1 $Rl
  $Rl AND  ; R(0) = N(i) = 0
.check1:  ; if R >= D
  MEMP generalbuf2
  ALU0 $Rh
  ALU1 $Dh
  BLT .for_end1
  BGT .sub1
  ALU0 $Rl
  ALU1 $Dl
  BLT .for_end1
.sub1:
  ALU0 $Rl
  ALU1 $Dl
  $Rl SUB
  ALU0 $Rh
  ALU1 $Dh
  $Rh SBC
  MEMP generalbuf3
  ALU0 $Ql    ; Q(i) = 1
  ALU1 STACK
  STACK ALU1
  $Ql OR
.for_end1:
  ALU0 STACK
  ALU1 1
  ALU0 SRL
  BRPZ .done1,ALU0
  STACK ALU0
  JUMP .for_start1
.done1:
  RET
  

;div_u16:
;; Divide 16bit number by 8bit
;; Insparation taken from:
;; http://www.avr-asm-tutorial.net/avr_en/calc/DIV8E.html
;
;  %def $rd1l,MEMLO
;  %def $rd1h,MEMHI
;  %def $rd2,REG0
;  %def $rd1u,REG1
;  %def $rel,MEMLO
;  %def $reh,MEMHI
;  
;  $rd1u 0
;  MEMP generalbuf2
;  $rel 1
;  $reh 0
;.div8a:
;  MEMP generalbuf
;  ALU0 1
;  ALU1 $rd1l  ; multiply by 2
;  $rd1l SLL
;  STACK ROL
;
;  ALU1 $rd1h  ; multiply by 2 with carry
;  ALU1 SLL
;  ALU0 STACK
;  $rd1h OR
;  STACK ROL
;
;  ALU0 1
;  ALU1 $rd1u 
;  ALU1 SLL
;  ALU0 STACK
;  $rd1u OR
;  ALU0 0
;  ALU1 ROL
;  BNE .div8b
;  ALU0 $rd1u
;  ALU1 $rd2
;  $rd1u SUB
;  ALU1 SUBC
;  ALU0 0
;  BNE .div8c
;.div8b:
;  ALU0 $rd1u
;  ALU1 $rd2
;  $rd1u SUB
;  STACK 1
;  JUMP .div8d
;.div8c:
;  STACK 0
;.div8d:
;  MEMP generalbuf2
;  ALU0 1
;  ALU1 $rel
;  ALU0 SLL
;  ALU1 STACK
;  $rel OR
;  STACK ROL
;
;  ALU0 1
;  ALU1 $reh
;  ALU0 SLL
;  ALU1 STACK
;  $reh OR
;  BRP .div8a
;  BRZ ROL
;.done:
;  RET


calc_sieve:
; Sieve of Atkin
  %def $xl,MEMLO
  %def $xh,MEMHI
  %def $x2l,REG0
  %def $x2h,REG1
  %def $yl,MEMLO
  %def $yh,MEMHI
  %def $y2l,REG0
  %def $y2h,REG1
  
  ; loop x setup
  MEMP sieve_x
  $xl 1 ; 
  $xh 0 ; x=1
.loopx:
  COPY sieve_x2  ; temp copy x to x2
  REG0 $xl
  REG1 $xh
  CALL mul_u16
  
  ALU1 0
  ALU0 MEMHI
  BRP .endp1
  BRZ  EQ	; if x^2 >= 2^16
  ALU0 MEMLO
  BRZ  EQ	; if x^2 >= 2^16
  MEMHI REG1
  MEMLO REG0

  ; loop y setup
  MEMP sieve_y
  $yl 1 ;
  $yh 0 ; y=1
.loopy:
  COPY sieve_y2 ; temp copy y to y2
  REG0 $yl
  REG1 $yh
  CALL mul_u16
  ALU1 0
  ALU0 MEMHI
  BRP .loopxe
  BRZ  EQ	; if y^2 >= 2^16
  ALU0 MEMLO
  BRZ  EQ	; if y^2 >= 2^16
  MEMHI REG1
  MEMLO REG0

  ; ==================
  ; Start of Main loop
  ; ==================
  ;MEMP sieve1
  
  %def $nh,REG1
  %def $nl,REG0
  
   ;MEMP sieve_y2
   ;PRINTMEM
   ;CALL println
.c1:
  MEMP sieve_x2
  COPY sieve1  ; copy x^2 to n
  REG0 4
  REG1 0
  CALL mul_u16  ; x^2 * 0x0004
  ALU0 MEMHI; \
  ALU1 0	; |
  BRP .c2	; | checking if 4*x^2 overflow
  BRZ EQ	; |
  ALU0 MEMLO; |
  BRZ EQ	; /
  ; n += y^2
  ;$nl MEMLO 
  ;$nh MEMHI
  MEMP sieve_y2
  ALU0 $nl  ; $nl
  ALU1 MEMLO ; $y2l
  $nl ADD
  ALU0 $nh
  ALU1 MEMHI ; $y2h
  $nh ADC
  ALU0 ADDC ; \
  ALU1 0    ; | check for 4*x^2+y^2 oveflow
  BNE .c2   ; /
  ;CALL print_u16
  ;STACK REG0
  ;REG0 0x20
  ;CALL print_char
  ;REG0 STACK
  MEMP sieve1 ; \
  MEMLO $nl	  ; | save n to sieve1
  MEMHI $nh   ; /
  ; checkinf for n%12 == 1 || n%12 == 5
  MEMP generalbuf
  MEMHI 0
  MEMLO 12  ; storing 12
  CALL mod_u16 ; n = n%12
  ALU0 0
  ALU1 $nh ; if n%12 high byte != 0
  BNE .c2
  ALU0 1   ; if n%12 == 1
  ALU1 $nl
  BEQ .c1x
  ALU0 5   ; if n%12 == 5
  BNE .c2
.c1x:
  ; call sieve
  CALL xorSieveArray
.c2:
  MEMP sieve_x2
  COPY sieve1  ; copy x^2 to n

  REG0 3
  REG1 0
  CALL mul_u16  ; x^2 * 0x0003
  ALU0 MEMHI; \
  ALU1 0	; |
  BRP .c3	; | checking if 3*x^2 overflow
  BRZ EQ	; |
  ALU0 MEMLO; |
  BRZ EQ	; /
  ; n += y^2
  MEMP sieve_y2
  ALU0 $nl  ; $nl
  ALU1 MEMLO ; $y2l
  $nl ADD
  ALU0 $nh
  ALU1 MEMHI
  $nh ADC
  ALU0 ADDC ; \
  ALU1 0    ; | chcek for 3*x^2+y^2 overflow
  BNE .c3   ; /
  
  MEMP sieve1
  MEMHI $nh
  MEMLO $nl
  ; checkinf for n%12 == 7
  MEMP generalbuf
  MEMHI 0
  MEMLO 12  ; storing 12
  CALL mod_u16 ; n = n%12
  ALU0 0
  ALU1 REG1 ; if n%12 high byte != 0
  BRP .c3
  BRZ EQ
  ALU0 7   ; if n%12 == 7
  ALU1 REG0
  BRZ EQ
  CALL xorSieveArray
.c3:
  ; checking if x > y
  MEMP sieve_y
  REG0 MEMLO
  REG1 MEMHI
  MEMP sieve_x
  ALU0 REG1   ; xh
  ALU1 MEMHI  ; yh
  BGT .c3c
  BLT .loopye  ; jump if x < y
  ALU0 REG0   ; xl
  ALU1 MEMLO  ; yl
  BGE .loopye ; jump to .loopy if x < y
.c3c:
  MEMP sieve_x2
  COPY sieve1  ; copy x^2 to n

  REG0 3
  REG1 0
  CALL mul_u16  ; x^2 * 0x0003
  ; now n is 32bit in {MEMHI, MEMLO, REG1, REG0}
  ; where do we store y^2? Should be in stack but for test lets use BRP
  BR0 MEMLO
  BR1 MEMHI
  MEMP sieve_y2
  COPY sieve1

  ALU0 REG0
  ALU1 MEMLO
  REG0 SUB
  ALU0 REG1
  ALU1 MEMHI
  REG1 SBC
  ALU0 BR0
  ALU1 0
  MEMLO SBC
  ALU0 BR1
  ALU1 0
  MEMHI SBC
  ; now 32bit in {MEMHI, MEMLO, REG1, REG0} 
  ; has been subtraced with y^2
  
  ALU0 MEMHI ; \
  ALU1 0	 ; |
  BRP .loopye; | checking if 3*x^2-y^2 overflow
  BRZ EQ	 ; |
  ALU0 MEMLO ; |
  BRZ EQ	 ; /
  
  MEMLO $nl
  MEMHI $nh
  ; checkinf for n%12 == 11
  MEMP generalbuf
  MEMHI 0
  MEMLO 12  ; storing 12
  CALL mod_u16 ; n = n%12
  ALU0 0
  ALU1 $nh ; if n%12 high byte != 0
  BRP .loopye
  BRZ NE
  ALU0 7   ; if n%12 == 7
  ALU1 $nl
  BRZ NE
  ; n should be in *sieve1
  CALL xorSieveArray

  ; ================
  ; End of main loop
  ; ================
.loopye:
  MEMP sieve_y
  ALU0 $yl  ; \
  ALU1 1    ; |
  $yl ADD   ; |  y++
  ALU1 ADDC ; |
  ALU0 $yh  ; |
  $yh ADD   ; /
  JUMP .loopy
.loopxe:
  MEMP sieve_x
  ALU0 $xl  ; \
  ALU1 1    ; |
  $xl ADD   ; |  x++
  ALU1 ADDC ; |
  ALU0 $xh  ; |
  $xh ADD   ; /
  JUMP .loopx
  ; =============
  ; End of part 1
  ; =============
.endp1:
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
  ; short n = *sieve1
  ; sieve[n//16] ^= 1<<n%16
  ;jump forever
  MEMP sieve1
  ;PRINTMEM
  ;CALL println
  ;ALU0 MEMHI
  ;ALU1 1000@1
  ;BGT forever
  COPY generalbuf
  MEMP generalbuf2
  MEMLO 16
  MEMHI 0
  CALL div_u16
  MEMP generalbuf3
  ALU0 MEMLO
  ALU1 memend@0
  MEM0 ADD
  ALU0 MEMHI
  ALU1 memend@1
  MEM1 ADC
  MEM2 0 
  ; memory pointer ready
  ; checking if there's enough ram to not corrupt stack
  ; mem1 should be less or equal to 0x0e, making ~ 3839 memory spaces or
  ; about 60800 bits
  ALU0 MEM1
  ALU1 0x0e
  BGT .done
.mpr:
  ;; DEBUG
  ;STACK REG0
  ;REG0 MEM2
  ;CALL print_hex
  ;REG0 MEM1
  ;CALL print_hex
  ;REG0 MEM0
  ;CALL print_hex
  ;REG0 ":"
  ;CALL print_char
  ;REG0 STACK 
  ;; DEBUG END

  ALU1 REG0 ; dividion reminder lower byte
  ALU0 8
  BLT .hi
  ; memory lower
  ALU0 1
  ALU1 REG0  ; reminder
  ALU0 SLL

  ;; debug
  ;STACK REG0
  ;STACK ALU0
  ;REG0 'L'
  ;CALL print_char
  ;REG0 MEMLO
  ;CALL print_bin
  ;REG0 '^'
  ;CALL print_char
  ;REG0 STACK
  ;CALL print_bin
  ;ALU0 REG0
  ;REG0 STACK
  ;; debug end

  ALU1 MEMLO
  MEMLO XOR
  JUMP .done
.hi:
  ALU0 1
  ALU1 REG0  ; reminder
  ALU0 SLL
  ;ALU0 ROL

  ;; debug
  ;STACK REG0
  ;STACK ALU0
  ;REG0 'H'
  ;CALL print_char
  ;REG0 MEMHI
  ;CALL print_bin
  ;REG0 '^'
  ;CALL print_char
  ;REG0 STACK
  ;CALL print_bin
  ;ALU0 REG0
  ;REG0 STACK
  ;; debug end

  ALU1 MEMHI
  MEMHI XOR
  
  ;STACK REG0
  ;REG0 MEMHI
  ;CALL print_u8
  ;REG0 0x20
  ;CALL print_char

  ;ALU0 MEMHI
  ;ALU1 16
  ;REG0 DIV 
  ;CALL print_u8
  ;REG0 0x20
  ;CALL print_char

  ;CALC_SIEVE_POINTER MEMHI,REG0,.hi,'A'
  ;; debug
  ;STACK REG0
  ;REG0 'L'
  ;CALL print_char
  ;REG0 MEMLO
  ;CALL print_bin
  ;REG0 '^'
  ;CALL print_char
  ;REG0 STACK
  ;CALL print_bin
  ;; debug end
;  ALU0 
;  ALU1 REG0
;  MEMLO XOR
;  JUMP .done
;.hi:
;  ;; debug
;  STACK REG0
;  REG0 'H'
;  CALL print_char
;  REG0 MEMHI
;  CALL print_bin
;  REG0 '^'
;  CALL print_char
;  REG0 STACK
;  CALL print_bin
;  ;; debug end
;  ALU0 MEMHI
;  ALU1 REG0
;  MEMHI XOR
.done:

  ;; debug
  ;STACK XOR
  ;REG0 '='
  ;CALL print_char
  ;REG0 STACK
  ;CALL print_bin
  ;CALL println
  ;; debug end

  RET

mul_u16:
  ; m1H, m1L, m2H, m2L, MEMHI, MEMLO, REG1, REG0
  ; answer = {MEMHI, MEMLO, REG1, REG0}
  %def $m1H,REG1 
  %def $m2H,MEMHI  
  %def $m1L,REG0
  %def $m2L,MEMLO 

  %def $res3,MEMHI
  %def $res2,MEMLO 
  %def $res1,REG1  
  %def $res0,REG0  
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
