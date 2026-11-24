# =============================================================================
# string —— 模仿 tbox 的 tb_string_t（动态字符串）
# 静态缓冲区版本：64 字节缓冲 + 当前长度；容量不足自动截断
# 内部调用约定同 ds/vector.s（edi/esi/edx 传参，eax 返回；被调方保存 ebx/esi/edi/ebp）
# API：
#   str_init                       清空
#   str_append  edi=地址 esi=长度  追加数据（容量不足自动截断）
#   str_length                     当前长度 -> eax
#   str_at      edi=下标           取字符 -> eax（越界返回 0）
# =============================================================================
        .lcomm sbuf, 64         # 字符串缓冲区
        .lcomm slen, 4          # 当前长度
        .lcomm ibuf, 12

.data
d_hello:  .ascii "hello"        # 测试用数据片段
d_space:  .ascii " "
d_asm:    .ascii "asm"
s_str:    .ascii "str: "
s_len:    .ascii "len: "
s_char:   .ascii "char0: "
chbuf:    .byte 0               # 单字符输出缓冲
nl:       .byte 10

.text
.globl _start

# ---------------- API ----------------

# str_init
str_init:
        movl $0, slen
        ret

# str_append：edi = 数据地址, esi = 长度（容量不足自动截断）
str_append:
        pushq %rdi
        pushq %rsi
        pushq %rbx
        movl slen, %ebx         # ebx = 原长度
        movl $64, %eax
        subl %ebx, %eax         # eax = 剩余容量
        cmpl %eax, %esi
        jbe  .Lsa_fit           # 请求 <= 剩余：全部拷贝
        movl %eax, %esi         # 否则截断
.Lsa_fit:
        leal sbuf(%ebx), %edx   # 目标 = sbuf + 原长度
.Lsa_copy:
        cmpl $0, %esi
        je   .Lsa_done
        movb (%edi), %al
        movb %al, (%edx)
        incl %edi
        incl %edx
        decl %esi
        jmp  .Lsa_copy
.Lsa_done:
        movl %edx, %ecx
        subl $sbuf, %ecx        # 新长度 = 拷贝终点 - sbuf
        movl %ecx, slen
        popq %rbx
        popq %rsi
        popq %rdi
        ret

# str_length：-> eax
str_length:
        movl slen, %eax
        ret

# str_at：edi = 下标 -> eax = 字符（越界返回 0）
str_at:
        movl slen, %eax
        cmpl %eax, %edi
        jae  .Lsat_oob
        movb sbuf(%edi), %al
        movzbl %al, %eax
        ret
.Lsat_oob:
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
# 完整单元测试见 tests/string_test.s
.ifdef STANDALONE
_start:
        call str_init

        movl $d_hello, %edi     # append "hello"
        movl $5, %esi
        call str_append
        movl $d_space, %edi     # append " "
        movl $1, %esi
        call str_append
        movl $d_asm, %edi       # append "asm"
        movl $3, %esi
        call str_append

        movl $s_str, %edi       # str: hello asm
        movl $5, %esi
        call print_str
        movl $sbuf, %edi
        call str_length
        movl %eax, %esi
        call print_str
        call print_nl

        movl $s_len, %edi       # len: 9
        movl $5, %esi
        call print_str
        call str_length
        movl %eax, %edi
        call print_int
        call print_nl

        movl $s_char, %edi      # char0: h
        movl $7, %esi
        call print_str
        movl $0, %edi
        call str_at             # eax = 'h'
        movb %al, chbuf
        movl $chbuf, %edi
        movl $1, %esi
        call print_str
        call print_nl

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80
.endif
