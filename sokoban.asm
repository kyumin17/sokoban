section .data
    ;style
    BOLD db 27, "[1m"
    RESET db 27, "[0m"
    STYLE_LEN equ $ - RESET
    REMOVE_CURSOR db 27, "[?25l"
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
    TITLE db "SOKOBAN", 10, 0
    TITLE_LEN equ $ - TITLE
    START db "start", 10, 0
    START_LEN equ $ - START
    EXIT db "exit", 10, 0
    EXIT_LEN equ $ - EXIT
    ARROW db ">", 10, 0
    ARROW_LEN equ $ - ARROW
    SPACE db " ", 0
    SPACE_LEN equ $ - SPACE
    PLAYER db 27, "[38;5;15m", 0xE2, 0x97, 0x8F, " ", 27, "[0m", 0
    PLAYER_LEN equ $ - PLAYER
    WALL db 27, "[48;5;245m", "  ", 27, "[0m", 0
    WALL_LEN equ $ - WALL
    GROUND db 27, "  ", 0
    GROUND_LEN equ $ - GROUND
    BOX db 27, "[38;5;130m", 0xE2, 0x98, 0x92, " ", 27, "[0m", 0
    BOX_LEN equ $ - BOX
    TARGET db 27, "[38;5;14m", 0xE2, 0x97, 0x86, " ", 27, "[0m", 0
    TARGET_LEN equ $ - TARGET

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

    call bold_style
    
    mov rdi, 24
    mov rsi, 4
    mov rdx, TITLE
    mov rcx, TITLE_LEN
    call pos_write

    call reset_style

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
    mov rcx, SPACE_LEN
    call pos_write

.draw_arrow:
    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 7
    mov rdx, SPACE
    mov rcx, SPACE_LEN
    call pos_write

    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 9
    mov rdx, SPACE
    mov rcx, SPACE_LEN
    call pos_write

    mov rdi, 24
    movzx rsi, byte [menu]
    add rsi, 8
    mov rdx, ARROW
    mov rcx, ARROW_LEN
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

.play:
    call clear_page

    mov eax, [y]
    imul eax, WIDTH
    add eax, [x]

    mov byte [map + eax], 2
    push rax
    call draw_map
    pop rax
    mov byte [map + eax], 0

    call read_key
    mov dl, [input]
    cmp dl, 0
    je .up
    cmp dl, 1
    je .down
    cmp dl, 2
    je .right
    cmp dl, 3
    je .left
    cmp dl, 5
    je .exit
    jmp .play

.up:
    dec dword [y]
    jmp .play
.down:
    inc dword [y]
    jmp .play
.right:
    inc dword [x]
    jmp .play
.left:
    dec dword [x]
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
    cmp byte [rax], 2 ;player
    mov rdx, PLAYER
    mov rcx, PLAYER_LEN
    je .draw
    cmp byte [rax], 3 ;box
    mov rdx, BOX
    mov rcx, BOX_LEN
    je .draw
    cmp byte [rax], 4 ;wall
    mov rdx, WALL
    mov rcx, WALL_LEN
    je .draw
    cmp byte [rax], 0
    mov rdx, GROUND
    mov rcx, GROUND_LEN
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

load_map:
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
bold_style:
    push rbp
    mov rbp, rsp
    mov rdi, BOLD
    mov rsi, STYLE_LEN
    call write
    leave
    ret

reset_style:
    push rbp
    mov rbp, rsp
    mov rdi, RESET
    mov rsi, STYLE_LEN
    call write
    leave
    ret

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
    lea rsi, [STYLE_LEN + 2]
    call write
    leave
    ret

total_reset:
    push rbp
    mov rbp, rsp
    mov rdi, TOTAL_RESET
    lea rsi, [TOTAL_RESET_LEN + 2]
    call write
    leave
    ret