# =============================================================================
# hash —— 模仿 tbox 的 tb_hash_t（哈希表）
# 8 个桶 + 静态节点池（8 个节点）；冲突用链地址法（头插法）
# 节点布局：+0 next、+4 key、+8 value（12 字节）；哈希函数 key & 7（即 key % 8）
# 内部调用约定同 ds/vector.s（edi/esi/edx 传参，eax 返回；被调方保存 ebx/esi/edi/ebp）
# API：
#   hash_init                      初始化（清桶 + 串空闲链）
#   hash_put  edi=key  esi=value   插入（最简实现：重复 key 会新增节点）
#   hash_get  edi=key              查找 -> eax=value（未找到返回 0）
# =============================================================================
        .lcomm htab, 32         # buckets[8]
        .lcomm hpool, 96        # 8 节点 × 12 字节
        .lcomm hfree, 4         # 空闲节点链表头
        .lcomm ibuf, 12

.data
s_hget:  .ascii "hash "
s_colon: .ascii ": "
s_miss:  .ascii "miss"
nl:      .byte 10

.text
.globl _start

# ---------------- API ----------------

# hash_init
hash_init:
        movl $htab, %ecx        # 清空 8 个桶
        movl $8, %edx
.Lhi_clear:
        movl $0, (%ecx)
        addl $4, %ecx
        decl %edx
        jnz  .Lhi_clear
        movl $hpool, %ecx       # 把 8 个节点串成空闲链
        movl $7, %edx
.Lhi_chain:
        cmpl $0, %edx
        je   .Lhi_last
        leal 12(%ecx), %eax
        movl %eax, (%ecx)       # node.next = 下一个节点
        addl $12, %ecx
        decl %edx
        jmp  .Lhi_chain
.Lhi_last:
        movl $0, (%ecx)         # 最后一个节点 next = 0
        movl $hpool, %eax
        movl %eax, hfree
        ret

# node_alloc：-> eax（池空返回 0）
node_alloc:
        movl hfree, %eax
        cmpl $0, %eax
        je   .Lhna_out
        movl (%eax), %ecx
        movl %ecx, hfree
.Lhna_out:
        ret

# hash_put：edi = key, esi = value（头插法挂到对应桶）
hash_put:
        call node_alloc
        cmpl $0, %eax
        je   .Lhp_out           # 池耗尽，忽略
        movl %edi, 4(%eax)      # node.key = key
        movl %esi, 8(%eax)      # node.value = value
        movl %edi, %ecx
        andl $7, %ecx           # 桶下标 = key & 7
        movl htab(,%ecx,4), %edx
        movl %edx, (%eax)       # node.next = 原桶头
        movl %eax, htab(,%ecx,4) # 桶头 = 新节点
.Lhp_out:
        ret

# hash_get：edi = key -> eax = value（未找到返回 0）
hash_get:
        movl %edi, %ecx
        andl $7, %ecx
        movl htab(,%ecx,4), %edx
.Lhg_loop:
        cmpl $0, %edx
        je   .Lhg_miss
        movl 4(%edx), %eax      # cur.key
        cmpl %edi, %eax
        je   .Lhg_hit
        movl (%edx), %edx       # cur = cur.next
        jmp  .Lhg_loop
.Lhg_hit:
        movl 8(%edx), %eax      # cur.value
        ret
.Lhg_miss:
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

# show_get：edi = key；打印 "hash <key>: <value|miss>"（测试辅助）
show_get:
        pushq %rdi              # 保存 key
        movl $s_hget, %edi
        movl $5, %esi
        call print_str
        popq %rdi               # 恢复 key
        pushq %rdi              # 再存一次（查表还要用）
        call print_int          # 打印 key
        movl $s_colon, %edi
        movl $2, %esi
        call print_str
        popq %rdi               # 恢复 key
        call hash_get
        cmpl $0, %eax
        je   .Lsg_miss
        movl %eax, %edi
        call print_int
        call print_nl
        ret
.Lsg_miss:
        movl $s_miss, %edi
        movl $4, %esi
        call print_str
        call print_nl
        ret

# ---------------- 测试 ----------------
# 冒烟测试：仅独立汇编时包含（as --defsym STANDALONE=1）
# 完整单元测试见 tests/hash_test.s
.ifdef STANDALONE
_start:
        call hash_init

        movl $1, %edi
        movl $11, %esi
        call hash_put
        movl $2, %edi
        movl $22, %esi
        call hash_put
        movl $9, %edi           # 9 & 7 = 1，与 key=1 同桶，验证冲突链
        movl $99, %esi
        call hash_put

        movl $1, %edi
        call show_get
        movl $2, %edi
        call show_get
        movl $9, %edi
        call show_get
        movl $3, %edi           # 从未插入 -> miss
        call show_get

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
.endif
