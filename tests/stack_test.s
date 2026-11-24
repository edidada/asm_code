# =============================================================================
# stack_test —— ds/stack.s 的单元测试
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> "ok\n"；不等 -> "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：空栈弹出 / LIFO 顺序 / 满栈溢出忽略 / 完整清空
# =============================================================================
.data
t_ok:    .ascii "ok\n"
t_fail:  .ascii "FAIL got="
t_want:  .ascii " want="

.text
.globl _start

# check：eax = 实际值, edi = 期望值
check:
        pushq %rax
        cmpl %edi, %eax
        je   .Lchk_ok
        pushq %rdi
        movl $t_fail, %edi
        movl $9, %esi
        call print_str
        movl 8(%rsp), %edi
        call print_int
        movl $t_want, %edi
        movl $6, %esi
        call print_str
        movl (%rsp), %edi
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
        call stack_init

        call stack_pop          # T1: 空栈 pop == 0
        movl $0, %edi
        call check

        movl $1, %edi           # push 1 2
        call stack_push
        movl $2, %edi
        call stack_push

        call stack_pop          # T2: LIFO，后压先弹 -> 2
        movl $2, %edi
        call check

        call stack_pop          # T3: 再弹 -> 1
        movl $1, %edi
        call check

        call stack_pop          # T4: 弹空后 pop == 0
        movl $0, %edi
        call check

        movl $1, %edi           # 压满 8 个：1..8
.Lst_fill:
        cmpl $9, %edi
        je   .Lst_fill_done
        call stack_push
        incl %edi
        jmp  .Lst_fill
.Lst_fill_done:

        movl $99, %edi          # 满栈再压 99（应被忽略）
        call stack_push

        call stack_pop          # T5: pop == 8（99 没有入栈）
        movl $8, %edi
        call check

        call stack_pop          # T6: pop == 7
        movl $7, %edi
        call check

        call stack_pop          # T7: pop == 6
        movl $6, %edi
        call check

        call stack_pop          # T8: pop == 5
        movl $5, %edi
        call check

        call stack_pop          # T9: pop == 4
        movl $4, %edi
        call check

        call stack_pop          # T10: pop == 3
        movl $3, %edi
        call check

        call stack_pop          # T11: pop == 2
        movl $2, %edi
        call check

        call stack_pop          # T12: pop == 1
        movl $1, %edi
        call check

        call stack_pop          # T13: 完全清空后 pop == 0
        movl $0, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/stack.s"
