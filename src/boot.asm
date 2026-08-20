; ============================================================================
; boot.asm - 引导扇区
; ============================================================================

BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld

    ; 加载第二阶段到 0x0000:0x8000
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x8000

    mov ah, 0x02
    mov al, 30
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80
    int 0x13
    jc error

    jmp 0x0000:0x8000

error:
    mov al, 'E'
    mov ah, 0x0E
    int 0x10
    cli
    hlt
    jmp error

times 510-($-$$) db 0
dw 0xAA55