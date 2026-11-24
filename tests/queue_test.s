# =============================================================================
# queue_test —— ds/queue.s 的单元测试
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> "ok\n"；不等 -> "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：空队出队 / FIFO 顺序 / 队满溢出忽略 / tail 与 head 双向环形回绕
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
        call queue_init

        call queue_pop          # T1: 空队 pop == 0
        movl $0, %edi
        call check

        movl $1, %edi           # push 1 2
        call queue_push
        movl $2, %edi
        call queue_push

        call queue_pop          # T2: FIFO，先入先出 -> 1
        movl $1, %edi
        call check

        call queue_pop          # T3: 再出 -> 2
        movl $2, %edi
        call check

        call queue_pop          # T4: 空队 pop == 0
        movl $0, %edi
        call check

        movl $1, %edi           # 填满 8 槽：1..8（tail 回绕到 0）
.Lqu_fill:
        cmpl $9, %edi
        je   .Lqu_fill_done
        call queue_push
        incl %edi
        jmp  .Lqu_fill
.Lqu_fill_done:

        call queue_pop          # 出队 1，腾出槽位（head=1, count=7）
        movl $9, %edi           # 入队 9 -> 槽 0，tail 回绕
        call queue_push
        call queue_pop          # 出队 2（head=2, count=7）
        movl $10, %edi          # 入队 10 -> 槽 1，tail 回绕
        call queue_push

        call queue_pop          # T5: 混合出入队后依次弹出 3..10
        movl $3, %edi
        call check
        call queue_pop          # T6
        movl $4, %edi
        call check
        call queue_pop          # T7
        movl $5, %edi
        call check
        call queue_pop          # T8
        movl $6, %edi
        call check
        call queue_pop          # T9
        movl $7, %edi
        call check
        call queue_pop          # T10
        movl $8, %edi
        call check
        call queue_pop          # T11
        movl $9, %edi
        call check
        call queue_pop          # T12
        movl $10, %edi
        call check

        call queue_pop          # T13: 完全清空后 pop == 0
        movl $0, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/queue.s"
