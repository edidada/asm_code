# =============================================================================
# vector_test —— ds/vector.s 的单元测试
# 通过 .include 复用数据结构源码（其内嵌冒烟测试被 .ifdef STANDALONE 排除）
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> 打印 "ok\n"；不等 -> 打印 "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：空向量行为 / 基本增删查 / 越界访问 / 容量填满与溢出忽略
# =============================================================================
.data
t_ok:    .ascii "ok\n"
t_fail:  .ascii "FAIL got="
t_want:  .ascii " want="

.text
.globl _start

# check：eax = 实际值, edi = 期望值
check:
        pushq %rax              # 保存实际值
        cmpl %edi, %eax
        je   .Lchk_ok
        pushq %rdi              # 保存期望值
        movl $t_fail, %edi      # "FAIL got="
        movl $9, %esi
        call print_str
        movl 8(%rsp), %edi      # 实际值
        call print_int
        movl $t_want, %edi      # " want="
        movl $6, %esi
        call print_str
        movl (%rsp), %edi       # 期望值
        call print_int
        call print_nl
        addq $16, %rsp
        ret
.Lchk_ok:
        movl $t_ok, %edi
        movl $3, %esi
        call print_str
        addq $8, %rsp
        ret

_start:
        call vector_init

        call vector_size        # T1: 空向量 size == 0
        movl $0, %edi
        call check

        call vector_pop         # T2: 空向量 pop == 0
        movl $0, %edi
        call check

        movl $0, %edi           # T3: 空向量 at(0) == 0（越界）
        call vector_at
        movl $0, %edi
        call check

        movl $10, %edi          # T4: push 10 后 at(0) == 10
        call vector_push
        movl $0, %edi
        call vector_at
        movl $10, %edi
        call check

        movl $20, %edi          # push 20 30 40
        call vector_push
        movl $30, %edi
        call vector_push
        movl $40, %edi
        call vector_push

        call vector_size        # T5: size == 4
        movl $4, %edi
        call check

        movl $3, %edi           # T6: at(3) == 40
        call vector_at
        movl $40, %edi
        call check

        call vector_pop         # T7: pop == 40（后进先出的尾部弹出）
        movl $40, %edi
        call check

        call vector_size        # T8: pop 后 size == 3
        movl $3, %edi
        call check

        movl $3, %edi           # T9: at(3) 越界 == 0
        call vector_at
        movl $0, %edi
        call check

.Lvfill:                        # T10: 循环填满到容量 16（当前 size=3）
        call vector_size
        cmpl $16, %eax
        jae  .Lvfill_done
        addl $100, %eax         # 值 = 100 + size（103..115）
        movl %eax, %edi
        call vector_push
        jmp  .Lvfill
.Lvfill_done:
        call vector_size        # 填满后 size == 16
        movl $16, %edi
        call check

        movl $999, %edi         # T11: 容量满后 push 999 被忽略
        call vector_push
        call vector_size
        movl $16, %edi
        call check

        call vector_pop         # T12: pop == 115（最后压入的 100+15）
        movl $115, %edi
        call check

        call vector_size        # T13: pop 后 size == 15
        movl $15, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/vector.s"
