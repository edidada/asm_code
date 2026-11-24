# =============================================================================
# stack —— 模仿 tbox 的 tb_stack_t（栈，后进先出 LIFO）
# 静态内存池实现：8 个 32 位元素，stk_top 为栈顶下标（0 表示空栈）
# 内部调用约定同 ds/vector.s（edi/esi/edx 传参，eax 返回；被调方保存 ebx/esi/edi/ebp）
# API：
#   stack_init          初始化
#   stack_push  edi=值  入栈（满栈忽略）
#   stack_pop           出栈 -> eax（空栈返回 0）
# =============================================================================
        .lcomm stk_data, 32     # 8 个 32 位元素
        .lcomm stk_top, 4       # 栈顶下标（也是当前元素个数）
        .lcomm ibuf, 12

.data
s_spop:   .ascii "stack pops: "
s_space:  .ascii " "
nl:       .byte 10

.text
.globl _start

# ---------------- API ----------------

# stack_init
stack_init:
        movl $0, stk_top
        ret

# stack_push：edi = 值
stack_push:
        movl stk_top, %eax
        cmpl $8, %eax
        jae  .Lsp_out           # 满栈忽略
        movl %edi, stk_data(,%eax,4)
        incl stk_top
.Lsp_out:
        ret

# stack_pop：-> eax
stack_pop:
        movl stk_top, %eax
        cmpl $0, %eax
        je   .Lspo_empty
        subl $1, %eax
        movl %eax, stk_top
        movl stk_data(,%eax,4), %eax
        ret
.Lspo_empty:
        movl $0, %eax
        ret

# ---------------- 工具函数 ----------------
# 注意：ebx 是约定中"被调方必须保存"的寄存器，而输出函数要往 ebx 里放
# stdout 文件描述符 1，因此三个输出函数都用 pushq/popq 保存恢复 ebx。

# print_str：edi = 地址, esi = 长度
print_str:
        pushq %rbx
        movl %edi, %ecx
        movl %esi, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        ret

# print_nl
print_nl:
        pushq %rbx
        movl $nl, %ecx
        movl $1, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        ret

# print_int：edi = 无符号数
print_int:
        pushq %rsi
        pushq %rbx
        movl %edi, %eax
        leal ibuf+11, %esi
        cmpl $0, %eax
        jne  .Lpi_digit
        movb $48, (%esi)
        subl $1, %esi
        jmp  .Lpi_out
.Lpi_digit:
        cmpl $0, %eax
        je   .Lpi_out
        xorl %edx, %edx
        movl $10, %ecx
        divl %ecx
        addl $48, %edx
        movb %dl, (%esi)
        subl $1, %esi
        jmp  .Lpi_digit
.Lpi_out:
        incl %esi
        movl $ibuf+12, %edx
        subl %esi, %edx
        movl %esi, %ecx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        popq %rsi
        ret

# ---------------- 测试 ----------------
# 冒烟测试：仅独立汇编时包含（as --defsym STANDALONE=1）
# 完整单元测试见 tests/stack_test.s
.ifdef STANDALONE
_start:
        call stack_init
        movl $1, %edi
        call stack_push
        movl $2, %edi
        call stack_push
        movl $3, %edi
        call stack_push
        movl $4, %edi
        call stack_push
        movl $5, %edi
        call stack_push

        movl $s_spop, %edi      # stack pops: 5 4 3 2 1
        movl $12, %esi
        call print_str
        movl $5, %ebx           # 已知栈里有 5 个，依次弹出
.Lspop:
        cmpl $0, %ebx
        je   .Lspop_done
        call stack_pop
        movl %eax, %edi
        call print_int
        cmpl $1, %ebx           # 最后一个元素后不打空格
        je   .Lspop_nosp
        movl $s_space, %edi
        movl $1, %esi
        call print_str
.Lspop_nosp:
        decl %ebx
        jmp  .Lspop
.Lspop_done:
        call print_nl

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
.endif
