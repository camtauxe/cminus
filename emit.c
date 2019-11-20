/**
 * Implmentation of emit.h (see header file for details)
 * 
 * Cameron Tauxe
 * 
 * 16 April, 2018
 * 	- Initial Version
 * 20 April, 2018
 *	- Implemented Strings and WRITE_STR_STMTs
 *	- Fixed Assignment Expressions not saving value in RSI
 *	- Implemented handling of simple expressions
 * 21 April, 2018
 *	- Implemented Array access
 *	- Implemented IF_STMT, LOOP_STMT and READ_STMT
 * 23 April, 2018
 * 	- Fixed RBP being set when it shouldn't in non-MAIN functions
 * 26 April, 2018
 * 	- Fixed incorrect behavior when a function call uses other function calls
 * 		in its arguments
 **/

#include <string.h>
#include <stdio.h>
#include "emit.h"

//Size of a single data word (in bytes)
#define WORDSIZE 8
#define LOGWORDSIZE 3

//emit_write_all implmentation
void emit_all(char *filename, AST_Node *prog_root) {
	//Check that prog_root is valid
	if (prog_root == NULL) {
		fprintf(stderr,"Given program root was NULL. Cannot emit program!\n");
		return;
	}
	if (prog_root->type != PROGRAM) {
		fprintf(stderr,"Given program root must be type PROGRAM. Cannot emit program!\n");
		return;
	}

	//Open output file
	emit_file = fopen(filename,"w");
	if (emit_file == NULL) {
		fprintf(stderr,"Cannot open output file '%s'!\n",filename);
		return;
	}
	emit_file_set = 1;

	//Write header
	emit_head(prog_root->next);

	//Write functions
	//(iterate through declarations writing any FUN_DECLS)
	AST_Node *p = prog_root->next;
	while (p != NULL) {
		if (p->type == FUN_DECL) {
			emit_function(p);
			emit_newline(); emit_newline();
		}
		p = p->next;
	}
}

//emit_write_head implementation
void emit_head(AST_Node *first_decl) {
	AST_Node *p; //pointer when iterating through AST

	//Write include statement
	emit_write_plain_line("%include \"io64.inc\"");
	emit_newline();

	//Parse for and write global variables
	p = first_decl;
	while (p != NULL) {
		if (p->type == VAR_DECL) {
			char buffer[100];
			sprintf(buffer,"common %s %d",p->name,p->symbol->size*WORDSIZE);
			emit_write_line("",buffer,";Define global variable");
		}
		p = p->next;
	}

	//Write .data section
	emit_write_plain_line("section .data");
	emit_search_strings(first_decl);

	emit_newline();

	//Write .text section
	emit_write_plain_line("section .text");

	//Check if a main function is declared and
	//write "global main" if it is
	p = first_decl;
	while (p != NULL) {
		if (p->type == FUN_DECL && strcmp(p->name,"main") == 0) {
			emit_write_plain_line("\tglobal main");
			break;
		}
		p = p->next;
	}

	emit_newline(); emit_newline();
}

//emit_search_strings implementation
void emit_search_strings(AST_Node *root) {
	//Base case: Return immediately if root is NULL
	if (root == NULL)
		return;
	
	
	if (root->type == WRITE_STR_STMT) {
		char label[100];
		char string[100];
		sprintf(label,"_STR%d:",root->value);
		sprintf(string,"db %s,0",root->name);
		emit_write_line(label,string,";global string");
	}
	
	//Recursive case: search all children of root
	emit_search_strings(root->next);
	emit_search_strings(root->s1.any);
	emit_search_strings(root->s2.any);
	emit_search_strings(root->s3.any);
}

//emit_write_function implementation
void emit_function(AST_Node *fun_decl) {
	//Check fun_decl is valid
	if (fun_decl == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit error! emit_function called with NULL node.\n");
		return;
	}
	if (fun_decl->type != FUN_DECL) {
		if (emit_debug)
			fprintf(stderr,"Emit error! emit_function called non-FUN_DECL node.\n");
		return;
	}

	//buffer for writing lines
	char buffer[100];

	//Write label
	sprintf(buffer,"%s:",fun_decl->name);
	emit_write_line(buffer,"",";Start of function");

	//Write function header
	emit_write_plain_line("\t;FUNCTION HEADER");
	if (strcmp(fun_decl->name,"main") == 0)
		emit_write_line("","mov rbp, rsp",";set RBP to current RSP (MAIN ONLY)");
	emit_write_line("","mov r8, rsp",";get current RSP");
	sprintf(buffer,"add r8, %d",(fun_decl->value*WORDSIZE)*-1);
	emit_write_line("",buffer,";Adjust stack pointer according to function size");
	emit_write_line("","mov [r8], rbp",";Store old RBP in activation record");
	emit_write_line("","mov [r8+8], rsp",";Store old RSP in activation record");
	emit_write_line("","mov rsp, r8",";Set new RSP");
	emit_newline();

	//Write function body
	emit_newline();
	emit_write_plain_line("\t;FUNCTION BODY");
	//iterate through statements
	AST_Node *p = fun_decl->s2.fun_body->s2.block_stmts;
	while (p != NULL) {
		emit_statement(p);
		p = p->next;
	}
	emit_newline();

	//Write function footer
	emit_write_plain_line("\t;FUNCTION FOOTER");
	emit_write_line("","mov rbp, [rsp]",";Restore old RBP");
	emit_write_line("","mov rsp,[rsp+8]",";Restore old RSP");
	if (strcmp(fun_decl->name,"main") == 0)
		emit_write_line("","mov rsp, rbp",";RBP and RSP must be same when exiting MAIN");
	emit_write_line("","ret",";return");
}

//emit_statement implementation
void emit_statement(AST_Node *stmt) {
	//Check that stmt is not NULL
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_statement called with NULL node.\n");
		return;
	}

	//Switch depending on statement type
	switch (stmt->type) {
		case BLOCK:				emit_block_stmt(stmt);		break;
		case IF_STMT:			emit_if_stmt(stmt);			break;
		case LOOP_STMT:			emit_loop_stmt(stmt);		break;
		case READ_STMT:			emit_read_stmt(stmt);		break;
		case RET_STMT:			emit_ret_stmt(stmt);		break;
		case WRITE_STMT:		emit_write_stmt(stmt);		break;
		case WRITE_STR_STMT:	emit_write_str_stmt(stmt);	break;
		case EXPR_STMT:			emit_expr_stmt(stmt);		break;
		default:
			if (emit_debug)
				fprintf(stderr,"Emit Error! emit_statement called with invalid node type.\n");
	}
}

//emit_block_stmt implementation
void emit_block_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_block_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != BLOCK) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_block_stmt called with non-BLOCK node.\n");
		return;
	}

	emit_write_plain_line("\t;BLOCK STATEMENT");
	//iterate through statements in block
	AST_Node *p = stmt->s2.block_stmts;
	while (p != NULL) {
		emit_statement(p);
		p = p->next;
	}
}

//emit_if_stmt implementation
void emit_if_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_if_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != IF_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_if_stmt called with non-IF_STMT node.\n");
		return;
	}
	
	char label_buffer[100];
	char line_buffer[100];
	
	//Get numbers for the endif and else labels
	int else_id = emit_labels;
	emit_labels++;
	int endif_id = emit_labels;
	emit_labels++;
	
	//Write statement
	emit_write_plain_line("\t;IF STATEMENT");
	//Evaluate condition expression
	emit_handle_expr(stmt->s1.condition); //value will be in RSI
	//compare and jump
	emit_write_line("","cmp rsi, 0",";do comparison");
	sprintf(line_buffer,"je else%d",else_id);
	emit_write_line("",line_buffer,";If FALSE, jump to else");
	//write TRUE statement
	emit_statement(stmt->s2.if_body);
	sprintf(line_buffer,"jmp endif%d",endif_id);
	emit_write_line("",line_buffer,";Jump to endif");
	//write ELSE label
	sprintf(label_buffer,"else%d:",else_id);
	emit_write_line(label_buffer,"nop","");
	//write ELSE statement
	if (stmt->s3.else_body != NULL) {
		emit_statement(stmt->s3.else_body);
	}
	//write endif
	sprintf(label_buffer,"endif%d:",endif_id);
	emit_write_line(label_buffer,"nop","");
}

//emit_loop_stmt implementation
void emit_loop_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_loop_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != LOOP_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_loop_stmt called with non-LOOP_STMT node.\n");
		return;
	}
	
	char label_buffer[100];
	char line_buffer[100];
	
	//Get numbers for loop and end labels
	int loop_id = emit_labels;
	emit_labels++;
	int end_id = emit_labels;
	emit_labels++;
	
	//Write statement
	emit_write_plain_line("\t;LOOP STATEMENT");
	//Write loop start
	sprintf(label_buffer,"loop%d:",loop_id);
	emit_write_line(label_buffer,"nop","");
	//Evaluate loop condition expression
	emit_handle_expr(stmt->s1.condition);//value will be in RSI
	//compare and jump
	emit_write_line("","cmp rsi, 0",";do comparison");
	sprintf(line_buffer,"je end%d",end_id);
	emit_write_line("",line_buffer,";If FALSE, jump to loop end");
	//Write loop body
	emit_statement(stmt->s2.loop_body);
	sprintf(line_buffer,"jmp loop%d",loop_id);
	emit_write_line("",line_buffer,";Jump to loop start");
	//Write loop end
	sprintf(label_buffer,"end%d:",end_id);
	emit_write_line(label_buffer,"nop","");
}

//emit_read_stmt implementation
void emit_read_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_read_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != READ_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_read_stmt called with non-READ_STMT node.\n");
		return;
	}
	
	//Write statement
	emit_write_plain_line("\t;READ STATEMENT");
	//Get variable address
	emit_handle_var(stmt->s1.var);//Address will be in RAX
	//Read in number
	emit_write_line("","GET_DEC 8, [rax]",";Read in value");
}

//emit_ret_stmt implementation
void emit_ret_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_ret_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != RET_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_ret_stmt called with non-RET_STMT node.\n");
		return;
	}

	//Write statement
	emit_write_plain_line("\t;RETURN STATEMENT");
	//Evaluate expression
	if (stmt->s1.expr != NULL) {
		emit_handle_expr(stmt->s1.expr);//value will be in RSI
	}
	//Restore old RBP and RSP
	emit_write_line("","mov rbp, [rsp]",";Restore old RBP");
	emit_write_line("","mov rsp,[rsp+8]",";Restore old RSP");
	emit_write_line("","ret",";return");
}

//emit_write_stmt implementation
void emit_write_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_write_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != WRITE_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_write_stmt called with non-WRITE_STMT node.\n");
		return;
	}

	//Write statement
	emit_write_plain_line("\t;WRITE STATEMENT");
	//evaluate expression
	emit_handle_expr(stmt->s1.expr);
	//write
	emit_write_line("","PRINT_DEC 8, rsi",";Write value to output");
	emit_write_line("","NEWLINE","");
}

//emit_write_string_stmt
void emit_write_str_stmt(AST_Node * stmt) {
	char buffer[100];
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_write_str_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != WRITE_STR_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_write_str_stmt called with non-WRITE_STR_STMT node.\n");
		return;
	}
	
	//Write statement
	emit_write_plain_line("\t;WRITE STRING STATEMENT");
	sprintf(buffer,"PRINT_STRING _STR%d",stmt->value);
	emit_write_line("",buffer,";Print string");
	emit_write_line("","NEWLINE","");
}

//emit_expr_stmt implementation
void emit_expr_stmt(AST_Node *stmt) {
	//Check that stmt is valid
	if (stmt == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_expr_stmt called with NULL node.\n");
		return;
	}
	if (stmt->type != EXPR_STMT) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_expr_stmt called with non-EXPR-STMT node.\n");
		return;
	}

	//Write statement
	emit_write_plain_line("\t;EXPR_STMT");
	//Execute expression
	emit_handle_expr(stmt->s1.expr);

}

//emit_handle_expr implementation
void emit_handle_expr(AST_Node *expr) {
	//buffer for writing lines
	char buffer[100];
	
	//Check that expr is not NULL
	if (expr == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_handle_expr called with NULL node.\n");
		return;
	}

	//Switch depending on expression type
	switch (expr->type) {
		case ASS_EXPR:
			emit_write_plain_line("\t;ASSIGNMENT EXPRESSION");
			//evaluate and save RHS
			emit_handle_expr(expr->s2.expr);//value will be in RSI
			sprintf(buffer,"mov [rsp+%d], rsi",expr->symbol->offset*WORDSIZE);
			emit_write_line("",buffer,";Save assignment RHS to temp variable");
			//Get LHS address
			emit_handle_var(expr->s1.var);//address will be in RAX
			sprintf(buffer,"mov rbx, [rsp+%d]",expr->symbol->offset*WORDSIZE);
			emit_write_line("",buffer,";Load temp variable into RBX");
			emit_write_line("","mov [rax], rbx",";Save to LHS");
			//copy to rsi
			emit_write_line("","mov rsi, rbx",";copy to rsi");
			break;
		case NUM_EXPR:
			sprintf(buffer,"mov rsi, %d",expr->value);
			emit_write_line("",buffer,";\"evaluate\" integer literal (NUM_EXPR)");
			break;
		case VAR_EXPR:
			emit_handle_var(expr);//address will be in RAX
			emit_write_line("","mov rsi, [rax]",";Load variable from memory");
			break;
		case SIMP_EXPR:
			sprintf(buffer,"\t;EXPRESSION (%s)",operator_to_string(expr->op));
			emit_write_plain_line(buffer);
			//evaluate and save RHS
			emit_handle_expr(expr->s2.expr_right);//value will be in RSI
			sprintf(buffer,"mov [rsp+%d], rsi",expr->symbol->offset*WORDSIZE);
			emit_write_line("",buffer,";Save Expression RHS to temp variable");
			//evaluate LHS
			emit_handle_expr(expr->s1.expr_left);//value will be in RSI
			emit_write_line("","mov rax, rsi",";copy RSI to RAX");
			//perform operation
			sprintf(buffer,"mov rbx, [rsp+%d]",expr->symbol->offset*WORDSIZE);
			emit_write_line("",buffer,";Load temp variable into RBX");
			emit_handle_operator(expr->op);//result will be in RAX
			//save result to temp variable and rsi
			sprintf(buffer,"mov [rsp+%d], rax",expr->symbol->offset*WORDSIZE);
			emit_write_line("",buffer,";Save expression result to temp variable");
			emit_write_line("","mov rsi, rax",";Save expression result to RSI");
			break;
		case CALL_EXPR:
			sprintf(buffer,"\t;FUNCTION CALL (%s)",expr->name);
			emit_write_plain_line(buffer);
			//iterate through parameters and arguments
			AST_Node *arg = expr->s1.call_args;
			AST_Node *param = expr->symbol->declaration->s1.fun_params;
			//Iterate through arguments, evaluating and storing in temp vars
			while (arg != NULL) {
				//Evaluate
				emit_handle_expr(arg->s1.expr);//value will be in RSI
				//Save to temporary variable
				sprintf(buffer,"mov [rsp+%d], rsi",arg->symbol->offset*WORDSIZE);
				emit_write_line("",buffer,";save argument to temp variable");
				arg = arg->next;
			}
			//Once all args have been evaluated, iterate through args and parameters,
			//copying values to the their spot on the stack once the function is called
			arg = expr->s1.call_args;//reset arg to first argument
			//get the offset_base (essentially what RSP will be after the function is called)
			int offset_base = expr->symbol->declaration->value + 1; //the 1 is for the program counter
			while (arg != NULL && param != NULL) {
				//Save arg value to stack (or rather where it will be on the stack after the call)
				emit_write_line("","mov rax, rsp",";get stack pointer");
				sprintf(buffer,"add rax, %d",((offset_base*-1)+param->symbol->offset)*WORDSIZE);
				emit_write_line("",buffer,";get offset for parameter value");
				sprintf(buffer,"mov rbx, [rsp+%d]",arg->symbol->offset*WORDSIZE);
				emit_write_line("",buffer,";get offset for arg temp variable");
				emit_write_line("","mov [rax], rbx",";save arg value");
				arg = arg->next;
				param = param->next;
			}
			if ((arg != NULL || param != NULL) && emit_debug) {
				fprintf(stderr,"Emit Error! function call has inequal number of parameters and arguments!\n");
			}
			//call function
			sprintf(buffer,"call %s",expr->name);
			emit_write_line("",buffer,";call function");
			//return value will be in RSI
			break;
		default:
			if (emit_debug)
				fprintf(stderr,"Emit Error! emit_handle_expr called with invalid node type.\n");
	}
}

//emit_handle_operator implementation
void emit_handle_operator(OPERATOR op) {
	switch (op) {
		case PLUS:
			emit_write_line("","add rax, rbx",";perform addition");
			break;
		case MINUS:
			emit_write_line("","sub rax, rbx",";perform subtraction");
			break;
		case TIMES:
			emit_write_line("","imul rax, rbx",";perform multiplication");
			break;
		case DIVIDE:
			emit_write_line("","xor rdx, rdx",";RDX must be cleared before division");
			emit_write_line("","idiv rbx",";perform division");
			break;
		case EQ: //(EQ)ual
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","sete al",";Get Equal flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		case NE: //(N)ot (E)qual
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","setne al",";Get Not Equal flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		case GE: //(G)reater or (E)qual
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","setge al",";Get Greater or Equal flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		case LE: //(L)ess or (E)qual
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","setle al",";Get Less or Equal flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		case GT: //(G)reater (T)han
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","setg al",";Get Greater Than flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		case LT: //(L)ess (T)han
			emit_write_line("","cmp rax, rbx",";Compare RAX and RBX");
			emit_write_line("","setl al",";Get Less than flag");
			emit_write_line("","and rax, 1",";mask RAX to first bit");
			break;
		default:
			if (emit_debug)
				fprintf(stderr,"Emit Error! emit_handle_operator called with invalid operator.\n");
	}
}

//emit_handle_var implementation
void emit_handle_var(AST_Node *var) {
	//buffer for writing lines
	char buffer[100];
	char buffer2[100];

	//Check that var is valid
	if (var == NULL) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_handle_var called with NULL node.\n");
		return;
	}
	if (var->type != VAR_EXPR) {
		if (emit_debug)
			fprintf(stderr,"Emit Error! emit_handle_var called with non-VAR_EXPR node.\n");
		return;
	}
	
	//If an array access, evaluate expression to get array offset (in RBX)
	if (var->s1.expr != NULL) {
		emit_write_plain_line("\t;ARRAY ACCESS");
		emit_handle_expr(var->s1.expr);//value will be in RSI
		emit_write_line("","mov rbx, rsi",";store offset value in RBX");
		sprintf(buffer,"shl rbx, %d",LOGWORDSIZE);
		emit_write_line("",buffer,";Shift array offset");
	}
	
	//Global Variable
	if (var->symbol->level == 0) {
		sprintf(buffer,"mov rax, %s",var->name);
		emit_write_line("",buffer,";Get global variable address");
	}
	//Local Variable
	else {
		//get var offset
		sprintf(buffer,"mov rax, %d",var->symbol->offset*WORDSIZE);
		sprintf(buffer2,";Get Variable offset for %s",var->name);
		emit_write_line("",buffer,buffer2);
		emit_write_line("","add rax, rsp",";Add offset to stack pointer");
	}
	
	//If an array access, add array offset (in RBX)
	if (var->s1.expr != NULL) {
		emit_write_line("","add rax, rbx",";Add array offset");
	}
}

//emit_write_line implementation
void emit_write_line(char *label, char *line, char *comment) {
	if (!emit_file_set) {
		fprintf(stderr,"Output file has not been set. Cannot emit line!\n");
		return;
	}

	fprintf(emit_file,"%s\t%s\t\t%s\n",label,line,comment);
	if (emit_debug)
		fprintf(stderr,"%s\t%s\t\t%s\n",label,line,comment);
}

//emit_write_plain_line implentation
void emit_write_plain_line(char *text) {
	if (!emit_file_set) {
		fprintf(stderr,"Output file has not been set. Cannot emit line!\n");
		return;
	}

	fprintf(emit_file,"%s\n",text);
	if (emit_debug)
		fprintf(stderr,"%s\n",text);
}

//emit_newline implementation
void emit_newline() {
	if (!emit_file_set) {
		fprintf(stderr,"Output file has not been set. Cannot emit line!\n");
		return;
	}

	fprintf(emit_file,"\n");
	if (emit_debug)
		fprintf(stderr,"\n");
}
