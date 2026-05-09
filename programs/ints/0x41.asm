;===============================================================
;EXIT 
;AH = 0x01:         exit program and close it
;AH = 0x02:         exit to shell, but leave program active
;===============================================================
;Copyright (C) 2026 Technodon
;---------------------------------------------------------------

exit_program:
    cli
    mov ax, kernel_seg
    mov ds, ax
    mov es, ax

    dec byte [proccess_count]
    xor bx, bx
    mov bl, [current_proccess]
    shl bx, 3

    mov [pcb+bx], word 0
    mov [pcb+bx+2], word 0
    mov [pcb+bx+4], word 0
    mov [pcb+bx+6], word 0
    mov ax, [pcb]
    mov sp, ax
    mov ax, [pcb+2]
    mov ss, ax
    
    ;call scheduler
    ;call load_proccess
    sti
    jmp shell

exit_program_active:
    
    cli
    mov ax, kernel_seg
    mov ds, ax
    mov es, ax

    sti
    jmp shell