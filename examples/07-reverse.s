# AT&T 格式
# 示例 7：原地反转字符串
# 功能：双指针分别指向字符串两端，向中间推进并交换字符，最后输出反转结果
# 知识点：双指针算法、8 位寄存器交换、表达式地址 $str+rlen-1
.data
str:    .ascii "abcdef"            # 待反转的字符串
rlen = . - str                    # 字符串长度 = 6
        .byte 10                   # 输出时附加的换行符（紧邻 str 之后）

.text
.global _start

_start:
       movl $str, %esi            # 左指针：第一个字符
       movl $str+rlen-1, %edi     # 右指针：最后一个字符

swap:
       cmpl %edi, %esi            # 左指针 >= 右指针 ?
       jae  print                 # 完成，跳出

       movb (%esi), %al           # 取左字符
       movb (%edi), %bl           # 取右字符
       movb %al, (%edi)           # 左字符写入右侧
       movb %bl, (%esi)           # 右字符写入左侧
       incl %esi                  # 左指针右移
       decl %edi                  # 右指针左移
       jmp  swap

print:
       movl $rlen+1, %edx         # write(1, str, 7)：6 个反转字符 + 换行
       movl $str, %ecx
       movl $1, %ebx
       movl $4, %eax
       int  $0x80

       movl $0, %ebx              # exit(0)
       movl $1, %eax
       int  $0x80
