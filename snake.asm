org 0x7C00
bits 16

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Set video mode to 80x25 text
    mov ax, 0x0003
    int 0x10

    ; Hide cursor
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    ; Initialize snake
    mov byte [snake_dir], 1       ; Initial direction: right
    mov byte [snake_len], 3
    mov si, snake_body
    mov byte [si], 40             ; Head at (40,12)
    mov byte [si+1], 12
    mov byte [si+2], 39           ; Body segments
    mov byte [si+3], 12
    mov byte [si+4], 38
    mov byte [si+5], 12

    call generate_food
    call draw_screen    ; Draw initial screen

game_loop:
    ; Handle input
    mov ah, 0x01
    int 0x16
    jz .no_input
    xor ah, ah
    int 0x16
    cmp ah, 0x48      ; Up
    je .up
    cmp ah, 0x50      ; Down
    je .down
    cmp ah, 0x4B      ; Left
    je .left
    cmp ah, 0x4D      ; Right
    je .right
.no_input:
    call move_snake
    call check_food
    call check_collisions
    jc game_over
    call draw_screen
    jmp .delay

.up:
    cmp byte [snake_dir], 2
    je .no_input
    mov byte [snake_dir], 0
    jmp .no_input
.down:
    cmp byte [snake_dir], 0
    je .no_input
    mov byte [snake_dir], 2
    jmp .no_input
.left:
    cmp byte [snake_dir], 1
    je .no_input
    mov byte [snake_dir], 3
    jmp .no_input
.right:
    cmp byte [snake_dir], 3
    je .no_input
    mov byte [snake_dir], 1
    jmp .no_input

.delay:
    mov cx, 0x00F0    ; Outer loop counter (set to 120)
.outer_delay:
    mov dx, 0xFFFF    ; Inner loop counter - much longer delay
.inner_delay:
    dec dx
    jnz .inner_delay
    loop .outer_delay
    jmp game_loop

game_over:
    mov si, game_over_msg
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt

; Subroutines
move_snake:
    ; Shift all body segments
    movzx cx, byte [snake_len]
    dec cx              ; One less than length
    mov di, cx
    shl di, 1           ; Multiply by 2 (each segment is 2 bytes)
    add di, snake_body  ; Point to the last segment
    
.shift_loop:
    mov ax, [di-2]      ; Get the segment in front
    mov [di], ax        ; Move it to current position
    sub di, 2
    loop .shift_loop
    
    ; Now update the head based on direction
    mov al, [snake_body]    ; Current head X
    mov ah, [snake_body+1]  ; Current head Y
    
    cmp byte [snake_dir], 0
    je .up
    cmp byte [snake_dir], 1
    je .right
    cmp byte [snake_dir], 2
    je .down
    ; Left (direction 3)
    dec al
    jmp .done
.up:
    dec ah
    jmp .done
.right:
    inc al
    jmp .done
.down:
    inc ah
.done:
    ; Update head position
    mov [snake_body], al
    mov [snake_body+1], ah
    ret

check_collisions:
    mov si, snake_body
    mov al, [si]      ; Head X position
    mov ah, [si+1]    ; Head Y position
    
    ; Wall collision - smaller grid (40x15)
    cmp al, 20
    jl .fail
    cmp al, 59
    jg .fail
    cmp ah, 5
    jl .fail
    cmp ah, 19
    jg .fail

    ; Self collision
    mov cx, [snake_len]
    dec cx            ; Skip head
    mov si, snake_body
    add si, 2
.check:
    cmp [si], al
    jne .next
    cmp [si+1], ah
    je .fail
.next:
    add si, 2
    loop .check
    clc
    ret
.fail:
    stc
    ret

check_food:
    ; Get head position from snake_body array
    mov si, snake_body
    mov al, [si]      ; Head X position
    mov ah, [si+1]    ; Head Y position
    
    cmp al, [food_x]
    jne .no
    cmp ah, [food_y]
    jne .no
    
    ; When food is eaten, duplicate the last segment
    movzx bx, byte [snake_len]
    shl bx, 1                ; Multiply by 2 (each segment is 2 bytes)
    mov ax, [snake_body + bx - 2]
    mov [snake_body + bx], ax
    
    inc byte [snake_len]
    call generate_food
.no:
    ret

generate_food:
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    xor dx, dx
    mov bx, 40        ; Width of play area (40 columns)
    div bx
    add dl, 20        ; Offset by 20 to stay within bounds (20-59)
    mov [food_x], dl
    mov ax, dx
    xor dx, dx
    mov bx, 15        ; Height of play area (15 rows)
    div bx
    add dl, 5         ; Offset by 5 to stay within bounds (5-19)
    mov [food_y], dl
    ret

draw_screen:
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x0720
    rep stosw

    ; Draw snake
    mov si, snake_body
    movzx cx, byte [snake_len]
.snake:
    mov al, [si]
    mov bl, [si+1]
    xor bh, bh
    imul bx, 80
    add bl, al
    adc bh, 0
    shl bx, 1
    mov word [es:bx], 0x0F2A
    add si, 2
    loop .snake

    ; Draw food
    mov al, [food_x]
    mov bl, [food_y]
    imul bx, 80
    add bl, al
    adc bh, 0
    shl bx, 1
    mov word [es:bx], 0x0E40
    ret

; Data
game_over_msg db 'GG', 0
snake_dir db 1
snake_len db 3
snake_body times 20 db 0
food_x db 10
food_y db 10

times 510 - ($-$$) db 0
dw 0xAA55
