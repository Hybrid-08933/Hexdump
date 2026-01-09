default rel

; Define some macros
%define FILENAME_ADDR   [rsp + 0x10]            ; Address of argv[1]
%define BUFF_LEN        0x200                   ; Length of file buffer

; Define registers for holding bytes read, argc, argv, etc
%define BYTES_READ      rbx                     ; RBX - Return value of sys_read
; R12 - Reserved for byte offset column
%define BUFF_OFF        r13                     ; R13 - Buff offset
; R14 - Maybe will be used for output buffer offset
%define CHAR_COUNT      r15                     ; R15 - Number of characters printed so far
;

SECTION .data
    err_msg: db "Usage: hexdump_asm file",0xA   ; Error msg for incorrect usage of program
    err_msg_len: equ $-err_msg                  ; Error msg length
    col_nl: db ":",0xA                          ; A colon and new line
    space: db "    ."                           ; 4 spaces and a dot
    hex_digits: db "0123456789ABCDEF"           ; All the possible hex digits

SECTION .bss
    buff: resb 0x200                            ; A buffer to hold files

SECTION .text

global _start

_start:
    mov rax, [rsp]                              ; Copy argc into rax

    ; Check if a filename was passed
    cmp rax, 0x2                                ; If there aren't two arguments
    jnz err_exit                                ; Print error msg and exit


; Calculate length of the filename passed
filename_len:
    mov rax, FILENAME_ADDR                      ; Move address of argv[1] into rax


; Length counting loop
filename_len_loop:
    inc rdx                                     ; Keep count of arg length
    cmp byte [rax + rdx], 0x0                   ; Compare till Null Terminator
    jne filename_len_loop                       ; is encountered


; Print the filename to the screen
print_filename:
    ; Print the filename itself
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, FILENAME_ADDR                      ; Specify address of argv[1]
                                                ; Length of argv[1] was calculated in filename_len
                                                ; into rdx
    syscall                                     ; Call sys_write

    ; Print a colon and newline after it
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, col_nl                             ; Specify address of ":\n"
    mov rdx, 0x2                                ; Specify length of the string
    syscall                                     ; Call sys_write


; Open the filename passed to the program
open_file:
    mov rax, 0x2                                ; Specify sys_open
    mov rdi, FILENAME_ADDR                      ; Specifyl address of the filename
    mov rsi, 0x0                                ; Specify opening flags 0x0: Read Only
    syscall                                     ; Call sys_open

    push rax                                    ; Save the fd returned by sys_open


; Read the file into a buffer
read_file:
    mov rax, 0x0                                ; Specify sys_read
    pop rdi                                     ; Pop FD from stack into rdi
    mov rsi, buff                               ; Specify buffer address to read into
    mov rdx, BUFF_LEN                           ; Specify length of the buffer
    syscall                                     ; Call sys_read

    test rax, rax                               ; Empty file?
    jz close_file                               ; Close file and exit

    push rdi                                    ; Store FD back onto the stack

    ; Zero out all the counting registers
    xor BUFF_OFF, BUFF_OFF
    xor CHAR_COUNT, CHAR_COUNT
    xor BYTES_READ, BYTES_READ
    ;

    mov BYTES_READ, rax                         ; Save number of bytes read by sys_read


; Print the raw bytes in the file as hex values
; ---How though---
; First rotate transforms the register as follows:
; Ex: 00000000 00000000 ... 01001000 'H'
;         0        1            7
; To: 10000000 00000000 ... 00000100 0x4
;         0        1            7
; giving us the higher 4 bits which can be used as
; a offset in the lookup table
; Second rotate restores the original register
; and then the AND masks the higher 4 bits
; giving us the lower 4 bits
; Perhaps theres a better way of doing this
; Writing the characters into a buffer and then
; printing the entire buffer to screen is the only
; better way I can think of, so buffered O of the I/O
print_hex:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, hex_digits                         ; Specify hex digits
    mov r14b, [buff + BUFF_OFF]                 ; Copy the current character into r14b
    ror r14, 4                                  ; Rotate r14 by 4 bits
    add sil, r14b                               ; Add the resulting number to rsi
    mov rdx, 0x1                                ; Only have one byte to print
    syscall                                     ; Call sys_write

    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, hex_digits                         ; Specify hex digits
    rol r14, 4                                  ; Rotate r14 back into its original state
    and r14b, 0x0F                              ; AND r14 with this mask
    add sil, r14b                               ; Add the resulting number to rsi
    mov rdx, 0x1                                ; Only have one byte to print
    syscall                                     ; Call sys_write

    inc BUFF_OFF                                ; Increment the character offset
    inc CHAR_COUNT                              ; Increment character counter


; Print characters if 16 hex values have been printed
check_char_count:
    cmp BUFF_OFF, BYTES_READ                    ; If all bytes have been printed
    je print_padding                            ; as hex characters

    cmp CHAR_COUNT, 0x10                        ; If 16 characters have been printed
    je print_padding                            ; If not skip printing characters

    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, space                              ; Specify spaces
    mov rdx, 0x2                                ; Two spaces
    syscall                                     ; Call sys_write

    jmp print_hex                               ; Jump back to print_hex


; Print characters
print_ascii:
    cmp CHAR_COUNT, BUFF_OFF                    ; If 16 character have been printed
    je print_newline                            ; print a newline

    mov al, [buff + CHAR_COUNT]                 ; Store current character into al

    cmp al, 0x20                                ; If character is below ' '
    jb print_dot                                ; print a dot

    cmp al, 0x7F                                ; If character is below DEL
    jb print_char                               ; print it

    ; Otherwise execution falls through and prints a dot for DEL


; Print a dot for non printable characters
print_dot:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, space+0x4                          ; Print 5th byte in space
    mov rdx, 0x1                                ; Just one byte
    syscall                                     ; Call sys_write

    inc CHAR_COUNT                              ; Point to next character

    jmp print_ascii                             ; Jump back to process more characters


; Print the ascii character
print_char:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, buff                               ; Specify buffer and add char count
    add rsi, CHAR_COUNT                         ; to it so it points to the correct char
    mov rdx, 0x1                                ; Print one character
    syscall                                     ; Call sys_write

    inc CHAR_COUNT                              ; Point to next character

    jmp print_ascii                             ; Jump back to print_chars otherwise


; Print a newline after characters have been printed
; and jump to read_file if all bytes have been printed
; otherwise jump back to print_hex
print_newline:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, col_nl+0x1                         ; Specify nl
    mov rdx, 0x1                                ; Just need to print two spaces
    syscall                                     ; Call sys_write

    cmp CHAR_COUNT, BYTES_READ                  ; Check if buff offset has reached number of
    je read_file                                ; bytes read and slurp more bytes if it has
    
    xor CHAR_COUNT, CHAR_COUNT                  ; Reset char count

    jmp print_hex                               ; Jump back to printing hex characters


; Prints padding and sets up char count so it can be used as the buff offset
print_padding:
    mov r12, 0x11                               ; Store 17 in 
    sub r12, CHAR_COUNT                         ; Subtract char count to get required padding count
    sub CHAR_COUNT, BUFF_OFF                    ; Subtract buff offset from char count
    neg CHAR_COUNT                              ; Negate the result so char count can be used as the offset


; The loop to print spaces
padding_loop:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, space                              ; Specify space
    mov rdx, 0x4                                ; 4 spaces
    syscall                                     ; Call sys_write

    dec r12                                     ; Decrement r12

    jne padding_loop                            ; keep printing till r12 is 0

    jmp print_ascii                             ; Jump back to print_chars if r12 is 0


; Close the file as good programmers should
close_file:
    mov rax, 0x3                                ; Specify sys_close
    pop rdi                                     ; Pop FD into rdi
    syscall                                     ; Call sys_close


; Exit gracefully
exit:
    mov rax, 0x3c                               ; Specify sys_exit
    mov rdi, 0x0                                ; Specify return value
    syscall                                     ; Call sys_exit


; If no file was specified, print an example of how the
; program should be used to STDERR and exit
err_exit:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x2                                ; Specify STDERR
    mov rsi, err_msg                            ; Error msg
    mov rdx, err_msg_len                        ; Error msg len
    syscall                                     ; Call sys_write

    mov rax, 0x3C                               ; Specify sys_exit
    mov rdi, 0x1                                ; Specify return value
    syscall                                     ; Call sys_exit
