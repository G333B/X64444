global write
global read
global exit
global nano_sleep
global execve
global dup2

section .text

write:
    mov rax, 1 
    syscall
    ret

read:
    mov rax , 0   
    syscall
    ret        

exit:
    mov rax, 60
    syscall
    ret

nano_sleep:
    mov rax, 35
    syscall
    ret

execve:
    mov rax, 59
    syscall
    ret

dup2:
    mov rax, 33
    syscall
    ret