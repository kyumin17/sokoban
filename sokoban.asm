org 100h
jmp start

section .data
    title_str db "SOKOBAN"
    start_str db "START"
    exit_str db "EXIT"
    complete_str db "COMPLETE"
    
    map_file_path db "map/"
    level_str db "lv"
    level_num_str db "00"
    db ".bin", 0
    level_file_path db "data/level.bin", 0
    img_file_path db "data/image.bin", 0
    title_file_path db "data/title.bin", 0

    width equ 320
    height equ 200
    cell_size equ 16

    enter_key equ 0Dh
    up_key equ 48h
    down_key equ 50h
    right_key equ 4Dh
    left_key equ 4Bh

    target equ 1
    box equ 2
    target_box equ 3
    wall equ 4

section .bss
    fp: resw 1
    number: resw 1
    buffer: resb 256
    buffer2: resb 256
    clear_level: resw 1
    level: resw 1

    player_img: resb 68
    target_img: resb 68
    box_img: resb 68
    wall_img: resb 68
    ground_img: resb 68

    map_width: resb 1
    map_height: resb 1
    player_x: resb 1
    player_y: resb 1
    map: resb 200
    box_number: resb 1

section .text
;;;;;;;;;;define;;;;;;;;;;
%define arg1 [bp+4]
%define arg2 [bp+6]
%define arg3 [bp+8]
%define arg4 [bp+10]
%define arg5 [bp+12]

;;;;;;;;;;macro;;;;;;;;;;
%macro BEGIN 0
    push bp
    mov bp, sp
%endmacro
%macro END 1
    leave
    ret %1
%endmacro
%macro CALL_SYS 2
    mov ax, %2
    int %1
%endmacro
%macro CALL_FN 1-6
    %if %0 > 5
    push %6
    %endif
    %if %0 > 4
    push %5
    %endif
    %if %0 > 3
    push %4
    %endif
    %if %0 > 2
    push %3
    %endif
    %if %0 > 1
    push %2
    %endif
    call %1
%endmacro
%macro PUSH_REG 2-4
    push %1
    push %2
    %if %0 > 2
    push %3
    %endif
    %if %0 > 3
    push %4
    %endif
%endmacro
%macro POP_REG 2-4
    %if %0 > 3
    pop %4
    %endif
    %if %0 > 2
    pop %3
    %endif
    pop %2
    pop %1
%endmacro
%macro LOAD_FILE 3
    CALL_FN open_file, %1
    CALL_FN read_file, %2, %3
    CALL_FN close_file
%endmacro
%macro CJNE 3
    cmp %1, %2
    jne %3
%endmacro
%macro CJE 3
    cmp %1, %2
    je %3
%endmacro
%macro MOV_VAL 2
    mov ax, %2
    mov %1, ax
%endmacro

;;;;;;;;;;start;;;;;;;;;;
start:
    CALL_SYS 10h, 13h
    MOV_VAL es, 0A000h
    LOAD_FILE level_file_path, clear_level, 1
    LOAD_FILE img_file_path, player_img, 68*4
    mov byte [ground_img], 25
    call start_page
    CALL_SYS 10h, 3h
    CALL_SYS 21h, 4C00h

;;;;;;;;;;page;;;;;;;;;;
start_page:
    BEGIN
    call draw_start_background
    CALL_FN draw_string, 16, 6, title_str, 7, 0
    CALL_FN draw_string, 17, 13, start_str, 5, 0
    CALL_FN draw_string, 17, 15, exit_str, 4, 0
    mov bx, 13
.get_key:
    push bx
    mov cx, 28
    sub cx, bx
    push cx
    CALL_FN draw_letter, 15, bx, '>', 0
    pop cx
    CALL_FN draw_letter, 15, cx, 219, 43
    CALL_SYS 16h, 0h
    pop bx
    CJE al, enter_key, .select_menu
    CJNE ah, up_key, .check_down
    mov bl, 13
.check_down:
    CJNE ah, down_key, .get_key
    mov bl, 15
    jmp .get_key
.select_menu:
    CJE bl, 15, .exit
    call clear_screen
    call menu_page
.exit:
    END 0

menu_page:
    BEGIN
    CALL_FN draw_string, 16, 2, title_str, 7, 15
    CALL_SYS 16h, 0h
    MOV_VAL [level], [clear_level]
    call clear_screen
    call game_page
    END 0

game_page:
    BEGIN
    CALL_FN int_to_str, word [level], level_num_str
    call load_map
    call draw_map
    CALL_FN draw_string, 1, 1, level_str, 4, 15
.update:
    movzx bx, byte [player_x]
    movzx dx, byte [player_y]
    PUSH_REG bx, dx
    CALL_FN draw_map_shape, bx, dx, player_img
    CJE byte [box_number], 0, .complete
    CALL_SYS 16h, 0h
    CJE al, enter_key, .exit
    POP_REG bx, dx
    call play_turn
    jmp .update
.complete:
    call complete_page
.exit:
    END 0

complete_page:
    BEGIN
    CALL_FN draw_string, 16, 10, complete_str, 8
    CALL_SYS 16h, 0h
    END 0

;;;;;;;;;;util;;;;;;;;;;
draw_shape: ;(x, y, buf)
    BEGIN
    mov bx, arg3
    mov cx, 2
    xor si, si
.load_color:
    MOV_VAL [buffer+si], [bx+si]
    add si, 2
    loop .load_color
    mov di, arg2
    imul di, width
    add di, arg1
    shl di, 4
    add di, width*8
    xor dl, dl
.outer_loop:
    mov cx, cell_size/4
    push dx
.inner_loop:
    mov dh, [bx+si]
    xor dl, dl
    push si
    xor ax, ax
.third_loop:
    mov al, dh
    and al, 3
    mov si, buffer
    add si, ax
    mov al, [si]
    CJE al, 255, .skip_draw
    mov [es:di], al
.skip_draw:
    inc di
    inc dl
    shr dh, 2
    CJNE dl, 4, .third_loop
    pop si
    inc si
    loop .inner_loop
    add di, width-cell_size
    pop dx
    inc dl
    CJNE dl, cell_size, .outer_loop
    END 6

draw_map_shape: ;(x, y, buf)
    BEGIN
    mov ax, 20
    sub ax, [map_width]
    shr ax, 1
    add ax, arg1
    mov bx, 13
    sub bx, [map_height]
    shr bx, 1
    add bx, arg2
    inc bx
    CALL_FN draw_shape, ax, bx, word arg3
    END 6

draw_string: ;(x, y, msg, len, color)
    BEGIN
    xor si, si
    mov dx, arg1
    mov cx, arg4
.loop:
    mov bx, arg3
    add bx, si
    movzx ax, byte [bx]
    PUSH_REG si, cx, dx
    CALL_FN draw_letter, dx, word arg2, ax, word arg5
    POP_REG si, cx, dx
    inc dx
    inc si
    loop .loop
    END 8

draw_letter: ;(x, y, char, color)
    BEGIN
    mov si, arg3
    shl si, 3
    push ds
    PUSH_REG es, bp
    mov ax, 1130h
    mov bh, 3h
    int 10h
    MOV_VAL ds, es
    add si, bp
    POP_REG es, bp
    mov di, arg2
    imul di, width
    add di, arg1
    shl di, 3
    mov cx, 8
.outer_loop:
    mov al, [ds:si]
    mov bx, 0
.inner_loop:
    mov ah, al
    and ah, 128
    CJE ah, 0, .skip_draw
    push ax
    mov al, byte arg4
    mov [es:di], al
    pop ax
.skip_draw:
    shl al, 1
    inc bx
    inc di
    CJNE bx, 8, .inner_loop
    add di, width-8
    inc si
    loop .outer_loop
    pop ds
    END 8

draw_start_background:
    BEGIN
    mov ax, 0A000h
    mov es, ax
    xor di, di
    mov cx, width*height/2
    sub cx, width*24
    mov al, 43
    mov ah, al
    rep stosw
    mov cx, width/2
    mov al, 0
    mov ah, al
    rep stosw
    mov cx, 47*width/2
    mov al, 25
    mov ah, al
    rep stosw
    CALL_FN open_file, title_file_path
    mov [number], word 0
    xor di, di
    mov dx, player_img
.outer_loop:
    push dx
    CALL_FN read_file, number, 1
    CALL_FN read_file, buffer2, word [number]
    pop dx
    movzx cx, byte [number]
    xor si, si
.inner_loop:
    movzx ax, byte [buffer2+si]
    mov bl, 20
    div bl
    movzx bx, al
    push dx
    mov dl, ah
    movzx ax, dl
    pop dx
    PUSH_REG cx, si, dx, di
    CALL_FN draw_shape, ax, bx, dx
    POP_REG cx, si, dx, di
    inc si
    loop .inner_loop
    mov dx, box_img
    inc di
    CJE di, 1, .outer_loop
    call close_file
    END 0

load_map:
    BEGIN
    mov byte [box_number], 0
    mov word [number], 0
    CALL_FN open_file, map_file_path
    CALL_FN read_file, map_width, 4
    movzx ax, byte [map_width]
    movzx bx, byte [map_height]
    imul ax, bx
    shr ax, 2
    push ax
    CALL_FN read_file, buffer, ax
    pop ax
    mov cx, ax
    xor si, si
    xor bx, bx
.outer_loop:
    xor dx, dx
    mov al, byte [buffer+si]
.inner_loop:
    mov ah, al
    and ah, 3
    CJNE ah, 3, .skip_wall
    mov [map+bx], byte 4
    jmp .skip_all
.skip_wall:
    CJNE ah, 2, .skip_box
    inc byte [box_number]
.skip_box:
    mov [map+bx], ah
.skip_all:
    shr al, 2
    inc bx
    inc dx
    CJNE dx, 4, .inner_loop
    inc si
    loop .outer_loop
    CALL_FN close_file
    END 0

draw_map:
    BEGIN
    ;background
    mov cx, width*height/2
    xor di, di
.draw_background:
    mov al, 25
    mov ah, 25
    mov [es:di], ax
    add di, 2
    loop .draw_background
    ;object
    movzx cx, byte [map_width]
    movzx ax, byte [map_height]
    imul cx, ax
    xor ax, ax
    xor bx, bx
    xor si, si
.loop_obj:
    CJNE al, byte [map_width], .draw
    xor ax, ax
    inc bx
.draw:
    PUSH_REG ax, bx, cx, dx
    push si
    mov cl, byte [map+si]
    CJNE cl, target, .box
    mov dx, target_img
    jmp .skip_all
.box:
    CJNE cl, box, .wall
    mov dx, box_img
    jmp .skip_all
.wall:
    CJNE cl, wall, .skip_draw
    mov dx, wall_img
    jmp .skip_all
.skip_all:
    CALL_FN draw_map_shape, ax, bx, dx
.skip_draw:
    pop si
    POP_REG ax, bx, cx, dx
    inc ax
    inc si
    loop .loop_obj
    END 0

draw_map_cell: ;(idx)
    BEGIN
    mov ax, arg1
    mov cl, byte [map_width]
    div cl
    movzx cx, al
    movzx ax, ah
    PUSH_REG ax, cx
    CALL_FN draw_map_shape, ax, cx, ground_img
    POP_REG ax, cx
    mov bx, map
    add bx, arg1
    movzx bx, byte [bx]
    CJNE bx, target, .box
    mov dx, target_img
    jmp .draw
.box:
    CJNE bx, box, .target_box
    mov [box_img+1], byte 6
    mov [box_img+2], byte 114
    mov [box_img+3], byte 186
    mov dx, box_img
    jmp .draw
.target_box:
    CJNE bx, target_box, .wall
    mov [box_img+1], byte 42
    mov [box_img+2], byte 6
    mov [box_img+3], byte 114
    mov dx, box_img
    jmp .draw
.wall:
    CJNE bx, wall, .exit
    mov dx, wall_img
    jmp .draw
.draw:
    CALL_FN draw_map_shape, ax, cx, dx
.exit:
    END 2

play_turn:
    BEGIN
    movzx bx, byte [player_y]
    movzx cx, byte [map_width]
    imul bx, cx
    movzx cx, byte [player_x]
    add bx, cx
    xor si, si
    CJNE ah, up_key, .down
    movzx si, byte [map_width]
    imul si, -1
    jmp .skip_all
.down:
    CJNE ah, down_key, .left
    movzx si, byte [map_width]
    jmp .skip_all
.left:
    CJNE ah, left_key, .right
    dec si
    jmp .skip_all
.right:
    CJNE ah, right_key, .skip_all
    inc si
    jmp .skip_all
.skip_all:
    mov di, si
    shl di, 1
    CJE byte [map+bx+si], wall, .exit
    cmp byte [map+bx+si], target
    jle .move_player
    cmp byte [map+bx+di], target
    jle .move_box
    jmp .exit
.move_box:
    CJNE byte [map+bx+di], 1, .inc_box_num
    dec byte [box_number]
.inc_box_num:
    CJNE byte [map+bx+si], 3, .update_box
    inc byte [box_number]
.update_box:
    add byte [map+bx+di], box
    sub byte [map+bx+si], box
    mov dx, bx
    add dx, di
    PUSH_REG ax, bx, si
    CALL_FN draw_map_cell, dx
    POP_REG ax, bx, si
.move_player:
    PUSH_REG ax, bx, si
    CALL_FN draw_map_cell, bx
    POP_REG ax, bx, si
    push ax
    mov dx, bx
    add dx, si
    CALL_FN draw_map_cell, dx
    pop ax
    CJNE ah, up_key, .move_down
    dec byte [player_y]
    jmp .exit
.move_down:
    CJNE ah, down_key, .move_left
    inc byte [player_y]
    jmp .exit
.move_left:
    CJNE ah, left_key, .move_right
    dec byte [player_x]
    jmp .exit
.move_right:
    CJNE ah, right_key, .exit
    inc byte [player_x]
    jmp .exit
.exit:
    END 0

int_to_str: ;(x, buf)
    BEGIN
    mov ax, arg1
    mov bl, 10
    div bl
    add al, '0'
    add ah, '0'
    mov bx, arg2
    mov [bx], al
    mov [bx+1], ah
    END 4

clear_screen:
    BEGIN
    mov ax, 0A000h
    mov es, ax
    xor di, di
    mov cx, width*height/2
    mov al, 0
    mov ah, al
    rep stosw
    END 0

open_file: ;(file_name) -> fp
    BEGIN
    mov ah, 3Dh
    mov al, 0
    mov dx, arg1
    int 21h
    mov [fp], ax
    END 2

read_file: ;(buf, size)
    BEGIN
    mov ah, 3Fh
    mov bx, [fp]
    mov cx, arg2
    mov dx, arg1
    int 21h
    END 4

close_file:
    BEGIN
    mov ah, 3Eh
    mov bx, [fp]
    int 21h
    END 0