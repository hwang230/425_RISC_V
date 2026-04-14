main:
    lui x2, 65536   
    addi x3,  x0, 6
    addi x4,  x0, 3
    lui  x5,  1              # x5 = 0x00001000
    auipc x6, 2              # x6 = PC + (2 << 12)
    addi x20, x0, 9

    mul  x7,  x3, x4         # x7 = 18
    xori x8,  x20, 5         # x8 = 12
    ori  x9,  x4, 8          # x9 = 11
    andi x10, x20, 7         # x10 = 1
    slti x11, x4, 5          # x11 = 1
    addi x0,  x0, 0          # nop

    sw   x7,  0(x2)          # MEM[96]  = 18
    sw   x9,  4(x2)          # MEM[100] = 11
    addi x0,  x0, 0          # nop
    lw   x12, 0(x2)          # x12 = 18
    lw   x13, 4(x2)          # x13 = 11

    addi x0,  x0, 0          # nop
    addi x0,  x0, 0          # nop
    addi x0,  x0, 0          # nop

    blt  x4,  x3, less_path
    jal  x0,  fail

less_path:
    bge  x12, x13, pass
    jal  x0,  fail

pass:
    jal  x0,  pass

fail:
    jal  x0,  fail
