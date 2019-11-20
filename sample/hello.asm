%include "io64.inc"

section .data

_L0:	db "hello world\n", 0		;global string
section .text
 	global main
			
			
main:			;Start of Function 
	mov    rbp, rsp		;SPECIAL RSP to RSB for MAIN only
	mov    r8, rsp		;FUNC header RSP has to be at most RBP
	add    r8, -16,		;adjust Stack Pointer for Activation record
	mov    [r8], rbp		;FUNC header store old BP
	mov [r8+8],rsp		;FUNC header store old SP
	mov    rsp, r8		;FUNC header new SP
			
	PRINT_STRING _L0		;print a string
	NEWLINE		;standard Write a NEWLINE
	mov    rbp,[rsp] 		;FUNC end restore old BP
	mov rsp,[rsp+8]		;FUNC end restore old SP
	mov    rsp,rbp 		;stack and BP need to be same on exit for main 
	ret		
