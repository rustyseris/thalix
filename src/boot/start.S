# EXPORTS
global _start
global multiboot_header_address

section .multiboot_header
align 32
header_start:
    dd 0xe85250d6       ; multiboot magic
    dd 0                ; arch x86_64
    dd header_end - header_start
    dd 0x100000000 - (0xe85250d6 + header_end - header_start)
header_end:


section .data
align 32
multiboot_header_address: dd 0


section .initdata.early_stack
align 4096
early_stack_end:
    times 4096 db 0
early_stack_start:


section .initdata.gdt
align 32
gdt_table:
    .null: equ $-gdt_table
        dq 0
    .code: equ $-gdt_table
        dw 0 ; segment[0:15]
        dw 0 ; base[0:15]
        db 0 ; base[16:23]
        db 0b10011010
        db 0b11100000
        db 0 ; base[24:31]
    .data: equ $-gdt_table
        dw 0 ; segment[0:15]
        dw 0 ; base[0:15]
        db 0 ; base[16:23]
        db 0b10010010
        db 0b11100000
        db 0 ; base[24:31]
    .pointer:
        dw $ - gdt_table - 1
        dq gdt_table

section .initdata.errors
align 32
no_multiboot: db "Bootloader doesn't support multiboot2", 0
no_long_mode: db "Long mode (x86_64) is not available", 0
error_die: db "I'm dying :c", 0

section .text
bits 32
_start:
    cli
    cld
    
    ; stack setup
    mov ebp, early_stack_start
    mov esp, ebp

    ; check multiboot
    cmp eax, 0x36d76289
    mov ebx, no_long_mode
    jne early_error

    ; save multiboot header for rust
    mov [multiboot_header_address], ebx

    ; check if long mode is available
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000000
    mov ebx, no_long_mode
    jbe early_error

setup_gdt:
    ; setup gdt
    lgdt [gdt_table.pointer]
    jmp gdt_table.code:enable_paging

enable_paging:
    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax
    mov eax, cr4

enable_long_mode:
    mov ecx, 0xc0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    mov ebx, error_die

early_error:
    mov esi, 0
    mov ah, 4
    .loop:
        mov al, [ebx + esi]
        cmp al, 0
        je die
        mov [0xb8000 + esi*2], ax
        inc esi
        jmp .loop

die:
    hlt
    jmp die

