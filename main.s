# extern int asm_entry(int *arr, int size);

.section .text
.global asm_entry

asm_entry:
    add  s1, zero, a0
    addi t2, zero, 0
    addi s2, zero, 0
for:
    beq  s2, a1, done
    slli t0, s2, 2
    add  t0, t0, s1
    lw   t1, 0(t0)
    xor  t2, t2, t1 # change this to t2 ^ t1
    addi s2, s2, 1
    j for
done:
    add  a0, zero, t2
    ret
