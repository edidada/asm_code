# =============================================================================
# list —— 模仿 tbox 的 tb_list_t（链表）
# 单链表版本；节点来自 .bss 静态节点池（8 个），
# 池内用"空闲链"（free list）模拟 malloc/free —— 与 tbox 固定内存池思路一致
# 节点布局：+0 next（4字节）、+4 value（4字节）；空闲时复用 next 字段串链
# 内部调用约定同 ds/vector.s（edi/esi/edx 传参，eax 返回；被调方保存 ebx/esi/edi/ebp）
# API：
#   list_init                 初始化（串空闲链 + 清空链表）
#   list_push_back  edi=值    尾部追加
#   list_remove     edi=值    删除第一个匹配节点 -> eax（0 成功 / 1 未找到）
#   list_print                打印全部值（空格分隔，不换行）
# =============================================================================
        .lcomm node_pool, 64    # 8 节点 × 8 字节
        .lcomm free_head, 4     # 空闲节点链表头
        .lcomm list_head, 4     # 链表头
        .lcomm list_tail, 4     # 链表尾
        .lcomm ibuf, 12

.data
s_list:  .ascii "list: "
s_rm:    .ascii "after remove: "
s_push:  .ascii "after push: "
s_space: .ascii " "
nl:      .byte 10

.text
.globl _start

# ---------------- API ----------------

# list_init
list_init:
        call pool_init
        movl $0, list_head
        movl $0, list_tail
        ret

# pool_init：把 8 个节点串成空闲链，free_head 指向第一个
pool_init:
        movl $node_pool, %ecx   # ecx = 当前节点
        movl $7, %edx           # 前面 7 个节点各指向下一个
.Lpi_chain:
        cmpl $0, %edx
        je   .Lpi_last
        leal 8(%ecx), %eax
        movl %eax, (%ecx)       # node.next = 下一个节点
        addl $8, %ecx
        decl %edx
        jmp  .Lpi_chain
.Lpi_last:
        movl $0, (%ecx)         # 最后一个节点 next = 0
        movl $node_pool, %eax
        movl %eax, free_head
        ret

# node_alloc：从空闲链取一个节点 -> eax（池空返回 0）
node_alloc:
        movl free_head, %eax
        cmpl $0, %eax
        je   .Lna_out
        movl (%eax), %ecx       # 下一个空闲节点
        movl %ecx, free_head
.Lna_out:
        ret

# node_free：edi = 节点地址，头插归还空闲链
node_free:
        movl free_head, %eax
        movl %eax, (%edi)       # node.next = free_head
        movl %edi, free_head    # free_head = node
        ret

# list_push_back：edi = 值
list_push_back:
        call node_alloc
        cmpl $0, %eax
        je   .Llpb_out          # 池耗尽，忽略
        movl $0, (%eax)         # node.next = 0
        movl %edi, 4(%eax)      # node.value = edi
        movl list_tail, %ecx
        cmpl $0, %ecx
        jne  .Llpb_append
        movl %eax, list_head    # 空表：head = tail = node
        movl %eax, list_tail
        ret
.Llpb_append:
        movl %eax, (%ecx)       # tail.next = node
        movl %eax, list_tail
.Llpb_out:
        ret

# list_remove：edi = 值 -> eax（0 成功 / 1 未找到）
list_remove:
        pushq %rsi              # 本函数用到 esi，按约定保存
        movl list_head, %edx    # edx = 当前节点
        movl $0, %esi           # esi = 前驱节点（0 = 无前驱）
.Llrm_loop:
        cmpl $0, %edx
        je   .Llrm_notfound
        movl 4(%edx), %eax      # cur.value
        cmpl %edi, %eax
        je   .Llrm_found
        movl %edx, %esi         # prev = cur
        movl (%edx), %edx       # cur = cur.next
        jmp  .Llrm_loop
.Llrm_found:
        movl (%edx), %ecx       # next = cur.next
        cmpl $0, %esi
        jne  .Llrm_mid
        movl %ecx, list_head    # 删的是头节点
        cmpl $0, %ecx
        jne  .Llrm_freeit
        movl %ecx, list_tail    # 链表变空，tail 一并清零
        jmp  .Llrm_freeit
.Llrm_mid:
        movl %ecx, (%esi)       # prev.next = next
        cmpl list_tail, %edx    # 删的是尾节点？
        jne  .Llrm_freeit
        movl %esi, list_tail
.Llrm_freeit:
        movl %edx, %edi
        call node_free          # 归还节点池
        movl $0, %eax
        popq %rsi
        ret
.Llrm_notfound:
        movl $1, %eax
        popq %rsi
        ret

# list_print：打印全部值（空格分隔，不换行）
list_print:
        pushq %rbp              # 用 rbp 持有当前节点
        pushq %rbx              # 用 rbx 作"已打印"标志
        movl list_head, %ebp
        movl $0, %ebx
.Llpr_loop:
        cmpl $0, %ebp
        je   .Llpr_end
        cmpl $0, %ebx           # 第一个元素前不打印空格
        je   .Llpr_nosp
        movl $s_space, %edi
        movl $1, %esi
        call print_str
.Llpr_nosp:
        movl $1, %ebx
        movl 4(%ebp), %edi      # node.value
        call print_int
        movl (%ebp), %ebp       # 前进到 next
        jmp  .Llpr_loop
.Llpr_end:
        popq %rbx
        popq %rbp
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
# 完整单元测试见 tests/list_test.s
.ifdef STANDALONE
_start:
        call list_init

        movl $1, %edi
        call list_push_back
        movl $2, %edi
        call list_push_back
        movl $3, %edi
        call list_push_back

        movl $s_list, %edi      # list: 1 2 3
        movl $6, %esi
        call print_str
        call list_print
        call print_nl

        movl $2, %edi           # 删除值为 2 的节点
        call list_remove

        movl $s_rm, %edi        # after remove: 1 3
        movl $14, %esi
        call print_str
        call list_print
        call print_nl

        movl $4, %edi           # 复用刚释放的节点再追加 4
        call list_push_back

        movl $s_push, %edi      # after push: 1 3 4
        movl $12, %esi
        call print_str
        call list_print
        call print_nl

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
.endif
