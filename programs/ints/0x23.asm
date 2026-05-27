;======================================================
;file API for hard disk (LBA)
;AH = 0x01: search a file in root direcory and then copy the content into a buffer      (filename in SI, output buffer in DI)
;AH = 0x02: write a file to the disk and its content to the disk                        (filename in SI, buffer in DI, length of buffer in CX)
;------------------------------------------------------
;Copyright (C) 2026 Technodon
;======================================================
api_openfile:
    ;save data
    push ds
    mov ax, kernel_seg
    mov ds, ax
    mov [buffer_segment], es
    mov [buffer_adress], di

    cmp byte [sub_dir], 1
    je .sub_dir

    xor ax, ax
    mov es, ax
    mov dx, word [root_entries]
    mov di, 0x0500
    pop ds
    jmp openfile_loop
.sub_dir:
    mov ax, dir_seg
    mov es, ax
    xor di, di
    mov dx, [sub_entries]
    pop ds
openfile_loop:
    mov cx, 11
    push si
    push di
    repe cmpsb
    pop di
    pop si
    je .done
    add di, 32
    dec dx
    jnz openfile_loop
    stc
    ret
.done:
    mov ax, kernel_seg
    mov ds, ax

    mov di, [es:di+0x01a]
    mov [program_cluster], di
    mov ax, [buffer_adress]
    mov [program_dap+4], ax
    mov ax, [buffer_segment]
    mov [program_dap+6], ax
.loadfile:

    mov ax, [program_cluster]               ;first cluster of the program
    call cluster_to_sec                     ;get the first sector
    mov [program_dap+8], ax                 ;set LBA
    movzx bx, byte [sec_per_cluster]
    mov [program_dap+2], bx                 ;number of sectors to read
    mov si, program_dap
    call read_sectors
    movzx cx, byte [sec_per_cluster]
    mov ax, 512                                 ;standard size of sector
    mul cx
    add [program_dap+4], ax                     ;add one cluster to the memory adress
    jnc .no_overflow

    add word [program_dap+6], 0x1000
.no_overflow:

    mov bx, [program_cluster]                   ;get the cluster-number
    shl bx, 1                                   ;get FAT offset
    xor ax, ax
    mov ds, ax
    mov ax, [0x3999+bx]                         ;read the value for the next cluster number
    mov dx, kernel_seg
    mov ds, dx
    mov [program_cluster], ax                   ;save the value for next cluster
    cmp ax, 0xFFF8                              ;check if its the last cluster
    jb .loadfile

    ;call copy_filebuffer
    clc
    ret
copy_filebuffer:
    lodsb
    cmp al, 0x0a
    je newline            ;handle carriage return and line feed
    stosb
    loop copy_filebuffer    ;CX--
    ret
newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    stosb
    jmp copy_filebuffer
copyfile_done:
    mov ax, 0x5000
    mov ds, ax
    mov es, ax
    call print_newline
    ret

;--------------------------write file to the disk--------------------------------------
api_write_file:
    push ds
    push si
    mov ax, kernel_seg
    mov ds, ax
    mov [buffer_adress], di
    mov [buffer_segment], bx
    mov [text_length], cx

    cmp byte [sub_dir], 1
    je .search_subdir
    xor di, di
    mov es, di
    mov di, 0x500
    mov dx, [root_entries]
    jmp api_search_root
.search_subdir:
    mov di, dir_seg
    mov es, di
    xor di, di
    mov dx, 512
api_search_root:
    mov al, [es:di]
    cmp al, 0x00
    je .free_entry
    cmp al, 0xe5
    je .free_entry

    add di, 32
    dec dx
    jnz api_search_root

    pop si
    pop ds
    stc
    ret

.free_entry:
    ;calculate clusters
    ;clusters = (size + cluster_size - 1) / cluster_size
    mov ax, 512
    xor bx, bx
    mov bl, [sec_per_cluster]
    mul bx

    mov bx, ax
    mov ax, [text_length]
    add ax, bx
    dec ax

    xor dx, dx
    div bx
    mov cx, ax

    mov bx, 2       ;cluster 0 and 1 are reserved
    xor ax, ax
    mov es, ax
    push di
    xor di, di
api_search_fat:
    mov si, fat_offset
    mov ax, bx            ;cluster number in ax
    shl ax, 1             ;ax * 2
    add si, ax
    mov dx, [es:si]
    cmp dx, 0x0000        ;the entries are 2byte arrays
    je .free_cluster       ;0x0000 = free entry
    inc bx
    jmp api_search_fat

.free_cluster:
    mov si, fat_offset
    mov ax, 0xfff8
    mov dx, bx
    shl dx, 1
    add si, dx
    mov [es:si], ax
    mov ax, kernel_seg
    mov es, ax
    mov [first_cluster], bx
    call api_write_sectors
;     cmp di, 0
;     je .first_cluster

;     push ax
;     mov ax, kernel_seg
;     mov ds, ax
;     pop ax

;     push ax
;     xor ax, ax
;     mov ds, ax
;     pop ax

;     mov ax, di
;     shl ax, 1
;     mov si, fat_offset        ;adress of the FAT
;     add si, ax            ;add the FAT adress our cluster number
;     mov [si], bx          ;mark this FAT adress as reserved
; .first_cluster:
;     cmp word [first_cluster], 0
;     jne .continue
;     mov [first_cluster], bx
; .continue:
;     mov di, bx      ;save cluster
;     push si
    
;     mov ax, kernel_seg
;     mov ds, ax
    
;     mov si, [buffer_adress]

;     call api_write_sectors

;     pop si

;     push cx
;     mov cx, kernel_seg
;     mov ds, cx

;     mov ax, 512
;     xor cx, cx
;     mov cl, [sec_per_cluster]
;     mul cl
;     pop cx

;     add [buffer_adress], ax         ;increase buffer
;     jnc .no_overflow

;     mov [buffer_adress], ax
;     mov ax, [buffer_segment]
;     adc ax, 0
;     mov [buffer_segment], ax
; .no_overflow:

;     push ax
;     xor ax, ax
;     mov ds, ax
;     pop ax
    
;     cmp cx, 1
;     jbe .last_cluster
;     dec cx

;     inc bx
;     jmp api_search_fat

; .last_cluster:
;     mov ax, di
;     shl ax, 1
;     mov si, fat_offset
;     add si, ax
;     mov word [si], 0xfff8
.done:
    pop di

    call write_fat

    cmp byte [sub_dir], 1
    je .write_subdir

    xor ax, ax
    mov es, ax
    jmp .write_entry
.write_subdir:
    mov ax, dir_seg
    mov es, ax
.write_entry:

    pop si
    pop ds

    mov cx, 11
    push di
    rep movsb
    pop di

    mov ax, kernel_seg
    mov ds, ax
    
    mov byte [es:di+0x0b], 0x20     ;archive
    
    mov bx, [first_cluster]
    mov [es:di+0x1a], bx
    mov cx, [text_length]
    mov [es:di+0x1c], cx

    mov word [es:di+0x1e], 0        ;high word

    cmp byte [sub_dir], 1
    je .subdir

    call write_root
    jmp .end
.subdir:
    call write_subdir
.end:
    clc
    ret
api_write_sectors:
    mov ax, bx
    push cx
    call cluster_to_sec
    pop cx

    mov [file_dap+8], ax
    xor ax, ax
    mov al, [sec_per_cluster]
    mov [file_dap+2], ax
    mov ax, [buffer_adress]
    mov [file_dap+4], ax
    mov ax, [buffer_segment]
    mov [file_dap+6], ax
    
    mov ah, 0x43
    mov si, file_dap

    push dx
    xor dx, dx
    mov dl, [drive_number]
    int 0x13
    pop dx

    jc api_write_disk_error
    clc
    ret

api_write_disk_error:
    ;pop si
    pop di
    pop si
    pop ds
    pop bx
    stc
    ret