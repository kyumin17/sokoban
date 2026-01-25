org 100h
jmp start

section .data
    title_str db "SOKOBAN"
    start_str db "START"
    exit_str db "EXIT"
    
    map_file_path db "map/"
    level_str db "lv"
    level_num_str db "00"
    db ".bin"

    level_file_path db "data/level.bin", 0
    player_file_path db "data/player.bin", 0
    grass_file_path db "data/grass.bin", 0
    wall_file_path db "data/wall.bin", 0
    box_file_path db "data/box.bin", 0
    target_file_path db "data/target.bin", 0

    width equ 320
    height equ 200

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
    buffer: resb 200
    clear_level: resw 1
    level: resw 1
    map: resb 100
    player_shape: resb 300
    grass_shape: resb 100
    wall_shape: resb 100
    box_shape: resb 300
    target_shape: resb 200
    map_width: resb 1
    map_height: resb 1

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
%macro LOAD_FILE 3
    CALL_FN open_file, %1
    CALL_FN read_file, %2, %3
    CALL_FN close_file
%endmacro

;;;;;;;;;;start;;;;;;;;;;
start:
    CALL_SYS 10h, 13h
    mov ax, 0A000h
    mov es, ax
    LOAD_FILE level_file_path, clear_level, 1
    LOAD_FILE player_file_path, player_shape, 300
    LOAD_FILE grass_file_path, grass_shape, 100
    LOAD_FILE wall_file_path, wall_shape, 100
    LOAD_FILE box_file_path, box_shape, 300
    LOAD_FILE target_file_path, target_shape, 200
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
    cmp al, enter_key
    je .select_menu
    cmp ah, up_key
    jne .check_down
    mov bl, 15
.check_down:
    cmp ah, down_key
    jne .get_key
    mov bl, 17
    jmp .get_key
.select_menu:
    cmp bl, 17
    je .exit
    call clear_screen
    call menu_page
.exit:
    END 0

menu_page:
    BEGIN
    CALL_FN draw_string, 16, 2, title_str, 7
    CALL_SYS 16h, 0h
    mov ax, [clear_level]
    mov [level], ax
    call clear_screen
    call game_page
    END 0

game_page:
    BEGIN
    CALL_FN int_to_str, word [level], level_num_str
    CALL_FN draw_string, 1, 1, level_str, 4
    CALL_SYS 16h, 0h
    END 0

;;;;;;;;;;util;;;;;;;;;;
draw_shape: ;(x: int, y: int, buf)
    BEGIN
    mov di, arg2
    imul di, width
    add di, arg1
    xor cx, cx
    mov ah, 0
    mov bx, arg3
    mov dx, [bx]
.outer_loop:
    add bx, 2
    mov cl, [bx]
    mov al, [bx+1]
.inner_loop:
    mov [es:di], al
    cmp ah, 20
    jle .skip_div
    sub ah, 20
.skip_div:
    cmp ah, 19
    jne .skip_down
    add di, 300
.skip_down:
    inc ah
    inc di
    loop .inner_loop
    dec dx
    jnz .outer_loop
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