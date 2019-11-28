    global start
    section .text
start:
    mov
message: db   "Hello Wolrd", 0


;CPY $re 0xFF
;CPY $rb 0x01
;CPY $ra 'H'
;SW $ra $re
;
;CPY $ra '3'
;node3:
;LW $rc $re
;JEQ $rc $rb node3
;SW $ra $re
;
;CPY $ra 'l'
;nodeL1:
;LW $rc $re
;JEQ $rc $rb nodeL1
;SW $ra $re
;
;nodeL2:
;LW $rc $re
;JEQ $rc $rb nodeL2
;SW $ra $re
;
;CPY $ra '0'
;node0:
;LW $rc $re
;JEQ $rc $rb node0
;SW $ra $re
;
;CPY $ra '_'
;nodeS:
;LW $rc $re
;JEQ $rc $rb nodeS
;SW $ra $re
;
;CPY $ra 'P'
;nodeP:
;LW $rc $re
;JEQ $rc $rb nodeP
;SW $ra $re
;
;CPY $ra 'r'
;nodeR:
;LW $rc $re
;JEQ $rc $rb nodeR
;SW $ra $re
;
;CPY $ra '1'
;node1:
;LW $rc $re
;JEQ $rc $rb node1
;SW $ra $re
;
;CPY $ra 'c'
;nodeC:
;LW $rc $re
;JEQ $rc $rb nodeC
;SW $ra $re
;
;CPY $ra 'k'
;nodeK:
;LW $rc $re
;JEQ $rc $rb nodeK
;SW $ra $re
;
;CPY $ra 0x0A
;nodeLF:
;LW $rc $re
;JEQ $rc $rb nodeLF
;SW $ra $re
;
;CPY $ra 0x0D
;nodeCR:
;LW $rc $re
;JEQ $rc $rb nodeCR
;SW $ra $re
;
;stop:
;JMP stop
