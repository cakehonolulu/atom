bits 32

global enablePaging
global loadPageDirectory


enablePaging:
    mov cr3, eax    ;eax contains the register of page directory
    
    mov ebx, cr4    ;read cr4
    or ebx, 0x00000010 ; set PSE
    mov cr4, ebx

    mov ebx, cr0
    or ebx, 0x80000001 ; set PG
    mov cr0, ebx    ;;update ebx
    ret

loadPageDirectory:
    mov eax, [esp + 4]
    mov cr3, eax ;load address of page directory to eax
    ret