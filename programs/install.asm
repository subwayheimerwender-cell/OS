[org 0x0000]
bits 16

start:
    mov ax, 0x12
    int 0x10

    mov ax, 0x5000
    mov ds, ax
    mov es, ax

    xor ax, ax
    mov cx, 3
    xor bl, bl
    mov dl, 0x80
.loop:
    mov si, dap
    mov ah, 0x42
    int 0x13
    jc no_drive

    inc bl
    inc dl
    dec cx
    jnz .loop
no_drive:
    mov [drives], bl
    
    ;set background
    mov ah, 0x10
    xor al, al
    xor bl, bl
    mov bh, 0x01
    int 0x10

    mov ah, 0x0e
    mov al, 201
    mov bl, 0x0f
    int 0x10

    mov ah, 0x0e
    mov bl, 0x0f
    mov al, 205
    mov cx, 78
.loop1:
    int 0x10
    dec cx
    jnz .loop1

    mov ah, 0x0e
    mov al, 187
    mov bl, 0x0f
    int 0x10

    mov cx, 28

    mov dh, 1
    mov bl, 0x0f
    mov al, 186
    xor dl, dl
.loop2:
    mov ah, 0x02
    xor bh, bh
    int 0x10

    mov ah, 0x0e
    int 0x10

    inc dh

    dec cx
    jnz .loop2

    mov cx, 28
    mov dl, 79
    mov dh, 1
    xor bh, bh
    mov bl, 0x0f
    mov al, 186
.loop3:
    mov ah, 0x02
    int 0x10

    mov ah, 0x0e
    int 0x10

    inc dh

    dec cx
    jnz .loop3

    mov ah, 0x02
    mov dh, 29
    xor dl, dl
    int 0x10

    mov al, 200
    mov ah, 0x0e
    int 0x10

    mov cx, 78
    mov al, 205
    mov ah, 0x0e
    mov bl, 0x0f
.loop4:
    int 0x10
    dec cx
    jnz .loop4


    mov ah, 0x02
    mov dl, 2
    mov dh, 1
    int 0x10


    mov si, available_drives
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
    
    movzx ax, byte [drives]
    mov bh, 0x01
    int 0x27

    mov ah, 0x02
    mov dl, 2
    mov dh, 3
    xor bh, bh
    int 0x10

    mov si, c_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    cmp byte [drives], 2
    jb .done

    mov ah, 0x02
    mov dl, 2
    mov dh, 4
    xor bh, bh
    int 0x10

    mov si, d_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    cmp byte [drives], 3
    jne .done

    mov ah, 0x02
    mov dl, 2
    mov dh, 5
    xor bh, bh
    int 0x10

    mov si, e_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
.done:

    mov ah, 0x02
    mov dl, 2
    mov dh, 7
    xor bh, bh
    int 0x10

    mov si, instruction
    mov bh, 0x02
    mov bl, 0x0f
    int 0x27

    mov ah, 0x02
    mov dl, 2
    mov dh, 9
    xor bh, bh
    int 0x10

.get_key:
    xor ah, ah
    int 0x16

    cmp al, 'q'
    je .quit
    cmp al, '0'
    je .invalid
    cmp al, '1'
    jb .invalid
    cmp al, '3'
    ja .invalid

    sub al, '0'     ;convert to byte
    cmp byte al, [drives]
    ja .invalid_num

    dec al
    add al, 0x80
    mov [drive_number], al
    call clear

    mov ah, 0x03
    int 0x10
    push dx

    mov si, confirm_msg
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27


    xor ah, ah
    int 0x16
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x10

    pop dx
    mov ah, 0x02
    xor bh, bh
    int 0x10

    cmp al, 'y'
    jne .get_key

    mov ah, 0x02
    mov dl, 2
    mov dh, 11
    xor bh, bh
    int 0x10

    mov si, copy_fat
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call load_fat

    mov ah, 0x02
    mov dl, 2
    mov dh, 12
    xor bh, bh
    int 0x10

    mov si, copy_root
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call load_root

    mov ah, 0x02
    mov dl, 2
    mov dh, 13
    xor bh, bh
    int 0x10

    mov si, loading_bpb
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call load_bpb

    mov ah, 0x02
    mov dl, 2
    mov dh, 14
    xor bh, bh
    int 0x10

    mov si, copying_fat_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call write_fat

    mov ah, 0x02
    mov dl, 2
    mov dh, 15
    xor bh, bh
    int 0x10

    mov si, copying_root_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call write_root

    mov ah, 0x02
    mov dl, 2
    mov dh, 16
    xor bh, bh
    int 0x10

    mov si, copying_files_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27

    call copy_files

    mov ah, 0x02
    mov dl, 2
    mov dh, 17
    xor bh, bh
    int 0x10

    mov si, install_success
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
    
    xor ah, ah
    int 0x16
    mov ax, 0x12
    int 0x10
    retf

.invalid:
    call clear
    mov ah, 0x03
    int 0x10

    push dx
    mov si, invalid_key
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
    pop dx

    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .get_key
.already_installed:
    call clear
    mov ah, 0x03
    int 0x10

    push dx
    mov si, alrdy_installed_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
    pop dx

    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .get_key
.invalid_num:
    call clear
    mov ah, 0x03
    int 0x10

    push dx
    mov si, invalid_num_str
    mov bl, 0x0f
    mov bh, 0x02
    int 0x27
    pop dx

    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .get_key

.quit:
    mov ax, 0x12
    int 0x10
    retf





clear:
    mov ah, 0x03
    int 0x10
    push dx
    mov cx, 45
    mov ah, 0x0e
    xor bl, bl
    mov al, 0x20
.clear_loop:
    int 0x10
    dec cx
    jnz .clear_loop

    pop dx
    xor bh, bh
    mov ah, 0x02
    int 0x10
    ret


load_fat:
    xor ax, ax
    mov es, ax
    mov di, 0x7c00

    mov ax, [es:di+14]
    mov [reserved_sectors], ax
    mov ax, [es:di+11]
    mov [bytes_per_sec], ax
    mov al, [es:di+13]
    mov [sec_per_cluster], al
    mov al, [es:di+16]
    mov [num_fat], al
    mov ax, [es:di+17]
    mov [root_entries], ax
    mov al, [es:di+36]
    mov [current_drive], al
    mov ax, [es:di+22]
    mov [fat_size], ax

    movzx bx, byte [num_fat]
    mul bx
    mov [fat_sectors], ax
    add ax, 15
    mov bx, 16
    div bx
    mov cx, ax
    mov ax, 0x5000
    mov es, ax

    mov ax, [reserved_sectors]
    mov [dap+8], ax
    mov [dap+6], word 0x3000            ;load FAT at 0x3000:0x0000
    mov [dap+2], word 16
.loop:
    mov ah, 0x42
    mov dl, [current_drive]
    mov si, dap
    int 0x13
    jc error

    mov ax, [bytes_per_sec]
    mov bx, 16
    mul bx
    add [dap+4], ax
    mov ax, 16
    add [dap+8], ax

    dec cx
    jnz .loop
    ret



error:
    mov ah, 0x03
    int 0x10
    add dh, 1
    mov dl, 2
    mov ah, 0x02
    xor bh, bh
    int 0x10
    mov si, error_msg
    mov bl, 0x04
    mov bh, 0x02
    int 0x27
    xor ah, ah
    int 0x16
    retf





load_root:
    movzx ax, byte [num_fat]
    mov bx, [fat_size]
    mul bx
    add ax, [reserved_sectors]
    mov [dap+8], ax

    mov ax, [root_entries]
    mov bx, 32
    mul bx
    mov bx, [bytes_per_sec]
    div bx
    mov [root_size], ax
    
    mov bx, 16
    div bx
    mov cx, ax
    mov [dap+4], word 0
    mov [dap+6], word 0x4000
    mov ax, 16
    mov [dap+2], ax
.loop:
    mov ah, 0x42
    mov dl, [current_drive]
    mov si, dap
    int 0x13
    jc error

    mov ax, [bytes_per_sec]
    mov bx, 16
    mul bx
    add [dap+4], ax
    add [dap+8], word 16
    dec cx
    jnz .loop
    ret


load_bpb:
    mov [dap+2], word 1
    mov [dap+4], word 0x7e00
    mov [dap+6], word 0x9000
    mov [dap+8], word 0

    mov si, dap
    mov ah, 0x42
    mov dl, [drive_number]
    int 0x13
    jc error

    mov ax, 0x9000
    mov es, ax
    mov di, 0x7e00

    mov ax, [es:di+14]
    mov [ext_reserved_sectors], ax
    mov ax, [es:di+11]
    mov [ext_bytes_per_sec], ax
    mov al, [es:di+16]
    mov [ext_num_fat], al
    mov ax, [es:di+22]
    mov [ext_fat_size], ax
    mov al, [es:di+13]
    mov [ext_sec_per_cluster], al

    mov ax, 0x5000
    mov es, ax
    ret

write_fat:
    xor dx, dx
    mov ax, [fat_sectors]
    add ax, 15
    mov bx, 16
    div bx
    mov cx, ax

    mov [dap+2], word 16
    mov word [dap+4], 0
    mov word [dap+6], 0x3000
    mov ax, [ext_reserved_sectors]
    mov [dap+8], ax
.loop:
    mov si, dap
    mov ah, 0x43
    mov dl, [drive_number]
    int 0x13
    jc error

    add [dap+8], word 16
    mov ax, [ext_bytes_per_sec]
    mov bx, 16
    mul bx
    add [dap+4], ax

    dec cx
    jnz .loop

    ret

write_root:
    xor dx, dx
    movzx ax, byte [ext_num_fat]
    mov bx, [ext_fat_size]
    mul bx
    add ax, [ext_reserved_sectors]
    mov [ext_root_start], ax
    mov [dap+8], ax
    mov [dap+2], 16

    mov ax, [root_size]
    add ax, 15
    mov bx, 16
    div ax
    mov cx, ax
    mov [dap+4], word 0
    mov [dap+6], word 0x4000
.loop:
    mov si, dap
    mov ah, 0x43
    mov dl, [drive_number]
    int 0x13
    jc error

    add [dap+8], word 16
    mov ax, [ext_bytes_per_sec]
    mov bx, 16
    mul bx
    add [dap+4], ax

    dec cx
    jnz .loop

    ret

copy_files:
    movzx ax, byte [num_fat]
    mov bx, [fat_size]
    mul bx
    add ax, [reserved_sectors]

    add ax, [root_size]
    mov [cur_data_start], ax
    mov ax, [ext_root_start]
    add ax, [root_size]
    mov [data_start], ax

    mov ax, 0x7000
    mov es, ax
    xor di, di

    movzx ax, byte [ext_sec_per_cluster]
    mov [dap+2], ax
    mov [dap+4], word 0
    mov [dap+6], word 0x7000
.loop:
    mov ax, [cur_data_start]
    mov [dap+8], ax

    mov si, dap
    mov dl, [current_drive]
    mov ah, 0x42
    int 0x13
    jc error

    movzx ax, byte [ext_sec_per_cluster]
    add [cur_data_start], ax

    cmp dword [es:di], 0
    je .done

    mov ax, [data_start]
    mov [dap+8], ax

    mov si, dap
    xor al, al
    mov dl, [drive_number]
    mov ah, 0x43
    int 0x13
    jc error

    movzx ax, byte [ext_sec_per_cluster]
    add [data_start], ax
    jmp .loop

.done:
    ret
;====data====

dap:
    db 0x10
    db 0
    dw 1
    dw 0x0000
    dw 0x8000
    dq 0
drives: db 0
drive_number: db 0
current_drive: db 0
available_drives: db 'Available drives to install: ', 0
c_str: db '[1] C:\', 0
d_str: db '[2] D:\', 0
e_str: db '[3] E:\', 0
instruction: db 'Press 1, 2 or 3 to chose a drive or "q" to quit', 0
invalid_key: db 'Invalid key pressed', 0
alrdy_installed_str: db 'This OS is already installed on this drive', 0
invalid_num_str: db 'Not an existing drive', 0
confirm_msg: db 'Are you sure? All data will be deleted (y/n)', 0
copy_fat: db 'Loading FAT...', 0
copy_root: db 'Loading Root Directory...', 0
loading_bpb: db 'Loading boot sector...', 0
copying_fat_str: db 'Copying FAT...', 0
copying_root_str: db 'Copying Root Directory...', 0
copying_files_str: db 'Copying files...', 0
install_success: db 'Successfully installed OS. Press a key to finish', 0
reserved_sectors: dw 0
bytes_per_sec: dw 0
sec_per_cluster: db 0
root_entries: dw 0
fat_size: dw 0
num_fat: db 0

fat_sectors: dw 0
root_size: dw 0
cur_data_start: dw 0

ext_root_start: dw 0


ext_reserved_sectors: dw 0
ext_bytes_per_sec: dw 0
ext_sec_per_cluster: db 0
ext_root_entries: dw 0
ext_fat_size: dw 0
ext_num_fat: db 0
data_start: dw 0
error_msg: db 'Error while installing OS...', 0