section .data
    ;ansi code
    ansi_reset_terminal db 27, "[H", 27, "[?25h"
    ansi_reset_terminal_len equ $ - ansi_reset_terminal
    ansi_remove_cursor db 27, "[?25l"
    ansi_remove_cursor_len equ $ - ansi_remove_cursor
    ansi_clear_terminal db 27, "[0m", 27, "[2J", 27, "[3J", 27, "[H"
    ansi_clear_terminal_len equ $ - ansi_clear_terminal
    ansi_move_cursor db 27, "["
    move_cursor_row db "00"
    db ";"
    move_cursor_col db "00"
    db "H"
    ansi_move_cursor_len equ $ - ansi_move_cursor
    ansi_clear_terminal_blue db 27, "[48;5;33m", 27, "[2J", 27, "[3J", 27, "[H"
    ansi_clear_terminal_blue_len equ $ - ansi_clear_terminal_blue
    ansi_style_bold db 27, "[1m"
    ansi_style_bold_len equ $ - ansi_style_bold
    ansi_style_bold_remove db 27, "[22m"
    ansi_style_bold_remove_len equ $ - ansi_style_bold_remove

    ;text
    title_msg db 27, "[1m", "SOKOBAN", 27, "[0m"
    title_msg_len equ $ - title_msg
    start_msg db "start"
    start_msg_len equ $ - start_msg
    exit_msg db "exit"
    exit_msg_len equ $ - exit_msg
    arrow db ">"
    space db "    "

    select_left_msg db " ["
    select_right_msg db "] "

    level_msg db "Lv"
    level_str db "00"
    level_msg_len equ $ - level_msg

    player_shape db 27, "[38;5;15m", "@ "
    player_shape_len equ $ - player_shape
    wall_shape db 27, "[48;5;88;38;5;33m", "┤├", 27, "[48;5;33m"
    wall_shape_len equ $ - wall_shape
    box_shape db 27, "[38;5;15m", "☒ "
    box_shape_len equ $ - box_shape
    activate_box_shape db 27, "[38;5;15m", "☒ "
    activate_box_shape_len equ $ - activate_box_shape
    target_shape db 27, "[38;5;15m", "◇ "
    target_shape_len equ $ - target_shape

    ;setting
    WIDTH equ 25
    HEIGHT equ 10
    FILE_NAME db "data/lv00.bin"

    ;key
    UP_KEY equ 0
    DOWN_KEY equ 1
    RIGHT_KEY equ 2
    LEFT_KEY equ 3
    ENTER_KEY equ 4
    QUIT_KEY equ 5

section .bss
    map: resb 250
    key: resb 3
    input: resb 1
    x: resd 1
    y: resd 1
    level: resb 1

section .text
    global _start

;;;;;macro;;;;;
%macro BEGIN_FN 0
    push rbp
    mov rbp, rsp
%endmacro

%macro CALL_FN 1-5
    %if %0 > 4
    mov rcx, %5
    %endif
    %if %0 > 3
    mov rdx, %4
    %endif
    %if %0 > 2
    mov rsi, %3
    %endif
    %if %0 > 1
    mov rdi, %2
    %endif
    call %1
%endmacro

_start:
    BEGIN_FN
    CALL_FN write, ansi_remove_cursor, ansi_remove_cursor_len
    call start_page
    CALL_FN write, ansi_clear_terminal, ansi_clear_terminal_len
    CALL_FN write, ansi_reset_terminal, ansi_reset_terminal_len
    mov rax, 60
    xor rdi, rdi
    syscall

;;;;;page;;;;;
start_page:
    BEGIN_FN
    CALL_FN write, ansi_clear_terminal, ansi_clear_terminal_len
    CALL_FN write_xy, 24, 4, title_msg, title_msg_len
    CALL_FN write_xy, 26, 8, start_msg, start_msg_len
    CALL_FN write_xy, 26, 9, exit_msg, exit_msg_len
    push r12
    mov r12, 8
.draw_select:
    CALL_FN write_xy, 24, r12, arrow, 1
    call get_key
    CALL_FN write_xy, 24, 8, space, 1
    CALL_FN write_xy, 24, 9, space, 1
    mov dl, [input]
    cmp dl, QUIT_KEY
    je .exit
    cmp dl, ENTER_KEY
    je .select_menu
    cmp dl, UP_KEY
    jne .skip_up
    mov r12, 8
.skip_up:
    cmp dl, DOWN_KEY
    jne .draw_select
    mov r12, 9
    jmp .draw_select
.select_menu:
    cmp r12, 9
    pop r12
    je .exit
    call menu_page
.exit:
    leave
    ret

menu_page:
    mov byte [level], 1
    BEGIN_FN
    CALL_FN write, ansi_clear_terminal, ansi_clear_terminal_len
    CALL_FN write_xy, 24, 2, title_msg, title_msg_len
    CALL_FN write_xy, 9, 4, space, 0
    push r12
    mov r12, 1
.draw_lv:
    CALL_FN int_to_str, r12, level_str
    CALL_FN write, level_msg, level_msg_len
    CALL_FN write, space, 4
.draw_end:
    inc r12
    cmp r12, 6
    jne .skip_down_1
    CALL_FN write_xy, 9, 6, space, 0
.skip_down_1:
    cmp r12, 11
    jne .skip_down_2
    CALL_FN write_xy, 9, 8, space, 0
.skip_down_2:
    cmp r12, 15
    jle .draw_lv
.draw_select:
    mov r12, [level]
    call get_key
    mov dl, [input]
    cmp dl, QUIT_KEY
    je .exit
    cmp dl, ENTER_KEY
    je .play
    cmp dl, UP_KEY
    je .up
.up:
    cmp r12, 5
    jle .draw_select
    sub r12, 5
.down:
    cmp r12, 10
    jg .draw_select
    add r12, 5
.left:
    cmp r12, 1
    je .draw_select
    sub r12, 1
.right:
    cmp r12, 15
    je .draw_select
    add r12, 1
.play:
    pop r12
    call game_page
.exit:
    leave
    ret

game_page: ;(lv: int) -> void
    BEGIN_FN
    CALL_FN write, ansi_clear_terminal_blue, ansi_clear_terminal_blue_len
    call load_map
    CALL_FN int_to_str, [level], level_str
    CALL_FN write, ansi_style_bold, ansi_style_bold_len
    CALL_FN write_xy, 4, 2, level_msg, level_msg_len
    CALL_FN write, ansi_style_bold_remove, ansi_style_bold_remove_len
.play:
    call draw_map
    call draw_player
    call get_key
    call remove_player
    mov dl, [input]
    cmp dl, 5
    je .exit
    call move
    jmp .play
.exit:
    leave
    ret

;;;;;control;;;;;
write: ;(msg: str, len: int) -> void
    BEGIN_FN
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    mov rax, 1
    syscall
    leave
    ret

int_to_str: ;(x: int, buf) -> buf
    BEGIN_FN
    xor rdx, rdx
    mov rax, rdi
    mov rcx, 10
    div rcx
    add rax, "0"
    add rdx, "0"
    mov byte [rsi], al
    mov byte [rsi + 1], dl
    leave
    ret

write_xy: ;(x: int, y: int, msg: str, len: int) -> void
    BEGIN_FN
    push r12
    push rdx
    push rcx
    mov r12, rsi
    CALL_FN int_to_str, rdi, move_cursor_col
    CALL_FN int_to_str, r12, move_cursor_row
    CALL_FN write, ansi_move_cursor, ansi_move_cursor_len
    pop rcx
    pop rdx
    pop r12
    CALL_FN write, rdx, rcx
    leave
    ret

get_key: ;() -> input
    BEGIN_FN
    mov rax, 0
    mov rdi, 0
    mov rsi, key
    mov rdx, 3
    syscall
    cmp byte [key], 10
    mov byte [input], ENTER_KEY
    je .exit
    cmp byte [key], "q"
    mov byte [input], QUIT_KEY
    je .exit
    mov byte [input], -1
    cmp byte [key], 27
    jne .exit
    cmp byte [key + 2], "A"
    mov byte [input], UP_KEY
    je .exit
    cmp byte [key + 2], "B"
    mov byte [input], DOWN_KEY
    je .exit
    cmp byte [key + 2], "C"
    mov byte [input], RIGHT_KEY
    je .exit
    cmp byte [key + 2], "D"
    mov byte [input], LEFT_KEY
.exit:
    leave
    ret

;;;;;util;;;;;
get_terminal_pos: ;(x: int, y: int) -> x, y
    BEGIN_FN
    imul edi, 2
    add edi, 4
    add esi, 4
    leave
    ret

draw_map:
    BEGIN_FN
    push r12
    mov r12, 0

.loop:
    lea rax, [map + r12]
    push rax
    xor rdx, rdx
    mov rax, r12
    mov rbx, WIDTH
    div rbx
    CALL_FN get_terminal_pos, rdx, rax

    pop rax
    cmp byte [rax], 1 ;target
    mov rdx, target_shape
    mov rcx, target_shape_len
    je .draw
    cmp byte [rax], 2 ;box
    mov rdx, box_shape
    mov rcx, box_shape_len
    je .draw
    cmp byte [rax], 3 ;box + target
    mov rdx, activate_box_shape
    mov rcx, activate_box_shape_len
    je .draw
    cmp byte [rax], 4 ;wall
    mov rdx, wall_shape
    mov rcx, wall_shape_len
    je .draw
    jmp .skip_draw
.draw:
    call write_xy
.skip_draw:
    inc r12
    cmp r12, 250
    jl .loop
    pop r12
    leave
    ret

move:
    BEGIN_FN
    mov eax, [y]
    imul eax, WIDTH
    add eax, [x]
    mov dl, [input]
    cmp dl, 0
    je .up
    cmp dl, 1
    je .down
    cmp dl, 2
    je .right
    cmp dl, 3
    je .left
    jmp .exit
.up:
    mov ebx, -WIDTH
    jmp .check_move
.down:
    mov ebx, WIDTH
    jmp .check_move
.right:
    mov ebx, 1
    jmp .check_move
.left:
    mov ebx, -1
    jmp .check_move
.check_move:
    movsxd rax, eax
    movsxd rbx, ebx
    cmp byte [map + rax + rbx], 4
    je .exit
    cmp byte [map + rax + rbx], 1 ;move player
    jle .move_player
    cmp byte [map + rax + 2 * rbx], 1 ;move box + player
    jle .move_box
    jmp .exit
.move_box:
    add byte [map + rax + 2 * rbx], 2
    sub byte [map + rax + rbx], 2
.move_player:
    mov dl, [input]
    cmp dl, 0
    je .up_move
    cmp dl, 1
    je .down_move
    cmp dl, 2
    je .right_move
    cmp dl, 3
    je .left_move
.up_move:    
    dec dword [y]
    jmp .exit
.down_move:
    inc dword [y]
    jmp .exit
.right_move:
    inc dword [x]
    jmp .exit
.left_move:
    dec dword [x]
    jmp .exit
.exit:
    leave
    ret

draw_player:
    BEGIN_FN
    CALL_FN get_terminal_pos, [x], [y]
    mov rdx, player_shape
    mov rcx, player_shape_len
    call write_xy
    leave
    ret

remove_player:
    BEGIN_FN
    CALL_FN get_terminal_pos, [x], [y]
    mov rdx, space
    mov rcx, 2
    call write_xy
    leave
    ret

load_map: ;() -> x, y, map
    BEGIN_FN

    mov rax, FILE_NAME
    add rax, 7
    CALL_FN int_to_str, [level], rax

    mov rax, 2
    mov rdi, FILE_NAME
    mov rsi, 0
    mov rdx, 0
    syscall

    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, x
    mov rdx, 1
    syscall

    mov rax, 0
    mov rdi, rbx
    mov rsi, y
    mov rdx, 1
    syscall

    mov rax, 0
    mov rdi, rbx
    mov rsi, map
    mov rdx, 250
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

    leave
    ret