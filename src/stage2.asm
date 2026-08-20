; ============================================================================
; stage2.asm - 纯蓝色桌面 + 十字光标 + 状态栏 (边界裁剪修复)
; ============================================================================

BITS 16
ORG 0x8000

%define SCREEN_W 320
%define SCREEN_H 200
%define VGA_SEG  0xA000
%define BACK_SEG 0x7000

start_stage2:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld

    mov ax, 0x0013
    int 0x10

    mov word [draw_seg], BACK_SEG
    call init_mouse

.main_loop:
    call poll_mouse
    call draw_desktop
    call draw_cursor
    call update_status
    call blit
    call delay_45fps
    jmp .main_loop

; ============================================================================
; 45FPS 延迟
; ============================================================================
delay_45fps:
    push ax
    push cx
    mov cx, 0x8000
.delay:
    loop .delay
    pop cx
    pop ax
    ret

; ============================================================================
; 复制后台缓冲区到屏幕
; ============================================================================
blit:
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, BACK_SEG
    mov ds, ax
    mov ax, VGA_SEG
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 320*200/2
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

; ============================================================================
; 绘制桌面 (纯蓝色)
; ============================================================================
draw_desktop:
    push es
    push di
    push ax
    push cx

    mov ax, BACK_SEG
    mov es, ax
    xor di, di
    mov al, 1
    mov cx, 320*200
    rep stosb

    ; 底部状态栏背景 (灰色)
    mov ax, 0
    mov bx, 184
    mov cx, 320
    mov dx, 16
    mov si, 7
    call fill_rect

    ; 状态栏边框 (黑色)
    mov ax, 0
    mov bx, 184
    mov cx, 320
    mov dl, 0
    call hline

    ; 状态标签
    mov si, msg_status
    mov cx, 10
    mov dx, 188
    mov bl, 0
    call draw_text

    mov si, msg_x
    mov cx, 85
    mov dx, 188
    mov bl, 0
    call draw_text

    mov si, msg_y
    mov cx, 135
    mov dx, 188
    mov bl, 0
    call draw_text

    mov si, msg_btns
    mov cx, 185
    mov dx, 188
    mov bl, 0
    call draw_text

    pop cx
    pop ax
    pop di
    pop es
    ret

; ============================================================================
; 更新状态栏
; ============================================================================
update_status:
    push ax
    push bx
    push cx
    push dx
    push si

    ; X 坐标背景
    mov ax, 100
    mov bx, 187
    mov cx, 28
    mov dx, 10
    mov si, 7
    call fill_rect

    ; Y 坐标背景
    mov ax, 150
    mov bx, 187
    mov cx, 28
    mov dx, 10
    mov si, 7
    call fill_rect

    ; 按钮区域背景
    mov ax, 210
    mov bx, 187
    mov cx, 25
    mov dx, 10
    mov si, 7
    call fill_rect

    ; X 坐标条 (红色基底)
    mov ax, 100
    mov bx, 189
    mov cx, 6
    mov dx, 6
    mov si, 4
    call fill_rect

    ; X 坐标值 (白色条)
    mov ax, [mouse_x]
    shr ax, 1
    cmp ax, 6
    jle .x_ok
    mov ax, 6
.x_ok:
    add ax, 100
    mov bx, 189
    mov cx, 2
    mov dx, 6
    mov si, 15
    call fill_rect

    ; Y 坐标条 (红色基底)
    mov ax, 150
    mov bx, 189
    mov cx, 6
    mov dx, 6
    mov si, 4
    call fill_rect

    ; Y 坐标值 (白色条)
    mov ax, [mouse_y]
    shr ax, 1
    cmp ax, 6
    jle .y_ok
    mov ax, 6
.y_ok:
    add ax, 150
    mov bx, 189
    mov cx, 2
    mov dx, 6
    mov si, 15
    call fill_rect

    ; 鼠标按键状态
    mov al, [mouse_buttons]
    test al, 1
    jz .no_l
    mov ax, 212
    mov bx, 189
    mov cx, 5
    mov dx, 6
    mov si, 4
    call fill_rect
.no_l:
    test al, 2
    jz .no_r
    mov ax, 218
    mov bx, 189
    mov cx, 5
    mov dx, 6
    mov si, 2
    call fill_rect
.no_r:
    test al, 4
    jz .no_m
    mov ax, 224
    mov bx, 189
    mov cx, 5
    mov dx, 6
    mov si, 14
    call fill_rect
.no_m:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; 绘制鼠标光标 (十字 + 完整封闭黑色边框 + 边界裁剪)
; ============================================================================
draw_cursor:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; 检查光标是否超出屏幕边界
    ; 左边界: >= 6 (光标宽度13，中心在6时左边缘在0)
    ; 右边界: <= 313 (320-7)
    ; 上边界: >= 6
    ; 下边界: <= 176 (状态栏从184开始，留8像素间距)
    mov ax, [mouse_x]
    cmp ax, 6
    jl .skip
    cmp ax, 313
    jg .skip

    mov ax, [mouse_y]
    cmp ax, 6
    jl .skip
    cmp ax, 176
    jg .skip

    ; ===== 完整黑色外框 (13x13) =====
    ; 上边框
    mov ax, [mouse_x]
    sub ax, 6
    mov bx, [mouse_y]
    sub bx, 6
    mov cx, 13
    mov dx, 1
    mov si, 0
    call fill_rect_clip

    ; 下边框
    mov ax, [mouse_x]
    sub ax, 6
    mov bx, [mouse_y]
    add bx, 6
    mov cx, 13
    mov dx, 1
    mov si, 0
    call fill_rect_clip

    ; 左边框
    mov ax, [mouse_x]
    sub ax, 6
    mov bx, [mouse_y]
    sub bx, 5
    mov cx, 1
    mov dx, 11
    mov si, 0
    call fill_rect_clip

    ; 右边框
    mov ax, [mouse_x]
    add ax, 6
    mov bx, [mouse_y]
    sub bx, 5
    mov cx, 1
    mov dx, 11
    mov si, 0
    call fill_rect_clip

    ; ===== 白色十字主体 =====
    ; 水平线
    mov ax, [mouse_x]
    sub ax, 4
    mov bx, [mouse_y]
    mov cx, 9
    mov dx, 1
    mov si, 15
    call fill_rect_clip

    ; 垂直线
    mov ax, [mouse_x]
    mov bx, [mouse_y]
    sub bx, 4
    mov cx, 1
    mov dx, 9
    mov si, 15
    call fill_rect_clip

    ; ===== 中心黑色方块 (3x3) =====
    mov ax, [mouse_x]
    sub ax, 1
    mov bx, [mouse_y]
    sub bx, 1
    mov cx, 3
    mov dx, 3
    mov si, 0
    call fill_rect_clip

.skip:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; 带裁剪的矩形填充 (自动裁剪到屏幕边界)
; ============================================================================
fill_rect_clip:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    ; 保存参数到变量
    mov [rect_x], ax
    mov [rect_y], bx
    mov [rect_w], cx
    mov [rect_h], dx
    mov [rect_color], si

    ; ===== 左裁剪 =====
    mov ax, [rect_x]
    cmp ax, 0
    jge .check_right
    neg ax
    sub [rect_w], ax
    mov word [rect_x], 0
    cmp word [rect_w], 0
    jle .done

.check_right:
    mov ax, [rect_x]
    add ax, [rect_w]
    cmp ax, 320
    jle .check_top
    sub ax, 320
    sub [rect_w], ax
    cmp word [rect_w], 0
    jle .done

.check_top:
    mov ax, [rect_y]
    cmp ax, 0
    jge .check_bottom
    neg ax
    sub [rect_h], ax
    mov word [rect_y], 0
    cmp word [rect_h], 0
    jle .done

.check_bottom:
    mov ax, [rect_y]
    add ax, [rect_h]
    cmp ax, 200
    jle .draw
    sub ax, 200
    sub [rect_h], ax
    cmp word [rect_h], 0
    jle .done

.draw:
    ; 执行实际绘制
    mov ax, [draw_seg]
    mov es, ax

    xor bp, bp
.row:
    cmp bp, [rect_h]
    jae .done
    mov bx, [rect_y]
    add bx, bp
    mov di, bx
    mov ax, bx
    shl di, 6
    shl ax, 8
    add di, ax
    add di, [rect_x]
    mov cx, [rect_w]
    mov al, [rect_color]
    rep stosb
    inc bp
    jmp .row

.done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; 图形函数 (无裁剪，用于绘制已知在屏幕内的元素)
; ============================================================================
fill_rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov [rect_x], ax
    mov [rect_y], bx
    mov [rect_w], cx
    mov [rect_h], dx
    mov [rect_color], si

    mov ax, [draw_seg]
    mov es, ax

    xor bp, bp
.row:
    cmp bp, [rect_h]
    jae .done
    mov bx, [rect_y]
    add bx, bp
    cmp bx, 200
    jae .next
    mov di, bx
    mov ax, bx
    shl di, 6
    shl ax, 8
    add di, ax
    add di, [rect_x]
    mov cx, [rect_w]
    mov al, [rect_color]
    rep stosb
.next:
    inc bp
    jmp .row
.done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

hline:
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    cmp bx, 200
    jae .done
    mov di, bx
    mov ax, bx
    shl di, 6
    shl ax, 8
    add di, ax
    add di, [rect_x]
    mov ax, [draw_seg]
    mov es, ax
    mov al, dl
    rep stosb
.done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

vline:
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov di, bx
    mov ax, bx
    shl di, 6
    shl ax, 8
    add di, ax
    add di, [rect_x]
    mov ax, [draw_seg]
    mov es, ax
    mov al, dl
.loop:
    cmp cx, 0
    je .done
    mov es:[di], al
    add di, 320
    dec cx
    jmp .loop
.done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; 字符绘制
; ============================================================================
draw_char:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    push fs

    mov [char_code], al
    mov [char_x], cx
    mov [char_y], dx
    mov [char_color], bl

    mov ax, 0x1130
    mov bh, 0x03
    int 0x10

    xor ah, ah
    mov al, [char_code]
    shl ax, 3
    add ax, bp
    mov si, ax
    mov ax, es
    mov fs, ax

    mov ax, [draw_seg]
    mov es, ax

    xor bp, bp
.row:
    cmp bp, 8
    jae .done
    mov bl, fs:[si+bp]
    mov ax, [char_y]
    add ax, bp
    mov di, ax
    mov dx, ax
    shl di, 6
    shl dx, 8
    add di, dx
    add di, [char_x]
    mov dl, 0x80
    mov cx, 8
.bit:
    test bl, dl
    jz .skip
    mov al, [char_color]
    mov es:[di], al
.skip:
    inc di
    shr dl, 1
    loop .bit
    inc bp
    jmp .row
.done:
    pop fs
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_text:
    push ax
    push cx
    push dx
    push si
.next:
    lodsb
    test al, al
    jz .done
    call draw_char
    add cx, 8
    jmp .next
.done:
    pop si
    pop dx
    pop cx
    pop ax
    ret

; ============================================================================
; PS/2 鼠标驱动
; ============================================================================
mouse_x         dw 160
mouse_y         dw 100
mouse_buttons   db 0

ps2_pktcnt      db 0
ps2_pkt         times 4 db 0
draw_seg        dw BACK_SEG

init_mouse:
    call ps2_flush

    call ps2_wait_input
    jc .done
    mov al, 0xA8
    out 0x64, al

    mov al, 0xF6
    call ps2_send

    mov al, 0xF4
    call ps2_send

.done:
    ret

ps2_wait_input:
    push cx
    mov cx, 0xFFFF
.loop:
    in al, 0x64
    test al, 2
    jz .ok
    loop .loop
    pop cx
    stc
    ret
.ok:
    pop cx
    clc
    ret

ps2_wait_output:
    push cx
    mov cx, 0xFFFF
.loop:
    in al, 0x64
    test al, 1
    jnz .ok
    loop .loop
    pop cx
    stc
    ret
.ok:
    pop cx
    clc
    ret

ps2_flush:
    push ax
    push cx
    mov cx, 50
.loop:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    in al, 0x60
    loop .loop
.done:
    pop cx
    pop ax
    ret

ps2_write:
    push bx
    mov bl, al
    call ps2_wait_input
    jc .fail
    mov al, 0xD4
    out 0x64, al
    call ps2_wait_input
    jc .fail
    mov al, bl
    out 0x60, al
    pop bx
    clc
    ret
.fail:
    pop bx
    stc
    ret

ps2_read_ack:
    call ps2_wait_output
    jc .fail
    in al, 0x60
    cmp al, 0xFA
    jne .fail
    clc
    ret
.fail:
    stc
    ret

ps2_send:
    call ps2_write
    jc .fail
    call ps2_read_ack
.fail:
    ret

poll_mouse:
    push ax
    push bx
    push cx
    push dx

.loop:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    in al, 0x60

    mov bl, [ps2_pktcnt]
    mov [ps2_pkt+bx], al
    inc byte [ps2_pktcnt]

    cmp byte [ps2_pktcnt], 1
    jne .check
    test al, 0x08
    jnz .check
    mov byte [ps2_pktcnt], 0
    jmp .loop

.check:
    cmp byte [ps2_pktcnt], 3
    jb .loop

    mov byte [ps2_pktcnt], 0

    mov al, [ps2_pkt]
    test al, 0xC0
    jnz .loop

    mov al, [ps2_pkt+1]
    cbw
    add [mouse_x], ax

    mov al, [ps2_pkt+2]
    cbw
    sub [mouse_y], ax

    cmp word [mouse_x], 0
    jge .x_ok
    mov word [mouse_x], 0
.x_ok:
    cmp word [mouse_x], 319
    jle .y_ok
    mov word [mouse_x], 319
.y_ok:
    cmp word [mouse_y], 0
    jge .y_ok2
    mov word [mouse_y], 0
.y_ok2:
    cmp word [mouse_y], 199
    jle .buttons
    mov word [mouse_y], 199

.buttons:
    xor al, al
    mov bl, [ps2_pkt]
    test bl, 1
    jz .no_l
    or al, 1
.no_l:
    test bl, 2
    jz .no_r
    or al, 2
.no_r:
    test bl, 4
    jz .no_m
    or al, 4
.no_m:
    mov [mouse_buttons], al

    jmp .loop

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; 数据区
; ============================================================================
rect_x          dw 0
rect_y          dw 0
rect_w          dw 0
rect_h          dw 0
rect_color      db 0
char_code       db 0
char_color      db 0
char_x          dw 0
char_y          dw 0

msg_status      db 'Mouse:',0
msg_x           db 'X:',0
msg_y           db 'Y:',0
msg_btns        db 'Btns:',0