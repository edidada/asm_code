# =============================================================================
# queue —— 模仿 tbox 的 tb_queue_t（队列/环形缓冲，先进先出 FIFO）
# 8 槽环形缓冲：que_head 出队位置、que_tail 入队位置、que_count 当前元素数
# 内部调用约定同 ds/vector.s（edi/esi/edx 传参，eax 返回；被调方保存 ebx/esi/edi/ebp）
# API：
#   queue_init          初始化
#   queue_push  edi=值  入队（满则忽略）
#   queue_pop           出队 -> eax（空返回 0）
# =============================================================================
        .lcomm que_data, 32     # 8 个 32 位元素
        .lcomm que_head, 4      # 出队下标
        .lcomm que_tail, 4      # 入队下标
        .lcomm que_count, 4     # 当前元素个数
        .lcomm ibuf, 12

.data
s_qpop:   .ascii "queue pops: "
s_qwrap:  .ascii "queue wraps: "
s_space:  .ascii " "
nl:       .byte 10

.text
.globl _start

# ---------------- API ----------------

queue_init:
        movl $0, que_head
        movl $0, que_tail
        movl $0, que_count
        ret

# queue_push：edi = 值
queue_push:
        movl que_count, %eax
        cmpl $8, %eax
        jae  .Lqp_full          # 队满忽略
        movl que_tail, %ecx
        movl %edi, que_data(,%ecx,4)
        incl que_tail
        cmpl $8, que_tail       # 环形：越过尾部回绕到 0
        jb   .Lqp_nowrap
        movl $0, que_tail
.Lqp_nowrap:
        incl que_count
.Lqp_full:
        ret

# queue_pop：-> eax
queue_pop:
        movl que_count, %eax
        cmpl $0, %eax
        je   .Lqo_empty
        movl que_head, %ecx
        movl que_data(,%ecx,4), %eax
        incl que_head
        cmpl $8, que_head
        jb   .Lqo_nowrap
        movl $0, que_head
.Lqo_nowrap:
        decl que_count
        ret
.Lqo_empty:
        movl $0, %eax
        ret

# ---------------- 工具函数 ----------------

# print_str：edi = 地址, esi = 长度
print_str:
        movl %edi, %ecx
        movl %esi, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        ret

# print_nl
print_nl:
        movl $nl, %ecx
        movl $1, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        ret

# print_int：edi = 无符号数
print_int:
        pushq %rsi
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
        popq %rsi
        ret

# ---------------- 测试 ----------------
_start:
        call queue_init
        movl $1, %edi
        call queue_push
        movl $2, %edi
        call queue_push
        movl $3, %edi
        call queue_push

        movl $s_qpop, %edi      # queue pops: 1 2 3
        movl $12, %esi
        call print_str
        movl $3, %ebx
.Lqa:
        cmpl $0, %ebx
        je   .Lqa_done
        call queue_pop
        movl %eax, %edi
        call print_int
        cmpl $1, %ebx
        je   .Lqa_nosp
        movl $s_space, %edi
        movl $1, %esi
        call print_str
.Lqa_nosp:
        decl %ebx
        jmp  .Lqa
.Lqa_done:
        call print_nl

        movl $6, %edi           # 继续入队 6 7 8，tail 越过尾部发生回绕
        call queue_push
        movl $7, %edi
        call queue_push
        movl $8, %edi
        call queue_push

        movl $s_qwrap, %edi     # queue wraps: 4 5 6 7 8
        movl $13, %esi
        call print_str
        movl $5, %ebx
.Lqb:
        cmpl $0, %ebx
        je   .Lqb_done
        call queue_pop
        movl %eax, %edi
        call print_int
        cmpl $1, %ebx
        je   .Lqb_nosp
        movl $s_space, %edi
        movl $1, %esi
        call print_str
.Lqb_nosp:
        decl %ebx
        jmp  .Lqb
.Lqb_done:
        call print_nl

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
