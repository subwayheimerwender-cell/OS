bits 16
[org 0x500]


start:

    mov ax, 0x03
    int 0x10

    ;print welcome_msg
    mov si, welcome_msg
    call print_start

    ;print os_name
    mov si, os_name
    call print_start
    call shell

hang:
    jmp hang

print_start:
    mov ah, 0x0e
print_loop:
    lodsb           ;loads next byte
    or al, al
    jz done_print
    int 0x10
    jmp print_loop

done_print:
    ret

shell:
    mov si, prompt
    call print_start

; ask user for input
    call read_command

; execute the command
    call exec_cmd
    jmp shell

read_command:
    mov di, command_buffer
    xor cx, cx
read_loop:
    mov ah, 0x00
    int 0x16            ;call BIOS write function
    cmp al, 0x0d        ;check if ENTER was pressed
    je read_end
    cmp al, 0x08        ;
    je handle_backspace
    cmp cx, 255
    jge read_end
    stosb
    mov ah, 0x0e
    mov bl, 0x1f
    int 0x10
    inc cx
    jmp read_loop

handle_backspace:
    cmp di, command_buffer
    je read_loop
    dec di
    dec cx
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    jmp read_loop

read_end:
    mov byte [di], 0
    ret
exec_cmd:
    ; compare input with valid commands
    mov si, command_buffer
    mov di, help_str
    call compare_str
    je help

    mov si, command_buffer
    mov di, clear_str
    call compare_str
    je clear

    ; if unknown command
    call unknown_cmd
    ret
compare_str:
    xor cx, cx
next_char:
    lodsb
    cmp al, [di]
    jne not_equal
    cmp al, 0
    je equal
    inc di
    jmp next_char
not_equal:
    ret
equal:
    ret
help:
    mov si, help_msg
    call print_loop
    ret
clear:
    call clear_screen
    ret
clear_screen:
    mov ax, 0x03
    int 0x10
    ret
unknown_cmd:
    mov si, unknown_msg
    call print_loop
    ret
;================================
; Strings and Buffers
;================================

welcome_msg: db 'Kernel Loaded Successfully. Type HELP For Help.', 0x0d, 0x0a, 0
os_name: db 'Xiromos Bootloader and Kernel v1.0', 0x0d, 0x0a, 0

;commands
help_str: db 'help', 0
clear_str: db 'clear', 0

help_msg: db 'Commands: help(list all commands), clear(clears the screen)', 0x0d, 0x0a, 0
unknown_msg: db 'Invalid command', 0x0d, 0x0a, 0

prompt: db '{User$} ', 0
command_buffer db 25 dup(0)