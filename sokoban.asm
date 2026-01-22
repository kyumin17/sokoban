section .data
    ;style
    REMOVE_CURSOR db 27, "[?25l"
    REMOVE_CURSOR_LEN equ $ - REMOVE_CURSOR
    TOTAL_RESET db 27, "[H", 27, "[?25h"
    TOTAL_RESET_LEN equ $ - TOTAL_RESET
    CLEAR db 27, "[2J", 27, "[3J", 27, "[H"
    CLEAR_LEN equ $ - CLEAR

    ;move
    MOVE db 27, "["
    move_row db "00"
    db ";"
    move_col db "00"
    db "H"
    MOVE_LEN equ $ - MOVE

    ;text
    TITLE db 27, "[1m", "SOKOBAN", 27, "[0m", 0
    TITLE_LEN equ $ - TITLE
    START db "start", 0
    START_LEN equ $ - START
    EXIT db "exit", 0
    EXIT_LEN equ $ - EXIT
    ARROW db ">", 0
    SPACE db " ", 0

    PLAYER db 27, "[38;5;15m", 0xE2, 0x97, 0x8F, 27, "[0m", 0
    PLAYER_LEN equ $ - PLAYER
    WALL db 27, "[48;5;245m", "  ", 27, "[0m", 0
    WALL_LEN equ $ - WALL
    BOX db 27, "[38;5;130m", 0xE2, 0x98, 0x92, 27, "[0m", 0
    BOX_LEN equ $ - BOX
    ACTIVATE_BOX db 27, "[38;5;11m", 0xE2, 0x98, 0x92, 27, "[0m", 0
    ACTIVATE_BOX_LEN equ $ - ACTIVATE_BOX
    TARGET db 27, "[38;5;14m", 0xE2, 0x97, 0x86, 27, "[0m", 0
    TARGET_LEN equ $ - TARGET
    ERASER db "  ", 0
    ERASER_LEN equ $ - ERASER

    ;setting
    WIDTH equ 25
    HEIGHT equ 10

    ;map
    FILE_NAME db "map/map.bin", 0

section .bss
    map: resb 250
    menu: resb 1
    key: resb 3
    input: resb 1
    string: resb 2
    x: resd 1
    y: resd 1

section .text
    global main

main:
    push rbp
    mov rbp, rsp
    call start_page
    leave
    ret

;;;;;page;;;;;
start_page:
    push rbp
    mov rbp, rsp
    call remove_cursor
    call clear_page
    mov byte [menu], 0
    
    mov rdi, 24
    mov rsi, 4
    mov rdx, TITLE
    mov rcx, TITLE_LEN
    call pos_write

    mov rdi, 26
    mov rsi, 8
    mov rdx, START
    mov rcx, START_LEN
    call pos_write

    mov rdi, 26
    mov rsi, 9
    mov rdx, EXIT
    mov rcx, EXIT_LEN
    call pos_write

    mov rdi, 1
    mov rsi, 12
    mov rdx, SPACE
    mov rcx, 1
    call pos_write

.draw_arrow:
    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 7
    mov rdx, SPACE
    mov rcx, 1
    call pos_write

    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 9
    mov rdx, SPACE
    mov rcx, 1
    call pos_write

    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 8
    mov rdx, ARROW
    mov rcx, 1
    call pos_write

    call read_key
    mov dl, [input]
    cmp dl, 4
    je .select
    mov al, dl
    add al, [menu]
    cmp rax, 1
    jne .draw_arrow
    mov [menu], dl
    jmp .draw_arrow

.select:
    cmp byte [menu], 1
    je .exit
    call clear_page
    call game_page

.exit:
    call total_reset
    leave
    ret

game_page:
    push rbp
    mov rbp, rsp
    call load_map
    call draw_map

.play:
    call draw_map
    call draw_player
    call read_key
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
    push rbp
    mov rbp, rsp
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    mov rax, 1
    syscall
    leave
    ret
    
int_to_str: ;(x: int) -> string
    push rbp
    mov rbp, rsp
    xor rdx, rdx
    mov rax, rdi
    mov rcx, 10
    div rcx
    add rax, "0"
    add rdx, "0"
    mov byte [string], al
    mov byte [string + 1], dl
    leave
    ret

pos_write: ;(x: int, y: int, msg: str, len: int) -> void
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx

    ;move position
    call int_to_str
    mov ax, [string]
    mov [move_col], ax
    mov rdi, r12
    call int_to_str
    mov ax, [string]
    mov [move_row], ax
    mov rdi, MOVE
    mov rsi, MOVE_LEN
    call write

    ;print
    mov rdi, r13
    mov rsi, r14
    call write
    pop r12
    pop r13
    pop r14
    leave
    ret

read_key: ;() -> input
    push rbp
    mov rbp, rsp

    mov rax, 0
    mov rdi, 0
    mov rsi, key
    mov rdx, 3
    syscall

    cmp byte [key], 10 ;enter
    mov byte [input], 4
    je .exit

    cmp byte [key], "q" ;q
    mov byte [input], 5
    je .exit

    mov byte [input], -1
    cmp byte [key], 27
    jne .exit

    cmp byte [key + 2], "A" ;up
    mov byte [input], 0
    je .exit
    cmp byte [key + 2], "B" ;down
    mov byte [input], 1
    je .exit
    cmp byte [key + 2], "C" ;right
    mov byte [input], 2
    je .exit
    cmp byte [key + 2], "D" ;left
    mov byte [input], 3

.exit:
    leave
    ret

;;;;;util;;;;;
draw_map:
    push rbp
    mov rbp, rsp
    push r12
    mov r12, 0

.loop:
    lea rax, [map + r12]

    push rax

    xor rdx, rdx
    mov rax, r12
    mov rbx, WIDTH
    div rbx

    mov rdi, rdx ;x
    imul rdi, 2
    mov rsi, rax ;y
    inc rdi
    inc rsi

    pop rax
    cmp byte [rax], 1 ;target
    mov rdx, TARGET
    mov rcx, TARGET_LEN
    je .draw
    cmp byte [rax], 2 ;box
    mov rdx, BOX
    mov rcx, BOX_LEN
    je .draw
    cmp byte [rax], 3 ;box + target
    mov rdx, ACTIVATE_BOX
    mov rcx, ACTIVATE_BOX_LEN
    je .draw
    cmp byte [rax], 4 ;wall
    mov rdx, WALL
    mov rcx, WALL_LEN
    je .draw
    jmp .skip_draw

.draw:
    call pos_write
    
.skip_draw:
    inc r12
    cmp r12, 250
    jl .loop
    pop r12
    leave
    ret

move:
    push rbp
    mov rbp, rsp

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
    push rbp
    mov rbp, rsp

    mov edi, [x]
    imul edi, 2
    mov esi, [y]
    inc edi
    inc esi
    mov rdx, PLAYER
    mov rcx, PLAYER_LEN
    call pos_write

    leave
    ret

remove_player:
    push rbp
    mov rbp, rsp

    mov edi, [x]
    imul edi, 2
    mov esi, [y]
    inc edi
    inc esi
    mov rdx, ERASER
    mov rcx, ERASER_LEN
    call pos_write

    leave
    ret

load_map: ;() -> x, y, map
    push rbp
    mov rbp, rsp

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

;;;;;style;;;;;
clear_page:
    push rbp
    mov rbp, rsp
    mov rdi, CLEAR
    mov rsi, CLEAR_LEN
    call write
    leave
    ret

remove_cursor:
    push rbp
    mov rbp, rsp
    mov rdi, REMOVE_CURSOR
    mov rsi, REMOVE_CURSOR_LEN
    call write
    leave
    ret

total_reset:
    push rbp
    mov rbp, rsp
    mov rdi, TOTAL_RESET
    mov rsi, TOTAL_RESET_LEN
    call write
    leave
    ret