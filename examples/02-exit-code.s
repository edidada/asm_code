# AT&T 格式
# 示例 2：自定义退出码
# 功能：不做任何输出，直接以退出码 42 结束进程
# 验证：运行后 echo $? 应为 42（CI 中通过 02-exit-code.rc 文件比对退出码）
.text                   # 代码段声明
.global _start          # 指定入口函数

_start:
       movl $42, %ebx   # 参数一：退出代码（42）
       movl $1,  %eax   # 系统调用号（sys_exit）
       int  $0x80       # 调用内核功能
