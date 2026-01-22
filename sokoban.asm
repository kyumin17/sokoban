section .data
    ;style
    BOLD db 27, "[1m"
    RESET db 27, "[0m"
    STYLE_LEN equ $ - RESET
    REMOVE_CURSOR db 27, "[?25l"
    CLEAR db 27, "[2J"

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

    PLAYER db "i", 0
    PLAYER_LEN equ $ - PLAYER

    ;setting
    WIDTH equ 50
    HEIGHT equ 10

section .bss
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
    leave
    ret

game_page:
    push rbp
    mov rbp, rsp
    mov dword [x], 27
    mov dword [y], 6

.play:
    mov edi, [x]
    mov esi, [y]
    mov rdx, PLAYER
    mov rcx, PLAYER_LEN
    call pos_write

    call read_key

    mov edi, [x]
    mov esi, [y]
    mov rdx, SPACE
    mov rcx, SPACE_LEN
    call pos_write
    
    mov dl, [input]
    cmp dl, 0
    je .up
    cmp dl, 1
    je .down
    cmp dl, 2
    je .right
    cmp dl, 3
    je .left
    jmp .play

.up:
    cmp dword [y], 1
    je .play
    dec dword [y]
    jmp .play
.down:
    cmp dword [y], HEIGHT
    je .play
    inc dword [y]
    jmp .play
.right:
    cmp dword [x], WIDTH
    je .play
    inc dword [x]
    jmp .play
.left:
    cmp dword [x], 1
    je .play
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
    mov rsi, STYLE_LEN
    call write
    leave
    ret