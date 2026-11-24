# AT&T 格式
# 示例 4：循环打印 1 到 5
# 功能：用条件跳转实现循环，演示数字转 ASCII 字符后逐个输出
# 知识点：内存变量、cmpl/jg 条件跳转、jmp 无条件跳转、数字与 ASCII 的关系（'0' = 48）
.data
char:    .byte 0                # 待输出的数字字符（1 字节缓冲区）
newline: .byte 10               # 换行符 '\n'
counter: .long 1                # 循环计数器，从 1 开始

.text
.global _start

_start:
loop:
       movl counter, %eax    # 取出计数器
       cmpl $5, %eax         # 与 5 比较
       jg  done              # 大于 5 则循环结束

       addl $48, %eax        # 数字 + '0'(48) = 对应 ASCII 字符
       movb %al, char        # 存入输出缓冲区
       movl $1, %edx         # write(1, char, 1)
       movl $char, %ecx
       movl $1, %ebx
       movl $4, %eax
       int  $0x80

       movl $1, %edx         # write(1, newline, 1) 输出换行
       movl $newline, %ecx
       movl $1, %ebx
       movl $4, %eax
       int  $0x80

       incl counter          # 计数器 +1
       jmp  loop             # 回到循环开头

done:
       movl $0, %ebx         # exit(0)
       movl $1, %eax
       int  $0x80
