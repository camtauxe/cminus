%include "io64.inc"

	common arr 32		;Define global variable
section .data
_STR2:	db "Comparing these numbers:",0		;global string
_STR3:	db "The maximum is",0		;global string
_STR1:	db "That's too many!",0		;global string
_STR0:	db "Enter a number",0		;global string

section .text
	global main


getinput:			;Start of function
	;FUNCTION HEADER
	mov r8, rsp		;get current RSP
	add r8, -24		;Adjust stack pointer according to function size
	mov [r8], rbp		;Store old RBP in activation record
	mov [r8+8], rsp		;Store old RSP in activation record
	mov rsp, r8		;Set new RSP


	;FUNCTION BODY
	;WRITE STRING STATEMENT
	PRINT_STRING _STR0		;Print string
	NEWLINE		
	;READ STATEMENT
	mov rax, 16		;Get Variable offset for in
	add rax, rsp		;Add offset to stack pointer
	GET_DEC 8, [rax]		;Read in value
	;WRITE STATEMENT
	mov rax, 16		;Get Variable offset for in
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	PRINT_DEC 8, rsi		;Write value to output
	NEWLINE		
	;RETURN STATEMENT
	mov rax, 16		;Get Variable offset for in
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return

	;FUNCTION FOOTER
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return


writearr:			;Start of function
	;FUNCTION HEADER
	mov r8, rsp		;get current RSP
	add r8, -56		;Adjust stack pointer according to function size
	mov [r8], rbp		;Store old RBP in activation record
	mov [r8+8], rsp		;Store old RSP in activation record
	mov rsp, r8		;Set new RSP


	;FUNCTION BODY
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	mov rsi, 0		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+24], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+24]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	;LOOP STATEMENT
loop0:	nop		
	;EXPRESSION (<)
	mov rsi, 4		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+32], rsi		;Save Expression RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+32]		;Load temp variable into RBX
	cmp rax, rbx		;Compare RAX and RBX
	setl al		;Get Less than flag
	and rax, 1		;mask RAX to first bit
	mov [rsp+32], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	cmp rsi, 0		;do comparison
	je end1		;If FALSE, jump to loop end
	;BLOCK STATEMENT
	;WRITE STATEMENT
	;ARRAY ACCESS
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbx, rsi		;store offset value in RBX
	shl rbx, 3		;Shift array offset
	mov rax, arr		;Get global variable address
	add rax, rbx		;Add array offset
	mov rsi, [rax]		;Load variable from memory
	PRINT_DEC 8, rsi		;Write value to output
	NEWLINE		
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;EXPRESSION (+)
	mov rsi, 1		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+40], rsi		;Save Expression RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+40]		;Load temp variable into RBX
	add rax, rbx		;perform addition
	mov [rsp+40], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	mov [rsp+48], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+48]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	jmp loop0		;Jump to loop start
end1:	nop		

	;FUNCTION FOOTER
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return


insert:			;Start of function
	;FUNCTION HEADER
	mov r8, rsp		;get current RSP
	add r8, -48		;Adjust stack pointer according to function size
	mov [r8], rbp		;Store old RBP in activation record
	mov [r8+8], rsp		;Store old RSP in activation record
	mov rsp, r8		;Set new RSP


	;FUNCTION BODY
	;IF STATEMENT
	;EXPRESSION (>)
	mov rsi, 3		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+32], rsi		;Save Expression RHS to temp variable
	mov rax, 24		;Get Variable offset for index
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+32]		;Load temp variable into RBX
	cmp rax, rbx		;Compare RAX and RBX
	setg al		;Get Greater Than flag
	and rax, 1		;mask RAX to first bit
	mov [rsp+32], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	cmp rsi, 0		;do comparison
	je else2		;If FALSE, jump to else
	;WRITE STRING STATEMENT
	PRINT_STRING _STR1		;Print string
	NEWLINE		
	jmp endif3		;Jump to endif
else2:	nop		
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	mov rax, 16		;Get Variable offset for value
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov [rsp+40], rsi		;Save assignment RHS to temp variable
	;ARRAY ACCESS
	mov rax, 24		;Get Variable offset for index
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbx, rsi		;store offset value in RBX
	shl rbx, 3		;Shift array offset
	mov rax, arr		;Get global variable address
	add rax, rbx		;Add array offset
	mov rbx, [rsp+40]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
endif3:	nop		

	;FUNCTION FOOTER
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return


getmax:			;Start of function
	;FUNCTION HEADER
	mov r8, rsp		;get current RSP
	add r8, -88		;Adjust stack pointer according to function size
	mov [r8], rbp		;Store old RBP in activation record
	mov [r8+8], rsp		;Store old RSP in activation record
	mov rsp, r8		;Set new RSP


	;FUNCTION BODY
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;ARRAY ACCESS
	mov rsi, 0		;"evaluate" integer literal (NUM_EXPR)
	mov rbx, rsi		;store offset value in RBX
	shl rbx, 3		;Shift array offset
	mov rax, arr		;Get global variable address
	add rax, rbx		;Add array offset
	mov rsi, [rax]		;Load variable from memory
	mov [rsp+32], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for max
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+32]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	mov rsi, 0		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+40], rsi		;Save assignment RHS to temp variable
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+40]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	;LOOP STATEMENT
loop4:	nop		
	;EXPRESSION (<)
	mov rsi, 4		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+48], rsi		;Save Expression RHS to temp variable
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+48]		;Load temp variable into RBX
	cmp rax, rbx		;Compare RAX and RBX
	setl al		;Get Less than flag
	and rax, 1		;mask RAX to first bit
	mov [rsp+48], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	cmp rsi, 0		;do comparison
	je end5		;If FALSE, jump to loop end
	;BLOCK STATEMENT
	;IF STATEMENT
	;EXPRESSION (>)
	mov rax, 16		;Get Variable offset for max
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov [rsp+56], rsi		;Save Expression RHS to temp variable
	;ARRAY ACCESS
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbx, rsi		;store offset value in RBX
	shl rbx, 3		;Shift array offset
	mov rax, arr		;Get global variable address
	add rax, rbx		;Add array offset
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+56]		;Load temp variable into RBX
	cmp rax, rbx		;Compare RAX and RBX
	setg al		;Get Greater Than flag
	and rax, 1		;mask RAX to first bit
	mov [rsp+56], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	cmp rsi, 0		;do comparison
	je else6		;If FALSE, jump to else
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;ARRAY ACCESS
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbx, rsi		;store offset value in RBX
	shl rbx, 3		;Shift array offset
	mov rax, arr		;Get global variable address
	add rax, rbx		;Add array offset
	mov rsi, [rax]		;Load variable from memory
	mov [rsp+64], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for max
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+64]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	jmp endif7		;Jump to endif
else6:	nop		
endif7:	nop		
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;EXPRESSION (+)
	mov rsi, 1		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+72], rsi		;Save Expression RHS to temp variable
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+72]		;Load temp variable into RBX
	add rax, rbx		;perform addition
	mov [rsp+72], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	mov [rsp+80], rsi		;Save assignment RHS to temp variable
	mov rax, 24		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+80]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	jmp loop4		;Jump to loop start
end5:	nop		
	;RETURN STATEMENT
	mov rax, 16		;Get Variable offset for max
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return

	;FUNCTION FOOTER
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	ret		;return


main:			;Start of function
	;FUNCTION HEADER
	mov rbp, rsp		;set RBP to current RSP (MAIN ONLY)
	mov r8, rsp		;get current RSP
	add r8, -88		;Adjust stack pointer according to function size
	mov [r8], rbp		;Store old RBP in activation record
	mov [r8+8], rsp		;Store old RSP in activation record
	mov rsp, r8		;Set new RSP


	;FUNCTION BODY
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	mov rsi, 0		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+32], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+32]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	;LOOP STATEMENT
loop8:	nop		
	;EXPRESSION (<)
	mov rsi, 5		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+40], rsi		;Save Expression RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+40]		;Load temp variable into RBX
	cmp rax, rbx		;Compare RAX and RBX
	setl al		;Get Less than flag
	and rax, 1		;mask RAX to first bit
	mov [rsp+40], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	cmp rsi, 0		;do comparison
	je end9		;If FALSE, jump to loop end
	;BLOCK STATEMENT
	;EXPR_STMT
	;FUNCTION CALL (insert)
	;FUNCTION CALL (getinput)
	call getinput		;call function
	mov [rsp+56], rsi		;save argument to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov [rsp+48], rsi		;save argument to temp variable
	mov rax, rsp		;get stack pointer
	add rax, -40		;get offset for parameter value
	mov rbx, [rsp+56]		;get offset for arg temp variable
	mov [rax], rbx		;save arg value
	mov rax, rsp		;get stack pointer
	add rax, -32		;get offset for parameter value
	mov rbx, [rsp+48]		;get offset for arg temp variable
	mov [rax], rbx		;save arg value
	call insert		;call function
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;EXPRESSION (+)
	mov rsi, 1		;"evaluate" integer literal (NUM_EXPR)
	mov [rsp+64], rsi		;Save Expression RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	mov rax, rsi		;copy RSI to RAX
	mov rbx, [rsp+64]		;Load temp variable into RBX
	add rax, rbx		;perform addition
	mov [rsp+64], rax		;Save expression result to temp variable
	mov rsi, rax		;Save expression result to RSI
	mov [rsp+72], rsi		;Save assignment RHS to temp variable
	mov rax, 16		;Get Variable offset for i
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+72]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	jmp loop8		;Jump to loop start
end9:	nop		
	;WRITE STRING STATEMENT
	PRINT_STRING _STR2		;Print string
	NEWLINE		
	;EXPR_STMT
	;FUNCTION CALL (writearr)
	call writearr		;call function
	;EXPR_STMT
	;ASSIGNMENT EXPRESSION
	;FUNCTION CALL (getmax)
	call getmax		;call function
	mov [rsp+80], rsi		;Save assignment RHS to temp variable
	mov rax, 24		;Get Variable offset for m
	add rax, rsp		;Add offset to stack pointer
	mov rbx, [rsp+80]		;Load temp variable into RBX
	mov [rax], rbx		;Save to LHS
	mov rsi, rbx		;copy to rsi
	;WRITE STRING STATEMENT
	PRINT_STRING _STR3		;Print string
	NEWLINE		
	;WRITE STATEMENT
	mov rax, 24		;Get Variable offset for m
	add rax, rsp		;Add offset to stack pointer
	mov rsi, [rax]		;Load variable from memory
	PRINT_DEC 8, rsi		;Write value to output
	NEWLINE		

	;FUNCTION FOOTER
	mov rbp, [rsp]		;Restore old RBP
	mov rsp,[rsp+8]		;Restore old RSP
	mov rsp, rbp		;RBP and RSP must be same when exiting MAIN
	ret		;return


