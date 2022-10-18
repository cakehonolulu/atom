.global get_e820_mmap

.code16

.set MEMORY_MAP, 0x0500

get_e820_mmap:
    xchg %bx, %bx
    mov $MEMORY_MAP + 8, %di // Destination Location (Add 8 to MEMORY_MAP else int15 will freeze after adding entries)
0:
    movl $1, %es:20(%di)
    mov $0x534d4150, %edx
    mov $24, %ecx
    mov $0xe820, %eax
    int $0x15
    jc mmap_err
    xchg %bx, %bx
    cmp $0x534d4150, %eax
    jne mmap_err
1:
    jcxz 3f                 // ignore if bytes=0
    cmp $20, %cl            // or "ignore" ACPI 3.x attribute is 1
    jbe 2f
    testb $1, %es:20(%di)
    jz 3f
2:
    mov %es:8(%di), %ecx    // ignore if length=0
    or %es:12(%di), %ecx
    jz 3f
    inc %bp
    add $24, %di
3:
    test %ebx, %ebx         // ebx=0 if end of list
    jnz 0b
    mov %bp, (MEMORY_MAP)
    clc
    ret


mmap_err:
    mov $0x0e, %ah
	mov $'M', %al
	int $0x10
	cli
    hlt
