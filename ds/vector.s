# =============================================================================
# vector —— 模仿 tbox 的 tb_vector_t（动态数组）
# 无 libc 环境：用 .bss 静态内存池实现固定容量（16 个 32 位元素）版本
#
# 统一内部调用约定（ds/ 下所有文件相同）：
#   参数：edi = 参数1, esi = 参数2, edx = 参数3
#   返回：eax
#   被调方可破坏 eax/ecx/edx；必须保存 ebx/esi/edi/ebp
#   （int $0x80 本身会保存/恢复除 eax 外的全部寄存器，只有 eax 是返回值）
#
# API：
#   vector_init                 初始化（清空）
#   vector_push   edi=值        尾部追加（容量满则忽略）
#   vector_pop                  弹出尾部元素 -> eax（空向量返回 0）
#   vector_at     edi=下标      取元素 -> eax（越界返回 0）
#   vector_size                 元素个数 -> eax
# =============================================================================

# ---- 数据结构（静态内存池）----
        .lcomm vec_data, 64     # 元素数组：16 个 32 位元素
        .lcomm vec_size, 4      # 当前元素个数
        .lcomm ibuf, 12         # print_int 的数字转字符串缓冲区

.data
s_vsize:  .ascii "vector size: "
s_vdata:  .ascii "vector data: "
s_vpop:   .ascii "pop: "
s_vafter: .ascii "size after pop: "
s_space:  .ascii " "
nl:       .byte 10

.text
.globl _start

# ---------------- API ----------------

# vector_init：清空向量
vector_init:
        movl $0, vec_size
        ret

# vector_push：edi = 待追加的值
vector_push:
        movl vec_size, %eax
        cmpl $16, %eax          # 容量满？
        jae  .Lvp_full
        movl %edi, vec_data(,%eax,4)   # vec_data[size] = val
        incl vec_size
.Lvp_full:
        ret

# vector_pop：弹出尾部元素，返回值在 eax（空向量返回 0）
vector_pop:
        movl vec_size, %ecx
        cmpl $0, %ecx
        je   .Lvpop_empty
        subl $1, %ecx           # ecx = 尾元素下标
        movl %ecx, vec_size     # size--
        movl vec_data(,%ecx,4), %eax
        ret
.Lvpop_empty:
        movl $0, %eax
        ret

# vector_at：edi = 下标，返回元素（越界返回 0）
vector_at:
        movl vec_size, %eax
        cmpl %eax, %edi         # i >= size ?
        jae  .Lvat_oob
        movl vec_data(,%edi,4), %eax
        ret
.Lvat_oob:
        movl $0, %eax
        ret

# vector_size：返回元素个数
vector_size:
        movl vec_size, %eax
        ret

# ---------------- 工具函数 ----------------
# 注意：ebx 是约定中"被调方必须保存"的寄存器，而输出函数要往 ebx 里放
# stdout 文件描述符 1，因此三个输出函数都用 pushq/popq 保存恢复 ebx。

# print_str：edi = 字符串地址, esi = 长度
print_str:
        pushq %rbx
        movl %edi, %ecx
        movl %esi, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        ret

# print_nl：输出换行
print_nl:
        pushq %rbx
        movl $nl, %ecx
        movl $1, %edx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        ret

# print_int：edi = 无符号数，输出其十进制形式（不含换行）
print_int:
        pushq %rsi              # 本函数用到 esi，按约定保存
        pushq %rbx              # 本函数用到 ebx，按约定保存
        movl %edi, %eax
        leal ibuf+11, %esi      # 从缓冲区末尾向前填数字
        cmpl $0, %eax
        jne  .Lpi_digit
        movb $48, (%esi)        # 值为 0：直接输出 '0'
        subl $1, %esi
        jmp  .Lpi_out
.Lpi_digit:
        cmpl $0, %eax
        je   .Lpi_out
        xorl %edx, %edx
        movl $10, %ecx
        divl %ecx               # eax=商, edx=余数
        addl $48, %edx
        movb %dl, (%esi)
        subl $1, %esi
        jmp  .Lpi_digit
.Lpi_out:
        incl %esi               # 回到第一个数字
        movl $ibuf+12, %edx
        subl %esi, %edx         # 长度 = 缓冲区尾 - 起点
        movl %esi, %ecx
        movl $1, %ebx
        movl $4, %eax
        int  $0x80
        popq %rbx
        popq %rsi
        ret

# ---------------- 测试 ----------------
_start:
        call vector_init

        movl $10, %edi
        call vector_push
        movl $20, %edi
        call vector_push
        movl $30, %edi
        call vector_push
        movl $40, %edi
        call vector_push

        movl $s_vsize, %edi     # vector size: 4
        movl $13, %esi
        call print_str
        call vector_size
        movl %eax, %edi
        call print_int
        call print_nl

        movl $s_vdata, %edi     # vector data: 10 20 30 40
        movl $13, %esi
        call print_str
        movl $0, %ebx
.Lvdata:
        cmpl vec_size, %ebx
        jae  .Lvdata_done
        cmpl $0, %ebx           # 第一个元素前不打印空格
        je   .Lvdata_nosp
        movl $s_space, %edi
        movl $1, %esi
        call print_str
.Lvdata_nosp:
        movl %ebx, %edi
        call vector_at
        movl %eax, %edi
        call print_int
        incl %ebx
        jmp  .Lvdata
.Lvdata_done:
        call print_nl

        movl $s_vpop, %edi      # pop: 40
        movl $5, %esi
        call print_str
        call vector_pop
        movl %eax, %edi
        call print_int
        call print_nl

        movl $s_vafter, %edi    # size after pop: 3
        movl $16, %esi
        call print_str
        call vector_size
        movl %eax, %edi
        call print_int
        call print_nl

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
