org 100h
jmp start

section .data
    title_str db "SOKOBAN"
    start_str db "START"
    exit_str db "EXIT"
    complete_str db "LEVEL COMPLETE"
    menu_str db "MENU"
    next_str db "NEXT"
    
    map_file_path db "map/"
    level_str db "lv"
    level_num_str db "00"
    db ".bin", 0
    level_file_path db "data/level.bin", 0
    img_file_path db "data/image.bin", 0
    title_file_path db "data/title.bin", 0

    width equ 320
    height equ 200

    enter_key equ 0Dh
    up_key equ 48h
    down_key equ 50h
    right_key equ 4Dh
    left_key equ 4Bh
    exit_key equ 1Bh
    restart_key equ 'r'

    target equ 1
    box equ 2
    target_box equ 3
    wall equ 4

    start_page_num equ 1
    menu_page_num equ 2
    game_page_num equ 3

section .bss
    fp: resw 1
    number: resw 1
    buffer: resb 256
    buffer2: resb 256
    cell_size: resb 1

    clear_level: resw 1
    level: resw 1

    ground_img: resb 68
    player_img: resb 68
    target_img: resb 68
    box_img: resb 68
    wall_img: resb 68
    menu_img: resb 148
    lock_img: resb 68

    map_width: resb 1
    map_height: resb 1
    player_x: resb 1
    player_y: resb 1
    map: resb 200
    box_number: resb 1

    page: resb 1

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
    mov byte [page], 1
    mov byte [cell_size], 16
    LOAD_FILE level_file_path, clear_level, 1
    LOAD_FILE img_file_path, player_img, 488
    mov byte [ground_img], 25
.start:
    CJNE byte [page], 1, .skip_start
    call start_page
    jmp .start
.skip_start:
    CJNE byte [page], 2, .skip_menu
    call menu_page
    jmp .start
.skip_menu:
    CJNE byte [page], 3, .exit
    call game_page
    jmp .start
.exit:
    CALL_SYS 10h, 3h
    CALL_SYS 21h, 4C00h

;;;;;;;;;;page;;;;;;;;;;
start_page:
    BEGIN
    call draw_start_background
    CALL_FN draw_string, 32, 12, title_str, 7, 0
    CALL_FN draw_string, 34, 26, start_str, 5, 0
    CALL_FN draw_string, 35, 30, exit_str, 4, 0
    mov bx, 26
.get_key:
    push bx
    mov cx, 56
    sub cx, bx
    push cx
    CALL_FN draw_letter, 30, bx, '>', 0
    pop cx
    CALL_FN draw_letter, 30, cx, 219, 43
    CALL_SYS 16h, 0h
    pop bx
    CJNE al, exit_key, .skip_quit
    mov byte [page], 0
    jmp .exit
.skip_quit:
    CJE al, enter_key, .select_menu
    CJNE ah, up_key, .check_down
    mov bl, 26
.check_down:
    CJNE ah, down_key, .get_key
    mov bl, 30
    jmp .get_key
.select_menu:
    CJE bl, 30, .exit
    mov byte [page], 2
.exit:
    END 0

menu_page:
    BEGIN
    CALL_FN clear_screen, 43
    MOV_VAL [level], [clear_level]
    CALL_FN draw_string, 32, 5, title_str, 7, 0
    mov dx, 1
    mov ax, 14
.outer_loop:
    mov bx, 13
.inner_loop:
    push dx
    PUSH_REG ax, bx
    CALL_FN int_to_str, dx, level_num_str
    POP_REG ax, bx
    PUSH_REG ax, bx
    shl ax, 2
    shl bx, 2
    sub bx, 5
    sub ax, 16
    mov byte [cell_size], 24
    CALL_FN draw_shape, bx, ax, menu_img
    mov byte [cell_size], 16
    POP_REG ax, bx
    pop dx
    push dx
    cmp dl, byte [clear_level]
    jg .draw_lock
    PUSH_REG ax, bx
    CALL_FN draw_string, bx, ax, level_num_str, 2, 0
    POP_REG ax, bx
    jmp .skip_lock
.draw_lock:
    PUSH_REG ax, bx
    shl ax, 2
    shl bx, 2
    sub bx, 1
    sub ax, 12
    CALL_FN draw_shape, bx, ax, lock_img
    POP_REG ax, bx
.skip_lock:
    pop dx
    add bx, 12
    inc dx
    CJNE bx, 73, .inner_loop
    add ax, 12
    CJNE ax, 50, .outer_loop
.draw_select_lv:
    movzx dx, byte [level]
    CALL_FN int_to_str, dx, level_num_str
    movzx ax, byte [level]
    dec ax
    mov bl, 5
    div bl
    movzx bx, ah
    movzx dx, al
    imul bx, 12
    imul dx, 12
    add bx, 13
    add dx, 14
    PUSH_REG bx, dx
    CALL_FN draw_string, bx, dx, level_num_str, 2, 15
    CALL_SYS 16h, 0h
    POP_REG bx, dx
    CJNE al, exit_key, .skip_quit
    mov byte [page], 0
    jmp .exit
.skip_quit:
    CJE al, enter_key, .play
    push ax
    CALL_FN draw_string, bx, dx, level_num_str, 2, 0
    pop ax
    mov dl, [level]
    CJNE ah, up_key, .skip_up
    sub dl, 5
    jmp .skip_all
.skip_up:
    CJNE ah, down_key, .skip_down
    add dl, 5
    jmp .skip_all
.skip_down:
    CJNE ah, left_key, .skip_left
    dec dl
    jmp .skip_all
.skip_left:
    CJNE ah, right_key, .skip_all
    inc dl
.skip_all:
    cmp dl, 1
    jl .draw_select_lv
    cmp dl, [clear_level]
    jg .draw_select_lv
    mov [level], dl
    jmp .draw_select_lv
.play:
    mov byte [page], 3
.exit:
    END 0

game_page:
    BEGIN
    CALL_FN clear_screen, 25
    CALL_FN int_to_str, word [level], level_num_str
    call load_map
    call draw_map
    CALL_FN draw_string, 2, 2, level_str, 4, 15
.update:
    movzx bx, byte [player_x]
    movzx dx, byte [player_y]
    PUSH_REG bx, dx
    CALL_FN draw_map_shape, bx, dx, player_img
    CJE byte [box_number], 0, .complete
    CALL_SYS 16h, 0h
    CJE al, restart_key, .exit
    CJNE al, exit_key, .skip_quit
    mov byte [page], 0
    jmp .exit
.skip_quit:
    POP_REG bx, dx
    call play_turn
    jmp .update
.complete:
    mov al, byte [clear_level]
    CJNE byte [level], al, .skip_clear
    inc byte [clear_level]
    call update_clear_level
.skip_clear:
    call complete_page
.exit:
    END 0

complete_page:
    BEGIN
    mov cx, 60
    mov di, width*65+width/4
.loop:
    PUSH_REG di, cx
    mov ax, 0A000h
    mov es, ax
    mov cx, width/4-4
    mov al, 43
    mov ah, al
    rep stosw
    POP_REG di, cx
    add di, width
    loop .loop
    CALL_FN draw_string, 25, 20, complete_str, 14, 0
    mov bx, 6
.get_key:
    push bx
    CALL_FN draw_string, 28, 26, menu_str, 4, bx
    pop bx
    push bx
    mov cx, 192
    sub cx, bx
    CALL_FN draw_string, 43, 26, next_str, 4, cx
    pop bx
    CALL_SYS 16h, 0h
    CJNE al, exit_key, .skip_quit
    mov byte [page], 0
    jmp .exit
.skip_quit:
    CJE al, enter_key, .select_menu
    CJNE ah, left_key, .skip_left
    mov bx, 186
.skip_left:
    CJNE ah, right_key, .get_key
    mov bx, 6
    jmp .get_key
.select_menu:
    CJNE bx, 6, .skip_next
    mov al, byte [clear_level]
    mov byte [level], al
    mov byte [page], 3
    jmp .exit
.skip_next:
    mov byte [page], 2
.exit:
    END 0

;;;;;;;;;;draw;;;;;;;;;;
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
    add di, width*8
    xor dl, dl
.outer_loop:
    movzx cx, byte [cell_size]
    shr cx, 2
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
    add di, width
    movzx dx, [cell_size]
    sub di, dx
    pop dx
    inc dl
    CJNE dl, byte [cell_size], .outer_loop
    END 6

draw_map_shape: ;(x, y, buf)
    BEGIN
    mov ax, 20
    sub al, byte [map_width]
    shr ax, 1
    add ax, arg1
    mov bx, 12
    sub bl, byte [map_height]
    shr bx, 1
    add bx, arg2
    shl ax, 4
    shl bx, 4
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
    add dx, 2
    inc si
    loop .loop
    END 10

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
    shl di, 2
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
    mov si, ax
    mov di, bx
    shl si, 4
    shl di, 4
    CALL_FN draw_shape, si, di, dx
    POP_REG cx, si, dx, di
    inc si
    loop .inner_loop
    mov dx, box_img
    inc di
    CJE di, 1, .outer_loop
    call close_file
    END 0

draw_map:
    BEGIN
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

;;;;;;;;;;util;;;;;;;;;;
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

update_clear_level:
    BEGIN
    mov ah, 3Ch
    mov dx, level_file_path
    int 21h
    mov [fp], ax
    mov ah, 40h
    mov bx, [fp]
    mov cx, 1
    mov dx, clear_level
    int 21h
    call close_file
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

clear_screen: ;(color)
    BEGIN
    mov ax, 0A000h
    mov es, ax
    xor di, di
    mov cx, width*height/2
    mov al, arg1
    mov ah, al
    rep stosw
    END 2

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