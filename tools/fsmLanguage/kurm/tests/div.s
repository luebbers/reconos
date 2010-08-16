    .ALIGN  4
div:
    ADD     R1, R1, R4
    ADD     R4, R4, R3
    ADD     R3, R1, R3
    ADD     R3, R3, R3
    ADD     R0, R0, R5

_div_zero:
    CMPEQ   R4, R0
    JMPC    _div_done

_div_check:
    CMPL    R3, R4
    BRAL    _div_done    

_div_loop:
    ADD     R5, R1, R5
    SUB     R3, R4, R3
    CMPGE   R3, R4
    BRAGE   _div_loop

    .ALIGN 4
_div_done:
    JMP     _div_done
