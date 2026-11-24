# AT&T 格式
# 示例 5：计算 1+2+...+10 的和并打印结果
# 功能：循环累加求和，用除法指令把多位数拆成十位/个位，转成 ASCII 输出
# 知识点：内存变量累加、divl 除法（被除数在 edx:eax，商在 eax、余数在 edx）
.data
sum:    .long 0                # 累加和
i:      .long 1                # 循环变量
digits: .byte 0, 0, 10         # 输出缓冲区：[十位][个位]['\n']

.text
.global _start

_start:
loop:
       movl i, %eax           # 取循环变量
       cmpl $10, %eax         # i > 10 ?
       jg  print              # 是则跳出循环，进入打印
       addl %eax, sum         # sum += i
       incl i                 # i++
       jmp  loop

print:
       movl sum, %eax         # eax = 55
       xorl %edx, %edx        # 清零 edx（divl 的被除数是 edx:eax）
       movl $10, %ecx
       divl %ecx              # eax = 55/10 = 5（十位），edx = 55%10 = 5（个位）

       addl $48, %eax         # 十位转 ASCII
       movb %al, digits
       movl %edx, %eax        # 个位转 ASCII
       addl $48, %eax
       movb %al, digits+1

       movl $3, %edx          # write(1, digits, 3)：两位数字 + 换行
       movl $digits, %ecx
       movl $1, %ebx
       movl $4, %eax
       int  $0x80

       movl $0, %ebx          # exit(0)
       movl $1, %eax
       int  $0x80
