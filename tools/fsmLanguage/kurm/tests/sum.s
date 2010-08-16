; Transfer control to the beginning of the block memory summation function.
; This jump is necessary in order to not execute the words of data
; below here (which are used to load the appropriate registers with the
; source memory location, destination memory location, and number of words
; to sum).
    JMP     blocksum

; Block memory summation information structure. This structure stores the
; source memory location in the first word, the destination memory location
; in the second word, and the number of words to sum in the third word
info:
    .WORD   src
    .WORD   dst
    .WORD   32

; The block memory summation function. This function will load register R1 with
; the value 2, register R5 with the source memory location, register R6
; with the summation value, and register R10 with the number of words to sum.
    .ALIGN  4
blocksum:
    ADD     R1, R1, R2
    LW      R0, R5, 2
    ADD     R0, R0, R6
    LW      R0, R10, 6

; Check if there are any remaining words to be summed. If there are remaining
; words to be summed then simply continue execution. If there are no more
; words to be summed then branch to the label "done"
    .ALIGN  4
check:
    SET     R10, R0, 0b0011
    BRA     0b0011, done

; Sum one more word of memory from the source memory location. The current
; source memory location is maintained in register R5 and the current sum
; value is maintained in register R6. These registers along with register R10
; are updated to the next values upon completion of the instruction sequence.
sum:
    LW      R5,  R11, 0
    ADD     R6,  R11, R6
    ADD     R5,  R2,  R5
    SUB     R10, R1,  R10
    JMP     check

; Store the summation value into the destination location. The summation
; at this point is still located inside of register R6. Here we are going
; to place it into memory.
done:
    LW      R0, R10, 4
    SW      R10, R6, 0

; Finish  the execution of the block memory summation. This implements a
; simple infinite loop where the JMP instruction is just jumping to itself.
    .ALIGN  4
loop:
    JMP     loop

; The source memory location. This label designates the location in memory
; of the source data values. There are 32 data values in this example.
src:
    .WORD   0x0001
    .WORD   0x0002
    .WORD   0x0003
    .WORD   0x0004
    .WORD   0x0005
    .WORD   0x0006
    .WORD   0x0007
    .WORD   0x0008
    .WORD   0x0009
    .WORD   0x000A
    .WORD   0x000B
    .WORD   0x000C
    .WORD   0x000D
    .WORD   0x000E
    .WORD   0x000F
    .WORD   0x0010
    .WORD   0x0011
    .WORD   0x0012
    .WORD   0x0013
    .WORD   0x0014
    .WORD   0x0015
    .WORD   0x0016
    .WORD   0x0017
    .WORD   0x0018
    .WORD   0x0019
    .WORD   0x001A
    .WORD   0x001B
    .WORD   0x001C
    .WORD   0x001D
    .WORD   0x001E
    .WORD   0x001F
    .WORD   0x0020

; The destination memory location. This label designates the location in memory
; of the destination data values. There are 32 word locations reserved here
; for the block memory sum operation to work with.
dst:
    .FILL   1
