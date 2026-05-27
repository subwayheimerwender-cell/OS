load_interrupts:
    cli
    mov word [0x20*4+2], kernel_seg         ;write segment
    mov word [0x20*4], search_program       ;write offset

    mov word [0x22*4+2], kernel_seg
    mov word [0x22*4], int0x22

    mov word [0x23*4+2], kernel_seg
    mov word [0x23*4], int0x23

    mov word [0x24*4+2], kernel_seg
    mov word [0x24*4], int0x24

    mov word [0x27*4+2], kernel_seg
    mov word [0x27*4], int0x27

    mov word [0x30*4+2], kernel_seg
    mov word [0x30*4], int0x30

    xor ax, ax
    mov es, ax

    ; mov ax, word [es:0x9*4]
    ; mov [int9_addr], ax
    ; mov ax, word [es:0x9*4+2]
    ; mov [int9_addr+2], ax

    ; mov word [es:0x9*4+2], kernel_seg
    ; mov word [es:0x9*4], int0x9

    mov ax, [es:0x8*4]
    mov [int8_off], ax
    mov ax, [es:0x8*4+2]
    mov [int8_seg], ax

    ; mov word [0x8*4+2], kernel_seg
    ; mov word [0x8*4], timer

    mov word [0x41*4+2], kernel_seg
    mov word [0x41*4], int0x41
    mov ax, kernel_seg
    mov es, ax

    ;call setup_pit

    sti
    ret

int0x22:
    cmp ah, 0x01            ;read file
    je search_file
    cmp ah, 0x02            ;write file
    je search_entry
    cmp ah, 0x03            ;list content of root directory
    je get_file_list
    cmp ah, 0x04            ;rename a file
    je rename_file_name
    cmp ah, 0x05            ;delete a file
    je search_filename
    cmp ah, 0x06
    je change_drive
    cmp ah, 0x08
    je parse_arg_loop
    cmp ah, 0x0a
    je change_directory
    cmp ah, 0x0b
    je make_directory
    iret
int0x23:
    cmp ah, 0x01
    je .openfile
    cmp ah, 0x02
    je .api_write_file
    iret
.openfile:
    pusha
    call api_openfile
    popa
    mov cx, [es:di+0x1c]
    iret
.api_write_file:
    pusha
    push ds
    push es
    call api_write_file
    pop es
    pop ds
    popa
    iret
int0x24:
    cmp ah, 0x01
    je check_floppy
    cmp ah, 0x02
    je read_flp_file
    cmp ah, 0x03
    je search_file_flp
    cmp ah, 0x04
    je del_file_flp
    cmp ah, 0x05
    je ren_file_flp
    cmp ah, 0x08
    je flp_search_program
    cmp ah, 0x09
    je flp_change_dir
    cmp ah, 0x0a
    je flp_mkdir
    cmp ah, 0x0b
    je flp_deldir
    iret
int0x27:
    cmp bh, 0x01
    je print_dec
    cmp bh, 0x02
    je print
    cmp bh, 0x03
    je print_hexa
    iret

int0x30:
    cmp ah, 0x01
    je fat8_read_file
    cmp ah, 0x02
    je fat8_write_file
    cmp ah, 0x03
    je fat8_delete_file
    iret

int0x9:
    push ax
    in al, 0x60
    cmp al, 0x53    ;DEL
    je .reboot
    cmp al, 0x58
    je .reboot
    jmp .bios_int0x9
.reboot:
    pop ax
    mov al, 0x20
    out 0x20, al
    jmp reboot
.bios_int0x9:
    pop ax
    push ax
    mov ax, 0xa000
    mov ds, ax
    pop ax
    mov ax, 0xa000
.loop:
    inc ax
    mov ds, ax
    cmp [ds:0x0000], 0
    jne .loop
    mov [ds:0x0000], 1
    push ax
    xor ax, ax
    mov ds, ax
    pop ax
    pushf
    call far [int9_addr]
    push ax
    mov ax, kernel_seg
    mov ds, ax
    pop ax
    mov al, 0x20
    out 0x20, al
    iret

setup_pit:
    cli
    push ds
    push es
    mov al, 0b00110100
    out 0x43, al

    xor ax, ax
    mov ax, 5965                ;11931  ~ 100hz
    out 0x40, al
    mov al, ah
    out 0x40, al

    pop es
    pop ds
    sti
    ret
timer:
    ;stack of the current program
    cli
    pusha
    push ds
    push es

    mov ax, kernel_seg
    mov ds, ax
    call save_proccess
    call scheduler

    ;changes stack
    call load_proccess
    ;loads the data of the next program
    pop es
    pop ds
    popa

    sti
    mov al, 0x20
    out 0x20, al
    iret

int0x41:
    cmp ah, 0x01
    je exit_program
    cmp ah, 0x02
    je exit_program_active
    iret
%include "programs/ints/0x20.asm"
%include "programs/ints/0x22.asm"
%include "programs/ints/0x23.asm"
%include "programs/ints/0x24.asm"
%include "programs/ints/0x27.asm"
%include "programs/ints/0x30.asm"
%include "programs/ints/0x41.asm"