; Transfer control to the beginning of the block memory copy function.
; This jump is necessary in order to not execute the words of data
; below here (which are used to load the appropriate registers with the
; source memory location, destination memory location, and number of words
; to copy).
    JMP     blockcopy

; Block memory copy information structure. This structure stores the
; source memory location in the first word, the destination memory location
; in the second word, and the number of words to copy in the third word
info:
    .WORD   src
    .WORD   dst
    .WORD   32

; The block memory copy function. This function will load register R1 with
; the value 2, register R5 with the source memory location, register R6
; with the destination memory location, and register R10 with the number
; of words to copy.
    .ALIGN  4
blockcopy:
    ADD     R1, R1, R2
    LW      R0, R5, 2
    LW      R0, R6, 4
    LW      R0, R10, 6

; Check if there are any remaining words to be copied. If there are remaining
; words to be copied then simply continue execution. If there are no more
; words to be copied then branch to the label "done"
    .ALIGN  4
check:
    SET     R10, R0, 0b0011
    BRA     0b0011, done

; Transfer one word of memory from the source memory location to the
; destination memory location. The current source memory location is
; maintained in register R5 and the current destination memory location
; is maintained in register R6. These registers along with register R10
; are updated to the next values upon completion of the instruction
; sequence.
transfer:
    LW      R5,  R11, 0
    SW      R6,  R11, 0
    ADD     R5,  R2,  R5
    ADD     R6,  R2,  R6
    SUB     R10, R1,  R10
    JMP     check

; Finish  the execution of the block memory copy. This implements a simple
; infinite loop where the JMP instruction is just jumping to itself.
    .ALIGN  4
done:
    JMP     done

; The source memory location. This label designates the location in memory
; of the source data values. There are 32 data values in this example.
src:
    .WORD   0x0001
    .WORD   0x0002
    .WORD   0x0004
    .WORD   0x0008
    .WORD   0x0010
    .WORD   0x0020
    .WORD   0x0040
    .WORD   0x0080
    .WORD   0x0100
    .WORD   0x0200
    .WORD   0x0400
    .WORD   0x0800
    .WORD   0x1000
    .WORD   0x2000
    .WORD   0x4000
    .WORD   0x8000
    .WORD   0x1111
    .WORD   0x2222
    .WORD   0x3333
    .WORD   0x4444
    .WORD   0x5555
    .WORD   0x6666
    .WORD   0x7777
    .WORD   0x8888
    .WORD   0x9999
    .WORD   0xAAAA
    .WORD   0xBBBB
    .WORD   0xCCCC
    .WORD   0xF0F0
    .WORD   0x0F0F
    .WORD   0xAAAA
    .WORD   0x5555

; The destination memory location. This label designates the location in memory
; of the destination data values. There are 32 word locations reserved here
; for the block memory copy operation to work with.
dst:
    .FILL   32
