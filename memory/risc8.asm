%define COM_UARTF 	0x03
%define COM_UARTW 	0x05
%define COM_UARTR 	0x04
%define COM_LED 	0x06
%define COM_DIP 	0x08
%define COM_UARTIN 	0x09
%define NULL 		0x000000
%define LF          0x0a
%define CR          0x0d
%define LFCR        0x0a0d
%define COM_UART_TRANS 	0b0000_0001
%define COM_UART_RECV 	0b0000_0010
%define COM_UART_ECHO 	0b0000_0100
%define COM_UART_RR 	0b0000_1000 ; Read Ready

%macro PRINTREGS 0
	PUSH r0
	CALL print_hex
	MOVE r0,r1
	CALL print_hex
	MOVE r0,r2
	CALL print_hex
	MOVE r0,r3
	CALL print_hex
	CALL println 
	POP r0
%endmacro

%macro PRINTREG 1
	PUSH r0
	MOVE r0,%1
	CALL print_hex
	POP r0
%endmacro

%macro SLL16 4
	; 1			2			3			4
	; shift by, low byte, 	high byte,	temp reg
	SLL %2,%1
	PUSH %4
	GETAH %4
	SLL %3,%1
	OR %3,%4
	POP %4
%endmacro

%macro LOAD 3
	LWLO %3,%1
	LWHI %2,%1
%endmacro

%macro SAVE 3
	SWHI %2
	SWLO %3,%1
%endmacro

%macro PRINTMEM 1
	PUSH r0
	LWHI r0,%1
	CALL print_hex
	LWLO r0,%1
	CALL print_hex
	POP r0
%endmacro

%macro CH 1
	PUSH r0
	CPY0 %1
	CALL print_char
	POP r0
%endmacro

%macro BGE16 5
; 1				 2 3	   4 5
; Brach to if, A{H,L} >= B{H,L}
	CI2 %4
	BGT %2,0,%1
	CI2 %2
	BGT %4,0,%%continue
	CI2 %5	
	BGE %3,0,%1
%%continue:
%endmacro

section .data depth=4096,width=2
intro_text: DB "\x1Bc\x1B[2J\x1B[HBooting \x1B[1m\x1B[33mRISC\x1B[0m system\r\n",0
eq1_text: DB LFCR,"1) 0x1194 * 0x2710 = 0x",0
eq2_text: DB LFCR,"2) 3*2=",0
eq3_text: DB LFCR,"3) 3*2=",0
initial_vt100: DB 0x1B,'c',0x1B,"[2J",0x1B,"[40;32m",0
error_text: DB LFCR,"Invalid operation: ",0
error0: DB "Buffer is full",0
error1: DB "Number value overflow",0
mul16buf: DBE 8
generalbuf: DBE 1
generalbuf2: DBE 1
generalbuf3: DBE 1
termHiFlag: 	DB  0x0000
termBuff: 	DB  10,0
			DBE 10
mallocPointer: DB 0
MEMEND: DB 0
section .text depth=4096,width=1,length=2
setup:
	CPY1 intro_text@0	
	CPY2 intro_text@1	
	CALL print_msg
	;JUMP forever


    CPY0 0x00
	CPY1 0x02
	SAVE generalbuf,r0,r1
	PRINTMEM generalbuf
	CALL println
	CALL println
    CPY0 50000@1
	CPY1 50000@0
	CALL div_u16
	
	CALL println
	PRINTMEM generalbuf2
	CH 0x20
	PRINTREGS
	CALL println
	JUMP forever
	;CALL printU16
	;PRINTREG
	;CALL printU16
	;CALL println
	JUMP forever

	SRL r0,1
	GETAH r1
	CALL println
	CALL print_bin
	CALL println
	MOVE r0,r1
	CALL print_bin
	CALL println
forever:
	CALL read_char
	CALL print_char
	JUMP forever
	
	; Run init
	;INTRE interrupt
	;CALL read_char
	;CALL print_char
;.echo
;	JUMP .echo
;	CALL read_char
;	CALL print_char

	;CPY0 65432@1
	;CPY1 65432@0
	;CALL printU16
	;CALL read_char
	;CPY1 COM_UART_ECHO
	;COM r1,COM_UARTF
	;CPY1 eq1_text@0	
	;CPY2 eq1_text@1	
	;CALL print_msg
    
    CPY0 0x0A ; 
	CPY1 0x0B ; a = 0
    CPY2 0x03 ;
	CPY3 0x00 ; b = 0

loopyloop:
    PUSH r0
    PUSH r1

    PUSH r2
    PUSH r3


	CALL mulU16
	;CALL print_hex
	;MOVE r0,r1
	;CALL print_hex
	;MOVE r0,r2
	;CALL print_hex
	;MOVE r0,r3
	;CALL print_hex
	;CALL println

	POP r3
	POP r2
	POP r1
	POP r0

    INC r3
	ADDC r2
	BZ r3,.ztest0
	JUMP loopyloop
.ztest0:
	BZ r2,.ztest1
	JUMP loopyloop
.ztest1:
    INC r1
	ADDC r0
    ;PUSH r0
	;CALL print_hex
	;MOVE r0,r1
	;CALL print_hex
    ;CPY0 '*'
	;CALL print_char
	;MOVE r0,r2
	;CALL print_hex
	;MOVE r0,r3
	;CALL print_hex
	;POP r0
	JUMP loopyloop


	CALL sieveOfAtkin
	CALL println

div_u16:
	%def $Rh,r2
	%def $Rl,r3
	
	CPY2 0  ; set R = 0
	CPY3 0
	
	; Keep r1 <= Nl
	PUSH r1  ; keep Nl for second loop
	CALL print_hex
	PRINTREG r1
	CALL println

	MOVE r1,r0
	; for i=0;i<15;i++
	CPY0 0b1000_0000
.for_start0:
	CALL println
	;CALL print_bin
	;CALL println
	SLL16 1,$Rl,$Rh,r0
	CH 'N'
	PRINTREG r1
	;; Finding N(i)
	PUSH r1  ;; copy Nh
	AND r1,r0  ; AND i,N
	
	BEQ r1,0,.z0  ; if N&i == 0, do nothing
	PUSH r0
	CPY0 0x01
	OR $Rl,r0 ; R[0] = 1
	POP r0
.z0:
	CH 0x20
	CH 'R'
	PRINTREG $Rh
	PRINTREG $Rl
	; check if R >= D
	PUSH r0
	%def $Dl,r1
	%def $Dh,r0
	LOAD generalbuf,$Dh,$Dl
	
	CH 0x20
	CH 'D'
	CALL print_hex
	PRINTREG r1
	CH 0x20
	BGE16 .sub0,$Rh,$Rl,$Dh,$Dl
	POP r0
	JUMP .fin0
.sub0:
	; R -= D
	SUB $Rl,$Dl
	SUB $Rh,$Dh
	SUBC $Rh
	CH 'R'
	PRINTREG $Rh
	PRINTREG $Rl
	CH 0x20
	; Q[i] = 1
	POP r0
	LWHI r1,generalbuf2
	OR r1,r0
	PRINTREG r1
	SWHI r1				 
	LWLO r1,generalbuf2
	SWLO r1,generalbuf2
.fin0:
	POP r1  ;; restore Nh
.for_end0:
	SRL r0,1
	BEQ r0,0,.done0
	JUMP .for_start0

.done0:
	POP r1 ; restore Nh
	CPY0 0b1000_0000
.for_start1:
	;CALL print_bin
	;CALL println
	CALL println
	SLL16 1,$Rl,$Rh,r0
	CH 'N'
	PRINTREG r1
	;; Finding N(i)
	PUSH r1  ;; copy Nl
	AND r1,r0  ; AND i,N
	
	BEQ r1,0,.z1  ; if N&i == 0, do nothing
	PUSH r0
	CPY0 0x01
	OR $Rl,r0 ; R[0] = 1
	POP r0
.z1:
	CH 0x20
	CH 'R'
	PRINTREG $Rh
	PRINTREG $Rl
	; check if R >= D
	PUSH r0
	%def $Dl,r1
	%def $Dh,r0
	LOAD generalbuf,$Dh,$Dl
	
	CH 0x20
	CH 'D'
	CALL print_hex
	PRINTREG r1
	CH 0x20
	BGE16 .sub1,$Rh,$Rl,$Dh,$Dl
	POP r0
	JUMP .fin1
.sub1:
	; R -= D
	SUB $Rl,$Dl
	SUB $Rh,$Dh
	SUBC $Rh
	; Q[i] = 1
	POP r0
	LWHI r1,generalbuf2 ; \ keep high byte
	SWHI r1				; / 
	LWLO r1,generalbuf2
	OR r1,r0
	PRINTREG r1
	SWLO r1,generalbuf2
.fin1:
	POP r1  ;; restore Nl
.for_end1:
	SRL r0,1
	BEQ r0,0,.done1
	JUMP .for_start1
.done1:
	RET

mod_u16:
	; {Ah, Al} = {Ah, Al} % {Bh, Bl}
	%def $Al,r1
	%def $Ah,r0
	%def $Bl,r3 
	%def $Bh,r2 
	%def $Xl,r3 
	%def $Xh,r2 

	PUSH $Bl
	PUSH $Bh 
	PUSH $Al
	PUSH $Ah 
	; Assume X = B

	; Change A /= 2
	PUSH r2
    SRL $Ah,1
	GETAH r2
	SRL $Al,1
	OR $Al,r2
	POP r2
	; While x <= A/2
.part1:
	CI2 $Ah
	BGT $Xh,0,.part2
	CI2 $Xh
	BGT $Ah,0,.xsl
	CI2 $Al	
	BGT $Xl,0,.part2
.xsl:
	PUSH r0
    SLL $Xl,1
	GETAH r0
	SLL $Xh,1
	OR $Xh,r0
	POP r0
	JUMP .part1
.part2:
	; Saving X
	SWHI $Xh
	SWLO $Xl,generalbuf
    ; Returning A
	POP $Ah
	POP $Al
	; Returning B
	POP $Bh
	POP $Bl
.p2check:	
	; Check A>=B
	;PRINTREG
	CI2 $Ah	
	BGT $Bh,0,.done
	CI2 $Bh	
	BGT $Ah,0,.loop
	CI2 $Al	
	BGT $Bl,0,.done
    ; end of check
.loop:
	; Store B
	PUSH $Bl
	PUSH $Bh
	; Load X
	LWHI $Xh,generalbuf
	LWLO $Xl,generalbuf

	; if A >= X
	;PRINTREG
	CI2 $Xh	
	BGT $Ah,0,.agtx
	CI2 $Xl	
	BGT $Al,0,.agtx
	CI2 $Xl	
	BEQ $Al,0,.agtx
	JUMP .next
	; A -= X
.agtx:
	SUB $Ah,$Xh
	SUB $Al,$Xl
	SUBC $Ah
.next:
	; X >>= 1
	SRL $Xh,1
	PUSH r0
	GETAH r0
	SRL $Xl,1
	OR $Xl,r0
	POP r0
	
	; Pack X
	SWHI $Xh
	SWLO $Xl,generalbuf

	POP $Bh
	POP $Bl
	JUMP .p2check
.done:
	RET
	
	
loop:
	CPY0 0
	PUSH r0
	CPY0 '>'
	CALL print_char
	CPY0 0x20  ; space
	CALL print_char
;.loop
;	CALL read_char
;	CALL print_char
;	;BEQ r2,0x0a,.start
;	BEQ r0,0x0d,.error
;	JUMP .loop
;.error	
;	CPY1 error_text@0	
;	CPY2 error_text@1	
;	CALL print_msg
;	JUMP .start

.read:
	CALL read_char
	BGT r0,57,.readc0 
	BGT r0,48,.readadd
.readc0:
	BEQ r0,0x0d,.done
	;BEQ r0,0x20,.echo
	BEQ r0,0x08,.backspace
	BEQ r0,0x7F,.backspace
	BEQ r0,0x2A,.readadd  ; *
	BEQ r0,0x2B,.readadd  ; +
	BEQ r0,0x2D,.readadd  ; -
	BEQ r0,0x2F,.readadd  ; /
	JUMP .read
.backspace:
;	POP r1
;	BEQ r1,0,.backspaceCheck
;	CPY0 0x1B
;	CALL print_char
;	CPY0 'c'
;	CALL print_char
;	JUMP .read
;.backspaceCheck
;	PUSH r1
	JUMP .read
.readadd:
	LWLO r3,termHiFlag
	BZ r3,.readadd0
	JUMP .readstore
.readadd0:
	CPY3 1
	SWHI r0
	SWLO r3,termHiFlag
	JUMP .echo
.readstore:
	CPY2 0
	LWHI r3,termHiFlag
	SWLO r2,termHiFlag
	MOVE r2,r0
	CPY0 termBuff@0
	CPY1 termBuff@1
	CALL arrayPush
	; Check if buffer overflow
	BZ r0,.readstore0
	MOVE r0,r2
	JUMP .echo
.readstore0:
	MOVE r0,r2
	BZ r1,.error0
.echo:
	CALL print_char
	JUMP .read
.done:
	; if odd number of chars, push r0, 0 to array
	LWLO r3,termHiFlag
	BZ r3,.doneC
	;LWHI r2,termHiFlag
	;CPY3 0
	;CPY0 termBuff@0
	;CPY1 termBuff@1
	;CALL arrayPush
.doneC:
	CPY1 termBuff@0
	CPY2 termBuff@1
	CALL Process
	CPY0 termBuff@0
	CPY1 termBuff@1
	CALL arrayClear
	JUMP loop
.done0:
	POP r0
	BEQ r0,0,.done1
	CALL print_char
	JUMP .done0
.done1:
	CALL println
	JUMP loop

.error0:
	CALL println
	CPY1 error0@0	
	CPY2 error0@1	
	CALL print_msg
	CALL println
	JUMP loop

	MOVE r1,r0
	SUBI r1,48
	CALL print_char

	CALL read_char
	MOVE r2,r0
	CALL print_char
	
	CALL read_char
	MOVE r3,r0
	SUBI r3,48
	CALL print_char
	
	BEQ r2,'+',.add0
	BEQ r2,'-',.sub0
	JUMP .invalid
.add0:
	ADD r1,r3
	JUMP .result
.sub0:
	SUB r1,r3
	JUMP .result
.invalid:
	CPY1 error_text@0	
	CPY2 error_text@1	
	CALL print_msg
	JUMP .done
.result:
	PUSH r1
	CPY0 '='
	CALL print_char
	POP r0
	ADDI r0,48
	CALL print_char

Process:
	; Input array *{r2 r1}
	;CPY1 termBuff@0
	;CPY2 termBuff@1
.readnext:
	INC r1
	ADDC r2
	CI1 r2
	CI0 r1
	SWLO r0,NULL
.isdigit:
	;BGT r0,57,.issymbol 
	;BGT r0,48,.digit
.issymbol:
	;JUMP .error 
.digit:
	;CI1 r2
	;CI0 r1
	;SWHI r0
.error:	
	CPY1 error_text@0	
	CPY2 error_text@1	
	CALL print_msg
	CPY1 termBuff@0
	CPY2 termBuff@1
	INC r1
	ADDC r2
	CALL print_msg
.end:
	CALL println
	RET


print_bin:
; print r0 as binary
	PUSH r2
	PUSH r1
	PUSH r0
	CPY2 0b1000_0000	
	MOVE r1,r0
.start:
	AND r0,r2
	BZ r0,.print0
.print1:
	CPY0 '1'
	CALL print_char
	JUMP .end
.print0:
	CPY0 '0'
	CALL print_char
.end:
	SRL r2,1
	BZ r2,.done
	MOVE r0,r1
	JUMP .start
.done:
	POP r0
	POP r1
	POP r2
	RET	

print_hex:
; print r0 as hex
	PUSH r0
	PUSH r1
	MOVE r1,r0
	SRL r0,4
	BGT r0,9,.p0
	ADDI r0,48
	JUMP .p1
.p0:
	ADDI r0,55
.p1:
	CALL print_char
	MOVE r0,r1
	POP r1
	ANDI r0,0b0000_1111
	BGT r0,9,.p2
	ADDI r0,48
	JUMP .p3
.p2:
	ADDI r0,55
.p3:
	CALL print_char
	POP r0
	RET
	

;.done
	;; Equation 1
	;CPY1 eq1_text@0	
	;CPY2 eq1_text@1	
	;CALL print_msg
	;CPY0 3
	;ADDI r0,2
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char
	;
	;; Equation 2
	;CPY1 eq2_text@0	
	;CPY2 eq2_text@1	
	;CALL print_msg
	;CPY0 6
	;SUBI r0,2
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char

	;; Equation 3
	;CPY1 eq3_text@0	
	;CPY2 eq3_text@1	
	;CALL print_msg
	;CPY0 3
	;CPY1 2
	;MUL r0,r1
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char
	;
	;CPY1 eq3x_text@0	
	;CPY2 eq3x_text@1	
	;CALL print_msg
	;AH r0
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char

	;; Equation 4
	;CPY1 eq4_text@0	
	;CPY2 eq4_text@1	
	;CALL print_msg
	;CPY0 9
	;CPY1 2
	;DIV r0,r1
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char

	;; Equation 5
	;CPY1 eq5_text@0	
	;CPY2 eq5_text@1	
	;CALL print_msg
	;AH r0
	;ADDI r0,48 ; Convert to ascii
	;CALL print_char
	
	;CALL println
	;JUMP .start
	;CPY3 0
start:
	INC r3
	JUMP start

interrupt:
	PUSH r0
	GETIF r0
	POP r0
	RETI

println:
	PUSH r0
	CPY0 LF
	CALL print_char
	CPY0 CR
	CALL print_char
	POP r0
	RET

%define SLIMIT 255
sieveOfAtkin:
	; Calculate primes up to limit
	CPY0 MEMEND@0
	CPY1 MEMEND@1
	CPY2 0
	CPY3 0
	; Initialising memory with 0s
.clearCell:
	CPY2 0
	CI0 r0
	CI0 r1
	SWLO r2,NULL
	INC r3
	ADDC r3
	INC r1
	ADDC r0
	BZ r3,.clearCell
.main:
	CPY0 1 ; x=1
.loopx:
	; FOR loop x
	PUSH r0
	MUL r0,r0 ; x^2
	; check if more than 2 bytes
	AH r2
	BZ r2,.loopx0
	POP r0
	JUMP .p2; to part2 
.loopx0:  ; Loop content
	CPY1 1 ; y=1
.loopy:
	; FOR loop y
	PUSH r1
	MUL r1,r1 ; y^2
	; check if more than 2 bytes
	AH r2
	BZ r2,.loopy0
	POP r1
	JUMP .loopxe; to loop x end
.loopy0:  ; Loop content

; ======================
; START OF MAIN FUNCTION
; ======================

 ;At this point r0=x^2; r1=y^2
	CPY2 4 ; n=4
	MUL r2,r0 ; n=4*x^2
	AH r3 ; check for overflow
	BZ r3,.c1a
	JUMP .c2
.c1a:
	ADD r2,r1 ; n=4*x^2 + y^2
	ADDC r3 ; check for overflow
	BZ r3,.c1b
	JUMP .c2
.c1b: ; check if n%12==1
	PUSH r2
	CPY3 12
	DIV r2,r3
	AH r2
	CPY3 1
	XOR r3,r2
	BZ r3,.c1f
	; check if n%12==5
	CPY3 5
	XOR r3,r2
	BZ r3,.c1f
	POP r2; return n from stack
	; else cary on C2
	JUMP .c2
.c1f:
	POP r2; return n from stack
	CALL sieveOfAtkinInvN
.c2:
; At this point r0=x^2; r1=y^2
	CPY2 3 ; n=3
	MUL r2,r0 ; n=3*x^2
	AH r3 ; check for overflow
	BZ r3,.c2a
	JUMP .c3
.c2a:
	ADD r2,r1 ; n=3*x^2 + y^2
	ADDC r3 ; check for overflow
	BZ r3,.c2b
	JUMP .c3
.c2b: ; check if n%12==7
	PUSH r2
	CPY3 12
	DIV r2,r3
	AH r2
	CPY3 7
	XOR r3,r2
	POP r2
	BZ r3,.c2f
	JUMP .c3
.c2f:
	CALL sieveOfAtkinInvN
.c3:
; At this point r0=x^2; r1=y^2
; n=3*x^2-y^2
	CPY2 3
	MUL r2,r0
	AH r3
	SUB r2,r1
	SUBC r3
	BZ r3,.c3a ; check for limit
	JUMP .loopye
.c3a:; check if x>y
	; r2=n
	POP r1 ; get y
	POP r0 ; get x
	CI2 r1
	BGT r0,0,.c3b
	PUSH r0
	PUSH r1
	JUMP .loopye
.c3b:; check if n%12==11
	PUSH r0
	PUSH r1
	PUSH r2
	CPY3 12
	DIV r2,r3
	AH r2 ; n%12
	CPY3 11
	XOR r3,r2
	POP r2
	BZ r3,.c3c
	JUMP .loopye
.c3c:
	CALL sieveOfAtkinInvN

; ====================
; END OF MAIN FUNCTION
; ====================

.loopye:
	POP r1
	INC r1
	JUMP .loopy
.loopxe:
	POP r0
	INC r0
	JUMP .loopx
.p2:
	; for (r=5;r^2<limit;r++)
	CPY0 5  ; r=5
.loopr:
	MOVE r1,r0
	MUL r1,r0 ; r^2
	AH r3
	BZ r3,.r0e ; check for overflow
	JUMP .end
.r0e:
	CPY2 MEMEND@0
	CPY3 MEMEND@1
	ADD r2,r0 ; Add r to pointer
	ADDC r3
	CI0 r2
	CI1 r3
	LWLO r2,NULL ; if sieve[r]
	BZ r2,.loopre
	; for(i = r^2; i<limit;i+=r^2) sieve[r]=0
	; at this point r0 -> r;  r1 -> r^2
	PUSH r0
	MOVE r0,r1 ; set i=r^2
.loopi:
	; sieve[r] = 0
	CPY2 MEMEND@0
	CPY3 MEMEND@1
	ADD r2,r0
	ADDC r3
	CPY0 0
	CI0 r2
	CI1 r3
	LWLO r0,NULL
.loopie:
	ADD r0,r1
	ADDC r2
	BZ r2,.loopi ; if carry is zero carry on
	POP r0
.loopre:
	INC r0
	JUMP .loopr
.end:
; shall we print here?
	CPY0 0
	CPY1 MEMEND@0
	CPY2 MEMEND@1
.print0:
	CI0 r1
	CI1 r2
	LWLO r3,NULL
	BZ r3,.print1
	CALL printU8
	PUSH r0
	CPY0 0x20
	CALL print_char
	POP r0
.print1:
	INC r2
	ADDC r1
	INC r0
	ADDC r3
	BZ r3,.print0 ; if not overflow, carry on
	RET

;sieveOfAtkinCore


sieveOfAtkinInvN:
; sieve[n] ^=1 where n=r2
	PUSH r0
	PUSH r1
	PUSH r3
	PUSH r2
	
	CPY3 16
	DIV r2,r3; n/=16

	CPY0 MEMEND@0
	CPY1 MEMEND@1
	ADD r0,r2 ; add n to pointer
	ADDC r1

	CI0 r0
	CI1 r1
	LWHI r2,NULL
	CI0 r0
	CI1 r1
	LWLO r3,NULL
	PUSH r0
	PUSH r1
	; check if high or low byte
	; n is saved from MSB to LSB e.g.:
	; data in memory address:
	;    0 0 0 0  0 0 0 0    0 0 0 0  0 0 0 0
	; n= 0 1 2 3  4 5 6 7    8 9 A B  C D E F
	; At this point r3=memLO, r2=memHI
	CPY0 1
	AH r1; n%16
	BGE r1,8,.lo
	JUMP .hi
.lo:
	SUBI r1,8
	CI2 r1
	SLL r0,0  ; 1 << (n-8)
	XOR r3,r0
	JUMP .fi
.hi:
	CI2 r1
	SLL r0,0  ; 1 << n
	XOR r2,r0
.fi:
	; Everything's been flipped, time to upload to ram
	POP r1
	POP r0

	SWHI r2
	CI0 r0
	CI1 r1
	SWLO r3,NULL
	
	POP r2
	POP r3
	POP r1
	POP r0	

;	MOVE r0,r2
;	CPY1 16
;	DIV r0,r1; n/=16
;	PUSH r2
;	; Get array pointer + n/=16
;	CPY1 MEMEND@0
;	CPY2 MEMEND@1
;	ADD r2,r0
;	ADDC r1

	RET

mulU16:
	; Multiply 2 unsigned 16-bit int
	; {r0 r1} * {r2 r3}
	;  A  B   *  X  Y
	; Result:
	; r3 = BY0
	; r2 = BY1+BX0+AY0
	; r1 = BX1+AY1+AX0
	; r0 = AX1
	; Carryout must be included to higher bytes
	PUSH r3
	MUL r3,r1 ; BY0
	SWHI r3
	AH r3  ; BY1
	SWLO r3,mul16buf
	POP r3   ; Buffer = [BY0 BY1]
	PUSH r2
	MUL r2,r1 ; BX0
	SWHI r2
	AH r2  ; BX1
	SWLO r2,mul16buf+1
	POP r2   ; Buffer = [BY0 BY1 BX0 BX1]
	PUSH r3
	MUL r3,r0 ; AY0
	SWHI r3
	AH r3  ; AY1
	SWLO r3,mul16buf+2
	POP r3   ; Buffer = [BY0 BY1 BX0 BX1 AY0 AY1]
	PUSH r2
	MUL r2,r0 ; AX0
	SWHI r2
	AH r2  ; AX1
	SWLO r2,mul16buf+3
	POP r2   ; Buffer = [BY0 BY1 BX0 BX1 AY0 AY1 AX0 AX1]
			 ;			 {  0  } {  1  } {  2  } {  3  }
	; r3 will be used as spare register as it's equal to BY0
	
	LWLO r2,mul16buf    ; r2=BY1
	LWLO r1,mul16buf+1  ; r1=BX1
	LWLO r0,mul16buf+3  ; r0=AX1
	LWHI r3,mul16buf+1  ;  t=BX0
	ADD r2,r3
	ADDC r1
	ADDC r0
	LWHI r3,mul16buf+2  ;  t=AY0
	ADD r2,r3
	ADDC r1
	ADDC r0
	LWLO r3,mul16buf+2  ;  t=AY1
	ADD r1,r3
	ADDC r0
	LWHI r3,mul16buf+3  ;  t=AX0
	ADD r1,r3
	ADDC r0
	LWHI r3,mul16buf    ; r3=BY0
	RET	

bin2digit:
	; Converts U16 to digit
	; Adopted from http://www.avr-asm-tutorial.net/avr_en/calc/CONVERT.html#bin2bcd
	; Digit {r0 r1}, Place in 10^n {r2 r3}
	PUSH r0
	CPY0 0
	SWLO r0,generalbuf  ; Using general buf to store number
	POP r0
.a:
	CI2 r0
	BGT r2,0,.c  ; MSB is smaller than digit
	CI2 r2
	BGT r0,0,.b ; MSB is grater than digit
	CI2 r1
	BGT r3,0,.c ; LSB is smaller than digit
.b:
	PUSH r0
	LWLO r0,generalbuf
	INC r0
	SWLO r0,generalbuf 
	POP r0
	SUB r0,r2
	SUB r1,r3
	SUBC r0
	JUMP .a
.c:
	LWLO r2,generalbuf
	RET	

printU16:
; print unsigned 16bit int as base-10 digit
; arguments: digit {r0, r1}
	PUSH r0
	PUSH r1
	PUSH r2
	PUSH r3

	CPY2 10000@1
	CPY3 10000@0
	CALL bin2digit
	MOVE r3,r0
	MOVE r0,r2
	ADDI r0,48 ; Convert to ascii digit
	CALL print_char
	MOVE r0,r3
	
	CPY2 1000@1
	CPY3 1000@0
	CALL bin2digit
	MOVE r3,r0
	MOVE r0,r2
	ADDI r0,48 ; Convert to ascii digit
	CALL print_char
	MOVE r0,r3

	CPY2 0
	CPY3 100
	CALL bin2digit
	MOVE r0,r2
	ADDI r0,48 ; Convert to ascii digit
	CALL print_char

	MOVE r0,r1
	CALL printU8

	POP r3
	POP r2
	POP r1
	POP r0
	RET

printU8:
	; Assuing number is 128
	; a = 128%10 = 8
	; a = 128%100 - a // 10 = 2
	; a = 128%1000 - a // 100 = 1
	; in case of 8bit number quicker is to do 2 if statements for 100s
	; input argument is in r0
	PUSH r0
	PUSH r1
	PUSH r2
	PUSH r3
	CPY2 10
	
	MOVE r1,r0
	DIV r1,r2
	AH r1
	PUSH r1  ; Stored last digit
	BGE r0,10,.ge10
	JUMP .p3
.ge10:
	CPY2 100
	MOVE r3,r0
	DIV r3,r2
	AH r3
	SUB r3,r1
	CPY2 10
	DIV r3,r2
	PUSH r3  ; Stored middle digit

	BGE r0,100,.ge100
	JUMP .p2
.ge100:
	CPY2 200
	CI2 r2
	BGE r0,0,.s2
	CPY2 100
	CI2 r2
	BGE r0,0,.s1
	JUMP .p2
.s1: 
	CPY0 '1'
	JUMP .p0
.s2:
	CPY0 '2'
.p0:
	CALL print_char
.p2:
	POP r0
	ADDI r0,48
	CALL print_char
.p3:
	POP r0
	ADDI r0,48
	CALL print_char
	POP r3
	POP r2
	POP r1
	POP r0
	RET

arrayClear:
	; Clear array at *{r1 r0}
	PUSH r2
	CI1 r1
	CI0 r0
	LWHI r2,NULL
	SWHI r2
	CPY2 0
	CI1 r1
	CI0 r0
	SWLO r2,NULL
	POP r2
	RET

arrayPush:
	; Push to array *{r1 r0} value {r3 r2}
	; If full, changes r1 r0 to 0x0000
	PUSH r2
	PUSH r3

	CI1 r1
	CI0 r0
	LWLO r2,NULL

	CI1 r1
	CI0 r0
	LWHI r3,NULL ; Stores cap
	; r2=size, r3=cap

	CI2 r3
	BGE r2,0xFF,.full
	INC r2
	SWHI r3
	CI1 r1
	CI0 r0
	SWLO r2,NULL
	
	ADD r0,r2
	ADDC r1

	POP r3
	SWHI r3
	POP r2
	CI1 r1
	CI0 r0
	SWLO r2,NULL
	RET
.full:
	POP r3
	POP r2
	CPY0 0
	CPY1 0
	RET

arrayPop:
	; Pop from array *{r1 r0} value {r3 r2}
	; If empty, changes all regs to 0x00
	CI1 r1
	CI0 r0
	LWLO r2,NULL
	BEQ r2,0,.empty
	DEC r2
	CI1 r1
	CI0 r0
	SWLO r2,NULL
	INC r2
	ADD r0,r2
	ADDC r1
	CI1 r1
	CI0 r0
	LWHI r3,NULL
	CI1 r1
	CI0 r0
	LWLO r2,NULL
	RET
.empty:
	CPY3 0
	CPY2 0
	CPY1 0
	CPY0 0
	RET

read_char:  ; read char to r0
	COM r0,COM_UARTR
	ANDI r0,0b0000_1000
	BZ r0,read_char
	COM r0,COM_UARTIN
	RET

malloc: ; returns memory free memory locaion
	; r0 = size to allocate
	; {r2, r1} memory pointer
	LWHI r2,mallocPointer	
	LWLO r1,mallocPointer
	PUSH r2
	PUSH r1
	ADD r1,r0
	ADDC r2
	SWHI r2
	SWLO r1,mallocPointer	
	POP r1
	POP r2
	RET

print_msg:  ; print value in mem pinter {r2 r1}
	PUSH r0
.loop:
	CI1 r2
	CI0 r1
	LWHI r0,NULL
	BZ r0,.end
	CALL print_char
	CI1 r2
	CI0 r1
	LWLO r0,NULL	
	BZ r0,.end
	CALL print_char
	INC r1
	ADDC r2
	JUMP .loop
.end:
	POP r0
	RET

print_char:  ; print value in r0
	PUSH r0
.loop:
	COM r0,COM_UARTR
	ANDI r0,0b0000_0010
	XORI r0,0b0000_0010 ; invert
	BZ r0,.loop
	POP r0
	COM r0,COM_UARTW
	RET
