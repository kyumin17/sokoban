org 100h
jmp start

section .data
    title_str db "SOKOBAN"
    start_str db "START"
    exit_str db "EXIT"
    
    map_file_path db "map/"
    level_str db "lv"
    level_num_str db "00"
    db ".bin", 0

    level_file_path db "data/level.bin", 0
    player_file_path db "data/player.bin", 0
    grass_file_path db "data/grass.bin", 0
    wall_file_path db "data/wall.bin", 0
    box_file_path db "data/box.bin", 0
    target_file_path db "data/target.bin", 0

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
    wall equ 3

section .bss
    fp: resw 1
    number: resw 1
    buffer: resb 256
    clear_level: resw 1
    level: resw 1
    map: resb 200
    player_shape: resb 68
    grass_shape: resb 68
    wall_shape: resb 68
    box_shape: resb 68
    target_shape: resb 68
    map_width: resb 1
    map_height: resb 1
    player_x: resb 1
    player_y: resb 1

section .text
;;;;;;;;;;define;;;;;;;;;;
%define arg1 [bp+4]
%define arg2 [bp+6]
%define arg3 [bp+8]
%define arg4 [bp+10]

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
%macro CALL_FN 1-5
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
    LOAD_FILE player_file_path, player_shape, 68
    LOAD_FILE grass_file_path, grass_shape, 68
    LOAD_FILE wall_file_path, wall_shape, 68
    LOAD_FILE box_file_path, box_shape, 68
    LOAD_FILE target_file_path, target_shape, 68
    call start_page
    CALL_SYS 10h, 3h
    CALL_SYS 21h, 4C00h

;;;;;;;;;;page;;;;;;;;;;
start_page:
    BEGIN
    CALL_FN draw_string, 16, 6, title_str, 7
    CALL_FN draw_string, 17, 15, start_str, 5
    CALL_FN draw_string, 17, 17, exit_str, 4
    mov bx, 15
.get_key:
    push bx
    mov cx, 32
    sub cx, bx
    CALL_FN draw_letter, 15, bx, '>'
    CALL_FN draw_letter, 15, cx, ' '
    CALL_SYS 16h, 0h
    pop bx
    CJE al, enter_key, .select_menu
    CJNE ah, up_key, .check_down
    mov bl, 15
.check_down:
    CJNE ah, down_key, .get_key
    mov bl, 17
    jmp .get_key
.select_menu:
    CJE bl, 17, .exit
    call clear_screen
    call menu_page
.exit:
    END 0

menu_page:
    BEGIN
    CALL_FN draw_string, 16, 2, title_str, 7
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
    CALL_FN draw_string, 1, 1, level_str, 4
.get_input:
    movzx bx, byte [player_x]
    inc bx
    shl bx, 4
    movzx dx, byte [player_y]
    shl dx, 4
    add dx, 24
    PUSH_REG bx, dx
    CALL_FN draw_shape, bx, dx, player_shape
    CALL_SYS 16h, 0h
    CJE al, enter_key, .exit
    POP_REG bx, dx
    call play_turn
    jmp .get_input
.exit:
    END 0

;;;;;;;;;;util;;;;;;;;;;
draw_shape: ;(x: int, y: int, buf)
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

draw_string: ;(x: int, y: int, msg: str, len: int)
    BEGIN
    mov ah, 2h
    mov bh, 0
    mov dh, arg2
    mov dl, arg1
    int 10h
    mov cx, arg4
    mov si, arg3
    cld
.loop:
    lodsb
    mov ah, 0Eh
    mov bl, 15
    int 10h
    loop .loop
    END 8

draw_letter: ;(x: int, y: int, c: char)
    BEGIN
    mov ah, 2h
    mov bh, 0
    mov dh, arg2
    mov dl, arg1
    int 10h
    mov al, arg3
    mov ah, 0Eh
    mov bl, 15
    int 10h
    END 6

load_map:
    BEGIN
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
    mov [map+bx], ah
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
    mov cx, width*4
    xor di, di
.draw_top:
    mov al, 2
    mov ah, 2
    mov [es:di], ax
    add di, 2
    loop .draw_top
    mov bx, 0
.outer_loop_bg:
    mov cx, 20
.inner_loop_bg:
    PUSH_REG bx, cx
    mov dx, bx
    shl dx, 4
    add dx, 8
    mov ax, cx
    shl ax, 4
    CALL_FN draw_shape, ax, dx, grass_shape
    POP_REG bx, cx
    loop .inner_loop_bg
    inc bx
    CJNE bx, 12, .outer_loop_bg
    ;objects
    movzx cx, byte [map_width]
    movzx ax, byte [map_height]
    imul cx, ax
    mov ax, cell_size
    mov bx, 24
    xor si, si
.loop_obj:
    movzx dx, byte [map_width]
    inc dx
    shl dx, 4
    CJNE ax, dx, .draw
    mov ax, cell_size
    add bx, cell_size
.draw:
    PUSH_REG ax, bx, cx, dx
    push si
    mov cl, byte [map+si]
    CJNE cl, target, .box
    mov dx, target_shape
    jmp .skip_all
.box:
    CJNE cl, box, .wall
    mov dx, box_shape
    jmp .skip_all
.wall:
    CJNE cl, wall, .skip_draw
    mov dx, wall_shape
    jmp .skip_all
.skip_all:
    CALL_FN draw_shape, ax, bx, dx
.skip_draw:
    pop si
    POP_REG ax, bx, cx, dx
    add ax, cell_size
    inc si
    loop .loop_obj
    END 0

draw_map_cell: ;(idx: int)
    BEGIN
    mov ax, arg1
    mov cl, byte [map_width]
    div cl
    movzx cx, al
    movzx ax, ah
    inc ax
    shl ax, 4
    shl cx, 4
    add cx, 24
    PUSH_REG ax, cx
    CALL_FN draw_shape, ax, cx, grass_shape
    POP_REG ax, cx
    mov bx, map
    add bx, arg1
    movzx bx, byte [bx]
    CJNE bx, target, .box
    mov dx, target_shape
    jmp .draw
.box:
    CJNE bx, box, .wall
    mov dx, box_shape
    jmp .draw
.wall:
    CJNE bx, wall, .exit
    mov dx, wall_shape
    jmp .draw
.draw:
    CALL_FN draw_shape, ax, cx, dx
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

int_to_str: ;(x: int, buf)
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

open_file: ;(file_name: str) -> fp
    BEGIN
    mov ah, 3Dh
    mov al, 0
    mov dx, arg1
    int 21h
    mov [fp], ax
    END 2

read_file: ;(buf, size: int)
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