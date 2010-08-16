    .ALIGN  4
start:
    ADD     R1, R1, R4
    ADD     R4, R4, R3
    ADD     R3, R1, R3
    ADD     R3, R3, R3
    ADD     R0, R0, R5

.INCLUDE "mul.s"
.INCLUDE "div.s"
