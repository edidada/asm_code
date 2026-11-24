# AT&T 格式
# 示例 3：回显标准输入（echo）
# 功能：用 sys_read 从标准输入读取数据，再用 sys_write 原样写回标准输出
# 知识点：sys_read 系统调用、.lcomm 在 .bss 段定义未初始化缓冲区、返回值的使用

# 256 字节输入缓冲区（.lcomm 放在 .bss 段，不占可执行文件体积）
        .lcomm buf, 256

.text
.global _start

_start:
                        # 第一步：read(0, buf, 256)
       movl $256, %edx  # 参数三：最多读取的字节数
       movl $buf, %ecx  # 参数二：缓冲区地址
       movl $0,  %ebx   # 参数一：文件描述符（0 = stdin）
       movl $3,  %eax   # 系统调用号（sys_read）
       int  $0x80       # 返回值 = 实际读到的字节数，保存在 %eax

       movl %eax, %edx  # 参数三：实际读到的字节数
       movl $buf, %ecx  # 参数二：缓冲区地址
       movl $1,  %ebx   # 参数一：文件描述符（1 = stdout）
       movl $4,  %eax   # 系统调用号（sys_write）
       int  $0x80       # 把读到的内容原样写回

       movl $0,  %ebx   # 退出码 0
       movl $1,  %eax   # 系统调用号（sys_exit）
       int  $0x80       # 调用内核功能
