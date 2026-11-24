# AT&T 格式
# 示例 6：把字符串里的小写字母转成大写后输出
# 功能：逐字节扫描字符串，条件判断 + 字符运算（同一字母大小写 ASCII 相差 32）
# 知识点：寄存器间接寻址 (%esi)、无符号比较 jb/ja、8 位字符处理
.data
str:    .ascii "Hello, ASM! 123"   # 待处理的字符串
        .byte 10                   # 结尾换行符
len = . - str                     # 总长度 = 16

.text
.global _start

_start:
       movl $str, %esi            # esi = 当前字符地址（从左端开始）
       movl $str+len, %edi        # edi = 结束地址（右端）

next:
       cmpl %edi, %esi            # 比较 esi 与 edi（esi - edi）
       jae  print                 # 左指针到达结束地址：扫描完成

       movb (%esi), %al           # 取当前字符
       cmpb $97, %al              # < 'a' (97) ?
       jb   store                 # 不是小写字母，跳过转换
       cmpb $122, %al             # > 'z' (122) ?
       ja   store                 # 不是小写字母，跳过转换
       subb $32, %al              # 小写 -> 大写（ASCII 差 32）

store:
       movb %al, (%esi)           # 写回原位置
       incl %esi                  # 移动到下一个字符
       jmp  next

print:
       movl $len, %edx            # write(1, str, len)
       movl $str, %ecx
       movl $1, %ebx
       movl $4, %eax
       int  $0x80

       movl $0, %ebx              # exit(0)
       movl $1, %eax
       int  $0x80
