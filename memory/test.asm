// Initialise
Start:
CPY $rb 0x01
CPY $rc 0x03
While:
ADD $ra $rb
JEQ $ra $rc Start
JMP While

