%include "io64.inc"

	common x4 800		; define a global variable
section .data

_L0:	db "inside f", 0		;global string
section .text
 	global main
			
			
f:			;Start of Function 
	mov    r8, rsp		;FUNC header RSP has to be at most RBP
	add    r8, -24,		;adjust Stack Pointer for Activation record
	mov    [r8], rbp		;FUNC header store old BP
	mov [r8+8],rsp		;FUNC header store old SP
	mov    rbp, rsp		;FUNC header RSP has to be at most RBP
	mov    rsp, r8		;FUNC header new SP
			
	PRINT_STRING _L0		;print a string
	NEWLINE		;standard Write a NEWLINE
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rsi, [rax]		; load rsi with the ident VALUE 
	PRINT_DEC 8, rsi 		;standard Write a value 
	NEWLINE		;standard Write a NEWLINE
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rax, [rax]		; identifier load memory address 
	mov    rbp,[rsp] 		;FUNC end restore old BP
	mov rsp,[rsp+8]		;FUNC end restore old SP
	ret		; Standard function return
	mov    rbp,[rsp] 		;FUNC end restore old BP
	mov rsp,[rsp+8]		;FUNC end restore old SP
	ret		
			
			
main:			;Start of Function 
	mov    rbp, rsp		;SPECIAL RSP to RSB for MAIN only
	mov    r8, rsp		;FUNC header RSP has to be at most RBP
	add    r8, -40,		;adjust Stack Pointer for Activation record
	mov    [r8], rbp		;FUNC header store old BP
	mov [r8+8],rsp		;FUNC header store old SP
	mov    rsp, r8		;FUNC header new SP
			
	mov rax, 2		; CALL arg is a number
	mov  [rsp+24], rax		; stor arg value in our runtime stack
	mov rbx, rsp		;Copy the stack pointer for call moves
	sub rbx, 32		;rbx is the new target for the function call
	mov rax, [rsp+24]		; Copy actual to rax
	mov [rbx+16], rax		; Copy rax to rbx target
			; about to call a function, set up each parameter in the new activation record
	call f		;CALL to function
mov rdx, rax			;ASSIGN identifier
	mov [rsp + 32], rdx 		; STORE RHS of ASSIGN temporarily
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov  rdx, [rsp+32] 		; FETCH RHS of ASSIGN temporarily
	mov [rax], rdx		; ASSIGN final store 
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rsi, [rax]		; load rsi with the ident VALUE 
	PRINT_DEC 8, rsi 		;standard Write a value 
	NEWLINE		;standard Write a NEWLINE
	mov    rbp,[rsp] 		;FUNC end restore old BP
	mov rsp,[rsp+8]		;FUNC end restore old SP
	mov    rsp,rbp 		;stack and BP need to be same on exit for main 
	ret		
