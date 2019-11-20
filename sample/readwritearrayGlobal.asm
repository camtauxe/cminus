%include "io64.inc"

	common x 40		; define a global variable
section .data

_L0:	db "enter X", 0		;global string
section .text
 	global main
			
			
main:			;Start of Function 
	mov    rbp, rsp		;SPECIAL RSP to RSB for MAIN only
	mov    r8, rsp		;FUNC header RSP has to be at most RBP
	add    r8, -80,		;adjust Stack Pointer for Activation record
	mov    [r8], rbp		;FUNC header store old BP
	mov [r8+8],rsp		;FUNC header store old SP
	mov    rsp, r8		;FUNC header new SP
			
	mov rdx, 0		;ASSIGN a number 
	mov [rsp + 24], rdx 		; STORE RHS of ASSIGN temporarily
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov  rdx, [rsp+24] 		; FETCH RHS of ASSIGN temporarily
	mov [rax], rdx		; ASSIGN final store 
_L1:	 			; WHILE TOP target
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rax, [rax]		;LHS expression is identifier
	mov [rsp+32], rax		;store LHS of expression in memory
	mov rbx, 5		; RHS expresion a number
	mov rax, [rsp+32]		;fetch LHS of expression from memory
	cmp rax, rbx		;EXPR Lessthan
	setl al		;EXPR Lessthan
	mov rbx, 1		;set rbx to one to filter rax
	and rax, rbx		;filter RAX
	mov [rsp+32], rax		;store RHS of expression in memory
	mov rax, [rsp+ 32]		;WHILE expression EXPR
	CMP  rax, 0		;WHILE compare 
	JE  _L2		;WHILE branch out
	PRINT_STRING _L0		;print a string
	NEWLINE		;standard Write a NEWLINE
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rbx, [rax] 		;get value from Identifier
	shl rbx, 3		 ; ARRAy reference needs WSIZE differencing
	mov rax, x 		; global variable on is now rax 
	add rax, rbx		; move add on  rbx as this is an array reference
	GET_DEC 8, [rax]		; READ in an integer 
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rax, [rax]		;LHS expression is identifier
	mov [rsp+40], rax		;store LHS of expression in memory
	mov rbx, 1		; RHS expresion a number
	mov rax, [rsp+40]		;fetch LHS of expression from memory
	add rax, rbx		;EXPR ADD
	mov [rsp+40], rax		;store RHS of expression in memory
	mov rdx, [rsp+40] 		; ASSIGN EXPR
	mov [rsp + 48], rdx 		; STORE RHS of ASSIGN temporarily
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov  rdx, [rsp+48] 		; FETCH RHS of ASSIGN temporarily
	mov [rax], rdx		; ASSIGN final store 
	JMP _L1		;WHILE Jump back
_L2:	 			; End of WHILE 
	mov rdx, 0		;ASSIGN a number 
	mov [rsp + 40], rdx 		; STORE RHS of ASSIGN temporarily
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov  rdx, [rsp+40] 		; FETCH RHS of ASSIGN temporarily
	mov [rax], rdx		; ASSIGN final store 
_L3:	 			; WHILE TOP target
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rax, [rax]		;LHS expression is identifier
	mov [rsp+48], rax		;store LHS of expression in memory
	mov rbx, 5		; RHS expresion a number
	mov rax, [rsp+48]		;fetch LHS of expression from memory
	cmp rax, rbx		;EXPR Lessthan
	setl al		;EXPR Lessthan
	mov rbx, 1		;set rbx to one to filter rax
	and rax, rbx		;filter RAX
	mov [rsp+48], rax		;store RHS of expression in memory
	mov rax, [rsp+ 48]		;WHILE expression EXPR
	CMP  rax, 0		;WHILE compare 
	JE  _L4		;WHILE branch out
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rbx, [rax] 		;get value from Identifier
	shl rbx, 3		 ; ARRAy reference needs WSIZE differencing
	mov rax, x 		; global variable on is now rax 
	add rax, rbx		; move add on  rbx as this is an array reference
	mov rax, [rax]		;LHS expression is identifier
	mov [rsp+56], rax		;store LHS of expression in memory
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rbx, [rax] 		;get value from Identifier
	shl rbx, 3		 ; ARRAy reference needs WSIZE differencing
	mov rax, x 		; global variable on is now rax 
	add rax, rbx		; move add on  rbx as this is an array reference
	mov rbx,  [rax]		;RHS expression is identifier
	mov rax, [rsp+56]		;fetch LHS of expression from memory
	imul rax, rbx		;EXPR MULT
	mov [rsp+56], rax		;store RHS of expression in memory
	mov rsi, [rsp+56]		;write expressin 
	PRINT_DEC 8, rsi 		;standard Write a value 
	NEWLINE		;standard Write a NEWLINE
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov rax, [rax]		;LHS expression is identifier
	mov [rsp+64], rax		;store LHS of expression in memory
	mov rbx, 1		; RHS expresion a number
	mov rax, [rsp+64]		;fetch LHS of expression from memory
	add rax, rbx		;EXPR ADD
	mov [rsp+64], rax		;store RHS of expression in memory
	mov rdx, [rsp+64] 		; ASSIGN EXPR
	mov [rsp + 72], rdx 		; STORE RHS of ASSIGN temporarily
	mov rax, 16		;get Identifier offset
	add rax, rsp		; Add the SP to have direct reference to memory 
	mov  rdx, [rsp+72] 		; FETCH RHS of ASSIGN temporarily
	mov [rax], rdx		; ASSIGN final store 
	JMP _L3		;WHILE Jump back
_L4:	 			; End of WHILE 
	mov    rbp,[rsp] 		;FUNC end restore old BP
	mov rsp,[rsp+8]		;FUNC end restore old SP
	mov    rsp,rbp 		;stack and BP need to be same on exit for main 
	ret		
