# =============================================================================
# list_test —— ds/list.s 的单元测试
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> "ok\n"；不等 -> "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：空表删除 / 删除头/中/尾节点 / 重复删除 / 节点池耗尽 / 释放后复用
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
        call list_init

        movl $5, %edi           # T1: 空表删除 -> 1（未找到）
        call list_remove
        movl $1, %edi
        call check

        movl $1, %edi           # push 1 2 3
        call list_push_back
        movl $2, %edi
        call list_push_back
        movl $3, %edi
        call list_push_back

        movl $2, %edi           # T2: 删除中间节点 2 -> 0（成功）
        call list_remove
        movl $0, %edi
        call check

        movl $2, %edi           # T3: 再次删除 2 -> 1（已不存在）
        call list_remove
        movl $1, %edi
        call check

        movl $1, %edi           # T4: 删除头节点 1 -> 0
        call list_remove
        movl $0, %edi
        call check

        movl $3, %edi           # T5: 删除最后节点 3（表清空，tail 归零）-> 0
        call list_remove
        movl $0, %edi
        call check

        movl $3, %edi           # T6: 空表再删 -> 1
        call list_remove
        movl $1, %edi
        call check

        movl $1, %edi           # 压满 8 个节点（节点池共 8 个，耗尽）
.Lli_fill:
        cmpl $9, %edi
        je   .Lli_fill_done
        call list_push_back
        incl %edi
        jmp  .Lli_fill
.Lli_fill_done:

        movl $99, %edi          # 池耗尽，push 99 被忽略
        call list_push_back

        movl $99, %edi          # T7: remove(99) -> 1（99 没入表）
        call list_remove
        movl $1, %edi
        call check

        movl $1, %edi           # T8: 删除 1 -> 0（释放一个节点）
        call list_remove
        movl $0, %edi
        call check

        movl $99, %edi          # 复用刚释放的节点，push 99
        call list_push_back

        movl $99, %edi          # T9: remove(99) -> 0（节点复用成功）
        call list_remove
        movl $0, %edi
        call check

        movl $8, %edi           # T10: 删除尾节点 8 -> 0（tail 指针正确回退）
        call list_remove
        movl $0, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/list.s"
