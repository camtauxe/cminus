/**
* Implementation of ast.h (see header file for details)
*
* 1 March, 2018
*	- Initial Version
* 2 March, 2018
*	- Updated to 2 March, 2018 changes to ast.h
*	- Made display output more clear
* 20 April, 2018
*	- Added display case for WRITE_STR_STMTs
*
* Cameron Tauxe
*/

#include"ast.h"
#include<string.h>
#include<stdio.h>
#include<malloc.h>

//Output stream when printing
#define OUT stderr

//ast_create_node implementation
AST_Node* ast_create_node(AST_TYPE _type) {
	AST_Node *p;
	if (ast_debug) fprintf(stderr, "Creating new AST node\n");
	p = (AST_Node*)malloc(sizeof(AST_Node));
	//init fields
	p->type = _type;
	p->var_type = TYPE_VOID;
	p->op = UNKNOWN_TYPE;
	p->name = NULL;
	p->value = 0;
	p->s1.any = NULL;
	p->s2.any = NULL;
	p->s3.any = NULL;

	return p;
}

//ast_display_all implementation
void ast_display_all() {
	ast_display(0,ast_root);
}

void ast_display(int level, AST_Node *p) {
	//If null, return immediately
	if (p == NULL) return;

	//print indentation
	ast_indent(level);

	//Print output according to type of node
	switch (p->type) {
		case PROGRAM:
			fprintf(OUT,"PROGRAM START\n");
			ast_display(level,p->next);
			break;
		case VAR_DECL:
			//Print variable type, name (and size if it's an array)
			if (p->value != 0)
				fprintf(OUT,"Variable Declaration (Array): %s %s Size: %d\n",
					var_type_to_string(p->var_type),
					p->name,
					p->value);
			else
				fprintf(OUT,"Variable Declaration: %s %s\n",
					var_type_to_string(p->var_type),
					p->name);
			//Print next declaration
			ast_display(level,p->next);
			break;
		case FUN_DECL:
			//Print function return type, name, parameters and body
			fprintf(OUT,"Function Declaration: %s %s\n",
				var_type_to_string(p->var_type),
				p->name);
			//Print parameters
			if (p->s1.fun_params != NULL) {
				ast_indent(level); fprintf(OUT,"Parameters:\n");
				ast_display(level+1,p->s1.fun_params);
			}
			else {
				ast_indent(level); fprintf(OUT, "(No Parameters)\n");
			}
			//Print body
			ast_indent(level); fprintf(OUT,"Body:\n");
			ast_display(level+1,p->s2.fun_body);
			//Print next declaration
			ast_display(level,p->next);
			break;
		case PARAM:
			//Print parameter type and name
			fprintf(OUT,"Parameter: %s %s\n",
				var_type_to_string(p->var_type),
				p->name);
			//Print next parameter
			ast_display(level,p->next);
			break;
		case BLOCK:
			//Print local declarations followed by statements
			fprintf(OUT,"Code Block:\n");
			//print local declarations
			if (p->s1.block_decls != NULL) {
				ast_indent(level); fprintf(OUT,"Local Declarations:\n");
				ast_display(level+1,p->s1.block_decls);
			}
			//print statements
			ast_indent(level); fprintf(OUT,"Body:\n");
			ast_display(level+1,p->s2.block_stmts);
			//print next statement
			ast_display(level,p->next);
			break;
		case EXPR_STMT:
			//Print statement's expression
			fprintf(OUT,"Expression Statement:\n");
			ast_display(level+1,p->s1.expr);
			//print next statement
			ast_display(level,p->next);
			break;
		case IF_STMT:
			//Print condition and body (including else if it has one)
			fprintf(OUT,"If Statement:\n");
			//Print condition
			ast_indent(level); fprintf(OUT,"Condition:\n");
			ast_display(level+1,p->s1.condition);
			//Print "If" body
			ast_indent(level); fprintf(OUT,"If True:\n");
			ast_display(level+1,p->s2.if_body);
			//Print "Else" body
			if (p->s3.else_body != NULL) {
				ast_indent(level); fprintf(OUT,"Else:\n");
				ast_display(level+1,p->s3.else_body);
			}
			//print next statement
			ast_display(level,p->next);
			break;
		case LOOP_STMT:
			//Print condition and loop body
			fprintf(OUT,"While Loop:\n");
			//print condition
			ast_indent(level); fprintf(OUT,"Condition:\n");
			ast_display(level+1,p->s1.condition);
			//print body
			ast_indent(level); fprintf(OUT,"Loop Body:\n");
			ast_display(level+1,p->s2.loop_body);
			//print next statement
			ast_display(level,p->next);
			break;
		case RET_STMT:
			//Print expression to return
			fprintf(OUT,"Return Statement:\n");
			ast_display(level+1,p->s1.expr);
			//print next statement
			ast_display(level,p->next);
			break;
		case READ_STMT:
			//Print var to read into
			fprintf(OUT,"Read Statement:\n");
			ast_display(level+1,p->s1.var);
			//print next statement
			ast_display(level,p->next);
			break;
		case WRITE_STMT:
			//Print expression to write
			fprintf(OUT,"Write Statement:\n");
			ast_display(level+1,p->s1.expr);
			//print next statement
			ast_display(level,p->next);
			break;
		case WRITE_STR_STMT:
			//Print string
			fprintf(OUT,"Write String Statement (%d):\n",p->value);
			ast_indent(level+1); fprintf(OUT,"%s\n",p->name);
			//print next statement
			ast_display(level,p->next);
			break;
		case VAR_EXPR:
			//Print variable
			//If accessing an array, print the expression used
			if (p->s1.expr != NULL) {
				fprintf(OUT,"Variable (Array Access): %s\n",p->name);
				ast_indent(level); fprintf(OUT,"Array Access Expression:\n");
				ast_display(level+1,p->s1.expr);
			}
			else {
				fprintf(OUT,"Variable: %s\n",p->name);
			}
			break;
		case ASS_EXPR:
			//Print variable and expression
			fprintf(OUT,"Assignment (=):\n");
			ast_indent(level); fprintf(OUT,"Left:\n");
			ast_display(level+1,p->s1.var);
			ast_indent(level); fprintf(OUT,"Right:\n");
			ast_display(level+1,p->s2.expr);
			break;
		case SIMP_EXPR:
			//Print both sides of expression and operator
			fprintf(OUT,"Expression (%s):\n",operator_to_string(p->op));
			ast_indent(level); fprintf(OUT,"Left:\n");
			ast_display(level+1,p->s1.expr_left);
			ast_indent(level); fprintf(OUT,"Right:\n");
			ast_display(level+1,p->s2.expr_right);
			break;
		case NUM_EXPR:
			//Print value
			fprintf(OUT,"Number: %d\n",p->value);
			break;
		case CALL_EXPR:
			//Print function name and arguments
			fprintf(OUT,"Function Call: %s\n",p->name);
			if (p->s1.call_args != NULL) {
				ast_indent(level); fprintf(OUT,"Arguments:\n");
				ast_display(level+1,p->s1.call_args);
			}
			break;
		case ARG:
			//Print argument expression
			fprintf(OUT,"Argument:\n");
			ast_display(level+1,p->s1.expr);
			//print next argument
			ast_display(level,p->next);
			break;
		default:
			//Hopefully, this doesn't happen.
			//But if it does, just stop
			fprintf(OUT,"UNKNOWN NODE TYPE!!!\n");
	}
}

//ast_indent implementation
void ast_indent(int n) {
	int i;
	for (i=0;i<n;i++)
		fprintf(OUT,"|   ");
}
