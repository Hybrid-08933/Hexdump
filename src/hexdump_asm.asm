default rel

; Define some macros
%define FILENAME_ADDR   [rsp + 0x10]            ; Address of argv[1]
%define BUFF_LEN        0x10000                 ; Length of file buffer

; Define registers for holding bytes read, argc, argv, etc
%define BYTES_READ      rbx                     ; RBX - Return value of sys_read
; R12 - Reserved for byte offset column
%define BUFF_OFF        r13                     ; R13 - Buff offset
%define BUFF_OUT_OFF    r14                     ; R14 - Maybe will be used for output buffer offset
%define CHAR_COUNT      r15                     ; R15 - Number of characters printed so far
;

SECTION .data
    err_msg: db "Usage: hexdump_asm file",0xA   ; Error msg for incorrect usage of program
    err_msg_len: equ $-err_msg                  ; Error msg length
    col_nl: db ":",0xA                          ; A colon and new line
    space: db "    ."                           ; 4 spaces and a dot
    dot: db ":"
    hex_table:                                  ; Make a lookup table for hex values
        dw 0x3030, 0x3130, 0x3230, 0x3330, 0x3430, 0x3530, 0x3630, 0x3730,
        dw 0x3830, 0x3930, 0x4130, 0x4230, 0x4330, 0x4430, 0x4530, 0x4630,
        dw 0x3031, 0x3131, 0x3231, 0x3331, 0x3431, 0x3531, 0x3631, 0x3731,
        dw 0x3831, 0x3931, 0x4131, 0x4231, 0x4331, 0x4431, 0x4531, 0x4631,
        dw 0x3032, 0x3132, 0x3232, 0x3332, 0x3432, 0x3532, 0x3632, 0x3732,
        dw 0x3832, 0x3932, 0x4132, 0x4232, 0x4332, 0x4432, 0x4532, 0x4632,
        dw 0x3033, 0x3133, 0x3233, 0x3333, 0x3433, 0x3533, 0x3633, 0x3733,
        dw 0x3833, 0x3933, 0x4133, 0x4233, 0x4333, 0x4433, 0x4533, 0x4633,
        dw 0x3034, 0x3134, 0x3234, 0x3334, 0x3434, 0x3534, 0x3634, 0x3734,
        dw 0x3834, 0x3934, 0x4134, 0x4234, 0x4334, 0x4434, 0x4534, 0x4634,
        dw 0x3035, 0x3135, 0x3235, 0x3335, 0x3435, 0x3535, 0x3635, 0x3735,
        dw 0x3835, 0x3935, 0x4135, 0x4235, 0x4335, 0x4435, 0x4535, 0x4635,
        dw 0x3036, 0x3136, 0x3236, 0x3336, 0x3436, 0x3536, 0x3636, 0x3736,
        dw 0x3836, 0x3936, 0x4136, 0x4236, 0x4336, 0x4436, 0x4536, 0x4636,
        dw 0x3037, 0x3137, 0x3237, 0x3337, 0x3437, 0x3537, 0x3637, 0x3737,
        dw 0x3837, 0x3937, 0x4137, 0x4237, 0x4337, 0x4437, 0x4537, 0x4637,
        dw 0x3038, 0x3138, 0x3238, 0x3338, 0x3438, 0x3538, 0x3638, 0x3738,
        dw 0x3838, 0x3938, 0x4138, 0x4238, 0x4338, 0x4438, 0x4538, 0x4638,
        dw 0x3039, 0x3139, 0x3239, 0x3339, 0x3439, 0x3539, 0x3639, 0x3739,
        dw 0x3839, 0x3939, 0x4139, 0x4239, 0x4339, 0x4439, 0x4539, 0x4639,
        dw 0x3041, 0x3141, 0x3241, 0x3341, 0x3441, 0x3541, 0x3641, 0x3741,
        dw 0x3841, 0x3941, 0x4141, 0x4241, 0x4341, 0x4441, 0x4541, 0x4641,
        dw 0x3042, 0x3142, 0x3242, 0x3342, 0x3442, 0x3542, 0x3642, 0x3742,
        dw 0x3842, 0x3942, 0x4142, 0x4242, 0x4342, 0x4442, 0x4542, 0x4642,
        dw 0x3043, 0x3143, 0x3243, 0x3343, 0x3443, 0x3543, 0x3643, 0x3743,
        dw 0x3843, 0x3943, 0x4143, 0x4243, 0x4343, 0x4443, 0x4543, 0x4643,
        dw 0x3044, 0x3144, 0x3244, 0x3344, 0x3444, 0x3544, 0x3644, 0x3744,
        dw 0x3844, 0x3944, 0x4144, 0x4244, 0x4344, 0x4444, 0x4544, 0x4644,
        dw 0x3045, 0x3145, 0x3245, 0x3345, 0x3445, 0x3545, 0x3645, 0x3745,
        dw 0x3845, 0x3945, 0x4145, 0x4245, 0x4345, 0x4445, 0x4545, 0x4645,
        dw 0x3046, 0x3146, 0x3246, 0x3346, 0x3446, 0x3546, 0x3646, 0x3746,
        dw 0x3846, 0x3946, 0x4146, 0x4246, 0x4346, 0x4446, 0x4546, 0x4646

SECTION .bss
    buff: resb BUFF_LEN                         ; A buffer to hold files
    buff_out: resb 278528                       ; A buffer to hold output

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

    mov BUFF_OUT_OFF, buff_out                  ; Set r14 to buff_out


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
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, hex_digits                         ; Specify hex digits
;    mov r14b, [buff + BUFF_OFF]                 ; Copy the current character into r14b
;    ror r14, 4                                  ; Rotate r14 by 4 bits
;    add sil, r14b                               ; Add the resulting number to rsi
;    mov rdx, 0x1                                ; Only have one byte to print
;    syscall                                     ; Call sys_write
;
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, hex_digits                         ; Specify hex digits
;    rol r14, 4                                  ; Rotate r14 back into its original state
;    and r14b, 0x0F                              ; AND r14 with this mask
;    add sil, r14b                               ; Add the resulting number to rsi
;    mov rdx, 0x1                                ; Only have one byte to print
;    syscall                                     ; Call sys_write

    mov al,  [buff + BUFF_OFF]                  ; Copy current character into al
    lea rsi, [hex_table + rax * 2]              ; Lookup its hex representation
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rdx, 0x2                                ; Print 2 bytes
;    syscall                                     ; Call sys_write
    mov ax, WORD [rsi]
    mov [BUFF_OUT_OFF], ax
    add BUFF_OUT_OFF, 0x2                       ; Move BUFF_OUT_OFF ahead by 2 bytes

    inc BUFF_OFF                                ; Increment the character offset
    inc CHAR_COUNT                              ; Increment character counter


; Print characters if 16 hex values have been printed
check_char_count:
    cmp BUFF_OFF, BYTES_READ                    ; If all bytes have been printed
    je print_padding                            ; as hex characters

    cmp CHAR_COUNT, 0x10                        ; If 16 characters have been printed
    je print_padding                            ; If not skip printing characters

;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, space                              ; Specify spaces
;    mov rdx, 0x1                                ; Two spaces
;    syscall                                     ; Call sys_write
    xor rax, rax
    mov al, 0x20
    mov [BUFF_OUT_OFF], al
    inc BUFF_OUT_OFF

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
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, space+0x4                          ; Print 5th byte in space
;    mov rdx, 0x1                                ; Just one byte
;    syscall                                     ; Call sys_write
    mov al, BYTE [space + 0x4]
    mov [BUFF_OUT_OFF], al
    inc BUFF_OUT_OFF

    inc CHAR_COUNT                              ; Point to next character

    jmp print_ascii                             ; Jump back to process more characters


; Print the ascii character
print_char:
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, buff                               ; Specify buffer and add char count
;    add rsi, CHAR_COUNT                         ; to it so it points to the correct char
;    mov rdx, 0x1                                ; Print one character
;    syscall                                     ; Call sys_write

    lea rsi, [buff + CHAR_COUNT]
    mov al, BYTE [rsi]
    mov [BUFF_OUT_OFF], al
    inc BUFF_OUT_OFF

    inc CHAR_COUNT                              ; Point to next character

    jmp print_ascii                             ; Jump back to print_chars otherwise


; Print a newline after characters have been printed
; and jump to read_file if all bytes have been printed
; otherwise jump back to print_hex
print_newline:
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, col_nl+0x1                         ; Specify nl
;    mov rdx, 0x1                                ; Just need to print two spaces
;    syscall                                     ; Call sys_write
    mov al, BYTE [col_nl+0x1]
    mov [BUFF_OUT_OFF], al
    inc BUFF_OUT_OFF

    cmp CHAR_COUNT, BYTES_READ                  ; Check if buff offset has reached number of
    je flush_buff                               ; bytes read and slurp more bytes if it has

    xor CHAR_COUNT, CHAR_COUNT                  ; Reset char count

    jmp print_hex                               ; Jump back to printing hex characters


; Prints padding and sets up char count so it can be used as the buff offset
print_padding:
    mov rax, 0x11                               ; Store 17 in r12
    sub rax, CHAR_COUNT                         ; Subtract char count to get required padding count
    sub CHAR_COUNT, BUFF_OFF                    ; Subtract buff offset from char count
    neg CHAR_COUNT                              ; Negate the result so char count can be used as the offset
    mov esi, dword [space]

; The loop to print spaces
padding_loop:
;    mov rax, 0x1                                ; Specify sys_write
;    mov rdi, 0x1                                ; Specify STDOUT
;    mov rsi, space                              ; Specify space
;    mov rdx, 0x4                                ; 4 spaces
;    syscall                                     ; Call sys_write
    mov [BUFF_OUT_OFF], esi
    add BUFF_OUT_OFF, 0x4

    dec rax                                     ; Decrement rax

    jne padding_loop                            ; keep printing till rax is 0

    jmp print_ascii                             ; Jump back to print_chars if rax is 0


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


flush_buff:
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, buff_out
    mov rdx, 278528
    syscall
    jmp read_file


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
