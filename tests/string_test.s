# =============================================================================
# string_test —— ds/string.s 的单元测试
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> "ok\n"；不等 -> "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：空串长度 / 越界取字符 / 追加与长度 / 容量截断（64 字节上限）
# =============================================================================
        .lcomm xbuf, 100        # 100 字节填充缓冲（测试截断用）

.data
t_ok:    .ascii "ok\n"
t_fail:  .ascii "FAIL got="
t_want:  .ascii " want="
t_hello: .ascii "hello"
t_spasm: .ascii " asm"

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
        call str_init

        call str_length         # T1: 空串长度 == 0
        movl $0, %edi
        call check

        movl $0, %edi           # T2: 空串 at(0) == 0（越界）
        call str_at
        movl $0, %edi
        call check

        movl $t_hello, %edi     # append "hello"
        movl $5, %esi
        call str_append

        call str_length         # T3: 长度 == 5
        movl $5, %edi
        call check

        movl $0, %edi           # T4: at(0) == 'h'(104)
        call str_at
        movl $104, %edi
        call check

        movl $4, %edi           # T5: at(4) == 'o'(111)
        call str_at
        movl $111, %edi
        call check

        movl $5, %edi           # T6: at(5) 越界 == 0
        call str_at
        movl $0, %edi
        call check

        movl $t_spasm, %edi     # append " asm"（含前导空格）
        movl $4, %esi
        call str_append

        call str_length         # T7: 长度 == 9
        movl $9, %edi
        call check

        movl $5, %edi           # T8: at(5) == ' '(32)
        call str_at
        movl $32, %edi
        call check

        leal xbuf, %edi         # xbuf 填满 100 个 'x'(120)
        movl $100, %ecx
.Lsx_fill:
        movb $120, (%edi)
        incl %edi
        decl %ecx
        jnz  .Lsx_fill

        movl $xbuf, %edi        # append 100 字节 -> 只能容纳 55，截断
        movl $100, %esi
        call str_append

        call str_length         # T9: 截断后长度 == 64
        movl $64, %edi
        call check

        movl $63, %edi          # T10: at(63) == 'x'(120)
        call str_at
        movl $120, %edi
        call check

        movl $xbuf, %edi        # 已满再追加 1 字节 -> 仍为 64
        movl $1, %esi
        call str_append
        call str_length         # T11: 长度仍 == 64
        movl $64, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/string.s"
