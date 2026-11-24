# AT&T 格式
# 示例 1：Hello World —— 最小的 Linux 汇编程序
# 功能：通过 sys_write 向标准输出写字符串，再通过 sys_exit 正常退出
.data    # 数据段声明
         msg : .ascii "Hello World!"           # 字符串主体（.ascii 不自动追加 NUL）
             .byte 10                          # 换行符 '\n' (LF, 0x0A)，用显式字节避免转义歧义
         len = . - msg                         # 字符串长度（含换行，共 13 字节）
.text                   # 代码段声明
.global _start          # 指定入口函数

_start:                 # 在屏幕上显示一个字符串
       movl $len, %edx  # 参数三：字符串长度
       movl $msg, %ecx  # 参数二：要显示的字符串
       movl $1, %ebx    # 参数一：文件描述符（stdout）
       movl $4, %eax    # 系统调用号（sys_write）
       int  $0x80       # 调用内核功能
                        # 退出程序
       movl $0, %ebx    # 参数一：退出代码
       movl $1, %eax    # 系统调用号（sys_exit）
       int  $0x80       # 调用内核功能
