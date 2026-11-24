# =============================================================================
# hash_test —— ds/hash.s 的单元测试
# 断言约定：eax = 实际值, edi = 期望值
#   相等 -> "ok\n"；不等 -> "FAIL got=<实际> want=<期望>\n"
# 覆盖用例：未命中查找 / 插入后命中 / 哈希冲突链（key&7 同桶）/ 节点池耗尽
# =============================================================================
.data
t_ok:    .ascii "ok\n"
t_fail:  .ascii "FAIL got="
t_want:  .ascii " want="

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
        call hash_init

        movl $1, %edi           # T1: 未插入时 get(1) == 0（未命中）
        call hash_get
        movl $0, %edi
        call check

        movl $1, %edi           # put(1, 11)
        movl $11, %esi
        call hash_put

        movl $1, %edi           # T2: get(1) == 11
        call hash_get
        movl $11, %edi
        call check

        movl $9, %edi           # put(9, 99)：9 & 7 = 1，与 key=1 同桶（冲突）
        movl $99, %esi
        call hash_put

        movl $9, %edi           # T3: 冲突链查找 get(9) == 99
        call hash_get
        movl $99, %edi
        call check

        movl $1, %edi           # T4: 冲突后原键仍可查 get(1) == 11
        call hash_get
        movl $11, %edi
        call check

        movl $2, %edi           # put(2, 22)
        movl $22, %esi
        call hash_put

        movl $2, %edi           # T5: get(2) == 22
        call hash_get
        movl $22, %edi
        call check

        movl $3, %edi           # T6: get(3) == 0（从未插入）
        call hash_get
        movl $0, %edi
        call check

        movl $3, %edi           # 填满节点池：3 4 5 6 7（连同 1 9 2 共 8 个）
        movl $33, %esi
        call hash_put
        movl $4, %edi
        movl $44, %esi
        call hash_put
        movl $5, %edi
        movl $55, %esi
        call hash_put
        movl $6, %edi
        movl $66, %esi
        call hash_put
        movl $7, %edi
        movl $77, %esi
        call hash_put

        movl $8, %edi           # 池耗尽，put(8, 88) 被忽略
        movl $88, %esi
        call hash_put

        movl $8, %edi           # T7: get(8) == 0（没插入成功）
        call hash_get
        movl $0, %edi
        call check

        movl $9, %edi           # T8: 池满后原有键不受影响 get(9) == 99
        call hash_get
        movl $99, %edi
        call check

        movl $7, %edi           # T9: get(7) == 77
        call hash_get
        movl $77, %edi
        call check

        movl $0, %ebx           # exit(0)
        movl $1, %eax
        int  $0x80

.include "ds/hash.s"
