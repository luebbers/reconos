    .ALIGN  4
mul:
    ADD     R1, R1, R4
    ADD     R4, R4, R3
    ADD     R3, R1, R3
    ADD     R3, R3, R3
    ADD     R0, R0, R5

_mul_check:
    CMPLE    R3, R0
    BRALE    _mul_done    

_mul_loop:
    ADD     R5, R4, R5
    SUB     R3, R1, R3
    CMPG    R3, R0
    BRAG    _mul_loop

    .ALIGN 4
_mul_done:
    JMP     _mul_done
