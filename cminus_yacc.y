%{
	/*
	* YACC Parser for the Cminus Language
	*
	* Cameron Tauxe
	*
	* 22 Feb, 2018
	*	-Initial version
	*	-Parses Input (No semantic action yet)
	* 23 Feb, 2018
	*	-Fixed type clashing with some placeholder semantic action in some places
	* 1 March, 2018
	*	-Added semantic action to build abstract syntax tree
	*	-Fixed incorrect logic when parsing expressions
	*	-Prints AST after parsing
	* 2 March, 2018
	*	- No longer includes lex.yy.c. Linked at compile-time
	*	- Updated to 2 March, 2018 changes to ast specs
	* 1 April, 2018
	*	- Implemented symbol table
	*		-Adds and removes symbols. No type checking or temp variables yet
	* 6 April, 2018
	*	- Multiple assignmnents in a single statement are no longer allowed
	* 7 April, 2018
	*	- Expressions now add temporary variables to symbol table
	*	- Implemented type checking
	* 8 April, 2018
	*	- ASS_EXPRs now store the temporary symbol from their corresponding simp_expr (right side)
	*	- VAR_EXPRs now store a temporary symbol when they are an array access
	*	- Now exits immediately on error
	*	- Fixed linenum value being incorrect
	* 16 April, 2018
	*	- Now parses command-line arguments for debug flags
	*	- Now calls emitter when done parsing
	* 17 April, 2018
	*	- Fixed FUN_DECL nodes not saving a reference to their symbol
	*	- Fixed specifying a custom output file not working
	*	- Now calculates and stores offset size for each function
	*	- Minimum offset for functions is now 2 to account for stack frame stuff
	* 18 April, 2018
	*	- Accessing an an element of an array no longer uses a temp variable
	*	- Assignment expressions now use a temp variable
	*	- Fixed assignment expressions not filling out their var_type field
	* 20 April, 2018
	*	- Added Write String statements
	*	- Can now properly set emit_debug flag
	* 21 April, 2018
	*	- Number of temp variables is no longer reset at the end of each block
	* 23 April, 2018
	*	- Arrays as parameters disabled
	* 26 April, 2018
	*	- Arguments in a call expression now use temp variables
	* 28 April, 2018
	*	- Added debug statements
	*/

	#include <string.h>
	#include <stdio.h>
	#include <ctype.h>
	#include <stdlib.h>
	#include"ast.h"
	#include"symtab.h"
	#include"emit.h"

	//external variables
	extern int linenum; //defined in cminus_lex.l
	extern int lexdebug;
	extern int ast_debug; //defined in ast.h
	extern int symtab_level; //defined in symtab.h
	extern int symtab_offset;
	extern int symtab_global_offset;
	extern int symtab_max_offset;
	extern int symtab_temp_vars;
	extern int symtab_debug;
	int emit_debug = 0;

	/*Declarations*/

	//Flag indicating whether or not to print debug statements
	static int yaccdebug = 0;

	//Temporary reference to the symbol created for a function
	//(this is because the symbol is created before it can
	// stored in the FUN_DECL node)
	Symtab_Node *fun_symbol;
	
	//Keep track of number of write_str_stmts that have been
	//found, so that each can have a unique ID.
	static int write_str_stmts = 0;

	//Buffer to write error messages too
	char error_message[100];

	//Error handler. Called by yyparse on error
	//(linenum is defined in cminus_lex.l)
	void yyerror(char* s) {
		printf("Error on line %d!\t%s\n",linenum,s);
		exit(1);
	}
%}

/***********************
* BEGIN SPECIFICATIONS
************************/

%union
{
	int integer;
	char* string;
	AST_Node* ast;
	OPERATOR op;
	VAR_TYPE type;
}

/*Define tokens*/
/*Reserve words*/
%token INT
%token VOID
%token IF
%token ELSE
%token WHILE
%token RETURN
%token READ
%token WRITE
/*Tokens with values*/
%token <string> ID
%token <integer> NUM
%token <string> STRING
/*Relation Operators*/
%token RELOP_LE
%token RELOP_GE
%token RELOP_EQ
%token RELOP_NE
%token RELOP_LT
%token RELOP_GT

/*Abstract Syntax Tree nodes*/
%type <ast> program
%type <ast> decl_list
%type <ast> decl
%type <ast> var_decls
%type <ast> var_decl
%type <ast> fun_decl
%type <ast> params
%type <ast> param_list
%type <ast> param
%type <ast> block
%type <ast> local_decls
%type <ast> stmt_list
%type <ast> stmts
%type <ast> stmt
%type <ast> expr_stmt
%type <ast> if_stmt
%type <ast> loop_stmt
%type <ast> ret_stmt
%type <ast> read_stmt
%type <ast> write_stmt
%type <ast> write_str_stmt
%type <ast> expr
%type <ast> simp_expr
%type <ast> math_expr
%type <ast> term
%type <ast> factor
%type <ast> call
%type <ast> var
%type <ast> args
%type <ast> arg_list

/*Var type*/
%type <type> type_spec

/*Operators*/
%type <op> addop
%type <op> multop
%type <op> relop

%start program

%%

/***********************
* BEGIN RULES
************************/

/*The entire program is a list of declarations*/
program		: decl_list {
					if (yaccdebug)
						fprintf(stderr,"Parsed program from decl_list\n");
					$$ = ast_create_node(PROGRAM);
					$$->next = $1;
					ast_root = $$;
				}
		;

/**************
* DECLARATIONS
***************/

/*Declaration List: One or more declarations*/
decl_list	: decl {
					if (yaccdebug)
							fprintf(stderr,"Parsed decl_list from single decl\n");
					$$=$1;
				}
			| decl decl_list {
					if (yaccdebug)
						fprintf(stderr,"Chained decl into decl_list\n");
					$1->next=$2;
					$$=$1;
				}
			;

/*Declaration: Can either declare a variable or a function*/
decl		: var_decl {
					if (yaccdebug)
							fprintf(stderr,"Parsed decl from var_decl\n");
					$$=$1;
				}
			| fun_decl {
					if (yaccdebug)
							fprintf(stderr,"Parsed decl from fun_decl\n");
					$$=$1;
				}
			;

/*Variable Declaration*/
var_decl	: type_spec ID ';' {
					if (yaccdebug)
						fprintf(stderr,"Parsed var_decl: %s %s\n",var_type_to_string($1),$2);
					//create new symbol
					Symtab_Node *new_symbol;
					new_symbol = symtab_create_variable($2,$1,symtab_level,symtab_offset);
					//attempt to add to symbol table
					if (!symtab_insert(new_symbol)) {
						//if adding to the table failed, throw an error
						sprintf(error_message,"Already declared identifier '%s'!\n",$2);
						yyerror(error_message);
					}
					//create VAR_DECL node
					$$ = ast_create_node(VAR_DECL);
					$$->var_type = $1;
					$$->name = $2;
					$$->symbol=new_symbol;
					$$->symbol->declaration=$$;
					//increment offset
					symtab_offset++;
				}
			/*Declaring an array*/
			| type_spec ID '[' NUM ']' ';' {
					if (yaccdebug)
						fprintf(stderr,"Parsed var_decl: %s %s[%d]\n",var_type_to_string($1),$2,$4);
					//create new symbol
					Symtab_Node *new_symbol;
					new_symbol = symtab_create_array($2,$1,symtab_level,symtab_offset,$4);
					//attempt to add to symbol table
					if (!symtab_insert(new_symbol)) {
						//if adding to the table failed, throw an error
						sprintf(error_message,"Already declared identifier '%s'!\n",$2);
						yyerror(error_message);
					}
					//create VAR_DECL node
					$$ = ast_create_node(VAR_DECL);
					$$->var_type = $1;
					$$->name = $2;
					$$->symbol=new_symbol;
					$$->symbol->declaration=$$;
					//define array size
					$$->value = $4;
					//increase offset
					symtab_offset += $4;
				}
			;

/*Variable Declarations: A list of one more variable declarations*/
var_decls	: var_decl {
					if (yaccdebug)
							fprintf(stderr,"Parsed var_decls from single var_decl\n");
					$$=$1;
				}
			| var_decl var_decls {
					if (yaccdebug)
						fprintf(stderr,"Chained var_decl into var_decls\n");
					$1->next=$2;
					$$ = $1;
				}
			;

/*Type Specifier: Just int or void*/
type_spec	: INT {
					$$=TYPE_INT;
					if (yaccdebug)
						fprintf(stderr,"Parsed type_spec: %s\n",var_type_to_string($$));
				}
			| VOID {
					$$=TYPE_VOID;
					if (yaccdebug)
						fprintf(stderr,"Parsed type_spec: %s\n",var_type_to_string($$));
				}
			;

/*zFunction Declaration: Declaration for a function (includes the function's code)*/
fun_decl	: 	type_spec
				ID
				'(' {
						if (yaccdebug)
							fprintf(stderr,"Parsed fun_decl %s %s\n",var_type_to_string($1),$2);
						//save global offset
						symtab_global_offset = symtab_offset;
						symtab_offset = 2;
						symtab_max_offset = symtab_offset;
					}
				params {
						//Add function to symbol table
						Symtab_Node *new_symbol;
						new_symbol = symtab_create_function($2,$1,$5);
						if (!symtab_insert(new_symbol)) {
							sprintf(error_message,"Already declared identifier '%s'!\n",$2);
							yyerror(error_message);
						}
						fun_symbol = new_symbol;
					}
				')'
				block {
						//create FUN_DECL node
						$$ = ast_create_node(FUN_DECL);
						$$->var_type = $1;
						$$->name = $2;
						$$->s1.fun_params = $5;
						$$->s2.fun_body = $8;
						$$->symbol = fun_symbol;
						$$->symbol->declaration = $$;
						//save function offset size
						$$->symbol->size = symtab_max_offset;
						$$->value = symtab_max_offset;
						//swap back to global offset
						symtab_offset = symtab_global_offset;
					}
			;

/*The parameters for a function (can just be 'void')*/
params		: VOID {
					if (yaccdebug)
							fprintf(stderr,"Parsed params from VOID\n");
					$$=NULL;
				}
			| param_list {
					if (yaccdebug)
							fprintf(stderr,"Parsed params from param_list\n");
					$$=$1;
				}
			;

/*Parameter List: A list of one or more parameters to a function, comma-separated*/
param_list	: param {
					if (yaccdebug)
							fprintf(stderr,"Parsed param_list from single param\n");
					$$=$1;
				}
			| param ',' param_list {
					if (yaccdebug)
							fprintf(stderr,"Chained param into param_list\n");
					$1->next = $3;
					$$ = $1;
				}
			;

/*A single parameter for a function*/
param		: type_spec ID {
					if (yaccdebug)
							fprintf(stderr,"Parsed param: %s %s\n",var_type_to_string($1),$2);
					//create new symbol
					Symtab_Node *new_symbol;
					new_symbol = symtab_create_variable($2,$1,symtab_level+1,symtab_offset);
					//attempt to add to symbol table
					if (!symtab_insert(new_symbol)) {
						//if adding to the table failed, throw an error
						sprintf(error_message,"Duplicate parameter name '%s'!\n",$2);
						yyerror(error_message);
					}
					//create PARAM node
					$$ = ast_create_node(PARAM);
					$$->var_type = $1;
					$$->name = $2;
					$$->symbol=new_symbol;
					//increment offset
					symtab_offset++;
				}
			/*Array parameter*/
			| type_spec ID '[' ']' {
					if (yaccdebug)
							fprintf(stderr,"Parsed param: %s %s[]\n",var_type_to_string($1),$2);
					//Arrays as parameters is currently disabled
					yyerror("Arrays as parameters is currently not allowed!\n");
					/*
					//create new symbol
					Symtab_Node *new_symbol;
					new_symbol = symtab_create_array($2,$1,symtab_level+1,symtab_offset,-1);
					//attempt to add to symbol table
					if (!symtab_insert(new_symbol)) {
						//if adding to the table failed, throw an error
						sprintf(error_message,"Duplicate parameter name '%s'!\n",$2);
						yyerror(error_message);
					}
					//create PARAM node
					$$ = ast_create_node(PARAM);
					$$->var_type = $1;
					$$->name = $2;
					$$->symbol=new_symbol;
					//increment offset
					symtab_offset++;
					*/
				}
			;

/*Represents a block of code. (the specification calls this a 'combination stmt')*/
block		: 	'{' {
						if (yaccdebug)
							fprintf(stderr,"Entered code block\n");
						//on entering a block, increment level
						symtab_level++;
					}
				local_decls
				stmt_list
				'}' {
						if (yaccdebug)
							fprintf(stderr,"Exited code block\n");
						//on exiting a block
						//create BLOCK node
						$$ = ast_create_node(BLOCK);
						$$->s1.block_decls = $3;
						$$->s2.block_stmts = $4;
						//print symbol table
						if (symtab_debug) {
							fprintf(stderr,"Block exited:\n");
							symtab_display();
						}
						//update max offset
						if (symtab_offset > symtab_max_offset)
							symtab_max_offset = symtab_offset;
						//delete local symbols from table
						symtab_offset -= symtab_delete_level(symtab_level);
						//decrement level
						symtab_level--;
						//reset temp variables
						//symtab_temp_vars = 0;
					}
			;

/*The local declarations for a code block. Either nothing or a list of variable declartions*/
local_decls	: /*empty*/ {
					if (yaccdebug)
							fprintf(stderr,"Parsed local_decls from EMPTY\n");
					$$=NULL;
				}
			| var_decls {
					if (yaccdebug)
							fprintf(stderr,"Parsed local_decls from var_decls\n");
					$$=$1;
				}
			;

/**************
* STATEMENTS
***************/

/*A list of statements inside a code block. Is 0 or more statements*/
stmt_list	: /*empty*/ {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt_list from EMPTY\n");
					$$=NULL;
				}
			| stmts {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt_list from stmts\n");
					$$=$1;
				}
			;

/*One or more statements*/
stmts		: stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmts from single stmt\n");
					$$=$1;
				}
			| stmt stmts {
					if (yaccdebug)
							fprintf(stderr,"Chained stmt into stmts\n");
					if ($1 == NULL) {
						if (yaccdebug)
							fprintf(stderr,"Skipped empty statement in stmts\n");
						//if a statment is null (just a semicolon), skip over it
						$$ = $2;
					}
					else {
						$1->next = $2;
						$$ = $1;
					}
				}
			;

/*A single statement, Can be a code block or one of some type of statement*/
stmt		: block {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from block\n");
					$$=$1;
				}
			| expr_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from expr_stmt\n");
					$$=$1;
				}
			| if_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from if_stmt\n");
					$$=$1;
				}
			| loop_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from loop_stmt\n");
					$$=$1;
				}
			 /*assignment statement isn't used currently (instead assignments are done in expressions)*/
			/*| ass_stmt*/
			| ret_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from ret_stmt\n");
					$$=$1;
				}
			| read_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from read_stmt\n");
					$$=$1;
				}
			| write_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from write_stmt\n");
					$$=$1;
				}
			| write_str_stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed stmt from write_str_stmt\n");
					$$=$1;
				}
			;

/*Expression Statement: Either nothing (just a semicolon) or an expression*/
expr_stmt	: ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed empty stmt (';')\n");				
					$$=NULL;
				}
			| expr ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed expr_stmt\n");
					//create an EXPR_STMT node
					$$ = ast_create_node(EXPR_STMT);
					$$->s1.expr = $1;
				}
			;

/*If Statement: Either an If or an If/Else statement*/
if_stmt		: IF '(' expr ')' stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed if_stmt (no else)\n");
					//type checking
					if ($3->var_type == TYPE_VOID) {
						yyerror("If condition cannot be void!\n");
					}
					//create an IF_STMT node
					$$ = ast_create_node(IF_STMT);
					$$->s1.condition = $3;
					$$->s2.if_body = $5;
				}
			| IF '(' expr ')' stmt ELSE stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed if_stmt (with else)\n");
					//type checking
					if ($3->var_type == TYPE_VOID) {
						yyerror("If condition cannot be void!\n");
					}
					//create an IF_STMT node
					$$ = ast_create_node(IF_STMT);
					$$->s1.condition = $3;
					$$->s2.if_body = $5;
					$$->s3.else_body = $7;
				}
			;

/*Loop Statement: A while loop*/
loop_stmt	: WHILE '(' expr ')' stmt {
					if (yaccdebug)
							fprintf(stderr,"Parsed loop_stmt\n");
					//type checking
					if ($3->var_type == TYPE_VOID) {
						yyerror("Loop condition cannot be void!\n");
					}
					//create LOOP_STMT node
					$$ = ast_create_node(LOOP_STMT);
					$$->s1.condition = $3;
					$$->s2.loop_body = $5;
				}
			;

/*Return Statement: Can return nothing or an expression*/
ret_stmt	: RETURN ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed ret_stmt (no expression)\n");
					//create a RET_STMT node
					$$ = ast_create_node(RET_STMT);
				}
			| RETURN expr ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed ret_stmt (with expression)\n");
					//type checking
					if ($2->var_type == TYPE_VOID) {
						yyerror("Cannot return void expression!\n");
					}
					//create a RET_STMT node (with an expression)
					$$ = ast_create_node(RET_STMT);
					$$->s1.expr = $2;
				}
			;

/*Read Statement*/
read_stmt	: READ var ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed read_stmt\n");
					if ($2->var_type == TYPE_VOID) {
						sprintf(error_message,"Cannot read into void variable '%s'!\n",$2->name);
						yyerror(error_message);
					}
					//create a READ_STMT node
					$$ = ast_create_node(READ_STMT);
					$$->s1.var = $2;
				}
			;

/*Write Statement*/
write_stmt	: WRITE expr ';' {
					if (yaccdebug)
							fprintf(stderr,"Parsed write_stmt\n");
					//type checking
					if ($2->var_type == TYPE_VOID) {
						yyerror("Cannot write void expression!\n");
					}
					//create a WRITE_STMT node
					$$ = ast_create_node(WRITE_STMT);
					$$->s1.expr = $2;
				}
			;
			
/*Write String Statement*/
write_str_stmt	: WRITE STRING ';' {
						if (yaccdebug)
							fprintf(stderr,"Parsed write_str_stmt\n");
						//Create a WRITE_STR_STMT node
						$$ = ast_create_node(WRITE_STR_STMT);
						$$->name = $2;
						$$->value = write_str_stmts;
						write_str_stmts++;
					}

/**************
* EXPRESSIONS
***************/

/*Expression: Either a simple expression or a variable assignment*/
expr		: simp_expr {
					if (yaccdebug)
							fprintf(stderr,"Parsed expr from simp_expr\n");
					$$=$1;
				}
			| var '=' simp_expr {
					if (yaccdebug)
							fprintf(stderr,"Parsed expr from assignment\n");
					//type checking
					if ($1->var_type == TYPE_VOID) {
						sprintf(error_message,"Cannot assign to void variable '%s'!\n",$1->name);
						yyerror(error_message);
					}
					if ($1->var_type != $3->var_type) {
						sprintf(error_message,"Type mismatch in assignment (%s = %s)\n",
							var_type_to_string($1->var_type),
							var_type_to_string($3->var_type));
						yyerror(error_message);
					}
					//Create temporary symbol
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create an ASS_EXPR node
					$$ = ast_create_node(ASS_EXPR);
					$$->s1.var = $1;
					$$->s2.expr = $3;
					$$->var_type = $1->var_type;
					$$->symbol = temp;
				}
			;

/*Variable:*/
var			: ID {
					if (yaccdebug)
							fprintf(stderr,"Parsed var from ID: %s\n",$1);
					//check that ID is in the symbol table and is a variable
					Symtab_Node *sym;
					sym = symtab_search_recursive($1,symtab_level);
					if (sym == NULL) {
						sprintf(error_message,"Undeclared Identifier '%s'!\n",$1);
						yyerror(error_message);
					}
					if (sym->isFunc) {
						sprintf(error_message,"'%s' is a function. Cannot access as variable.\n",$1);
						yyerror(error_message);
					}
					if (sym->isArr) {
						sprintf(error_message,"'%s' is an array. It cannot be referenced directly (instead access an element of it)",$1);
						yyerror(error_message);
					}
					//create a VAR_EXPR node
					$$ = ast_create_node(VAR_EXPR);
					$$->name = $1;
					$$->symbol=sym;
					$$->var_type=sym->type;
				}
			/*Array access*/
			| ID '[' expr ']' {
					if (yaccdebug)
							fprintf(stderr,"Parsed var from array access: %s\n",$1);
					//check that ID is in the symbol table and is an array
					Symtab_Node *sym;
					sym = symtab_search_recursive($1,symtab_level);
					if (sym == NULL) {
						sprintf(error_message,"Undeclared Identifier '%s'!\n",$1);
						yyerror(error_message);
					}
					if (!sym->isArr) {
						sprintf(error_message,"'%s' is not an array. Cannot access element.\n",$1);
						yyerror(error_message);
					}
					//create a VAR_EXPR node
					$$ = ast_create_node(VAR_EXPR);
					$$->name = $1;
					$$->symbol=sym;
					$$->var_type=sym->type;
					$$->s1.expr=$3;
				}
			;

/*Simple Expression: Either or a math expression or a relation expression*/
simp_expr	: math_expr {
					if (yaccdebug)
							fprintf(stderr,"Parsed simp_expr from math_expr\n");
					$$=$1;
				}
			| simp_expr relop math_expr {
					if (yaccdebug)
							fprintf(stderr,"Parsed simp_expr from operation: %s\n",operator_to_string($2));
					//type checking
					if ($1->var_type != $3->var_type) {
						sprintf(error_message,"Type mismatch in operation (%s %s %s)\n",
							var_type_to_string($1->var_type),
							operator_to_string($2),
							var_type_to_string($3->var_type));
						yyerror(error_message);
					}
					//add temporary variable to symbol table
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create a SIMP_EXPR node (with a relop operator)
					$$ = ast_create_node(SIMP_EXPR);
					$$->s1.expr_left = $1;
					$$->s2.expr_right = $3;
					$$->op = $2;
					$$->symbol = temp;
					$$->var_type = temp->type;
				}
			;

/*Relation Operators*/
relop		: RELOP_GE /*(G)reater than or (E)qual*/ {
					$$=GE;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			| RELOP_LE /*(L)ess than or (E)qual*/ {
					$$=LE;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			| RELOP_GT /*(G)reater (T)han*/ {
					$$=GT;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			| RELOP_LT /*(L)ess (T)han*/ {
					$$=LT;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			| RELOP_EQ /*(EQ)ual*/ {
					$$=EQ;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			| RELOP_NE /*(N)ot (E)qual*/ {
					$$=NE;
					if (yaccdebug)
							fprintf(stderr,"Parsed relop: %s\n",operator_to_string($$));
				}
			;

/*Math expression: Either a single value or an expression with mathematical operators*/
math_expr	: term {
					if (yaccdebug)
							fprintf(stderr,"Parsed math_expr from term\n");
					$$=$1;
				}
			| math_expr addop term {
					if (yaccdebug)
							fprintf(stderr,"Parsed math_expr from operation: %s\n",operator_to_string($2));
					//type checking
					if ($1->var_type != $3->var_type) {
						sprintf(error_message,"Type mismatch in operation (%s %s %s)\n",
							var_type_to_string($1->var_type),
							operator_to_string($2),
							var_type_to_string($3->var_type));
						yyerror(error_message);
					}
					//add temporary variable to symbol table
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create a SIMP_EXPR node (with a addop operator)
					$$ = ast_create_node(SIMP_EXPR);
					$$->s1.expr_left = $1;
					$$->s2.expr_right = $3;
					$$->op = $2;
					$$->symbol = temp;
					$$->var_type = temp->type;
				}
			;

/*Addition or Subtraction Operators*/
/*(Operators are split up to enforce order of operations)*/
addop		: '+' {
					$$=PLUS;
					if (yaccdebug)
							fprintf(stderr,"Parsed addop: %s\n",operator_to_string($$));
				}
			| '-' {
					$$=MINUS;
					if (yaccdebug)
							fprintf(stderr,"Parsed addop: %s\n",operator_to_string($$));
				}
			;

/*A term of an expression separated by addition/subtraction operators*/
term		: factor {
					if (yaccdebug)
							fprintf(stderr,"Parsed term from factor\n");
					$$=$1;
				}
			| term multop factor {
					if (yaccdebug)
							fprintf(stderr,"Parsed term from operation: %s\n",operator_to_string($2));
					//type checking
					if ($1->var_type != $3->var_type) {
						sprintf(error_message,"Type mismatch in operation (%s %s %s)\n",
							var_type_to_string($1->var_type),
							operator_to_string($2),
							var_type_to_string($3->var_type));
						yyerror(error_message);
					}
					//add temporary variable to symbol table
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create a SIMP_EXPR node (with a multop operator)
					$$ = ast_create_node(SIMP_EXPR);
					$$->s1.expr_left = $1;
					$$->s2.expr_right = $3;
					$$->op = $2;
					$$->symbol = temp;
					$$->var_type = temp->type;
				}
			;

/*Multiplication and Division Operators*/
multop		: '*' {
					$$=TIMES;
					if (yaccdebug)
							fprintf(stderr,"Parsed multop: %s\n",operator_to_string($$));
				}
			| '/' {
					$$=DIVIDE;
					if (yaccdebug)
							fprintf(stderr,"Parsed multop: %s\n",operator_to_string($$));
				}
			;

/*Factor (first priority in evaluating an expression i.e. smallest unit)*/
factor		: '(' expr ')' {
					if (yaccdebug)
							fprintf(stderr,"Parsed factor from parenthesed expr\n");
					$$=$2;
				}
			| NUM {
					if (yaccdebug)
							fprintf(stderr,"Parsed factor from NUM: %d\n",$1);
					//create a NUM_EXPR node
					$$ = ast_create_node(NUM_EXPR);
					$$->value = $1;
					$$->var_type = TYPE_INT;
				}
			| var {
					if (yaccdebug)
							fprintf(stderr,"Parsed factor from var\n");
					$$=$1;
				}
			| call {
					if (yaccdebug)
							fprintf(stderr,"Parsed factor from function call\n");
					$$=$1;
				}
			;

/*Function Call*/
call		: ID '(' args ')' {
					if (yaccdebug)
							fprintf(stderr,"Parsed function call: %s\n",$1);
					//check that ID is in the symbol table and is a function with correct parameters
					Symtab_Node *sym;
					sym = symtab_search($1,0);//a function will always be level 0
					if (sym == NULL) {
						sprintf(error_message,"Undeclared function '%s'!\n",$1);
						yyerror(error_message);
					}
					if (!sym->isFunc) {
						sprintf(error_message,"'%s' is not a function. Cannot call.\n",$1);
						yyerror(error_message);
					}
					//check that arguments match parameters
					if(!symtab_compare_params(sym->params,$3)) {
						sprintf(error_message,"Invalid parameters to function '%s'!\n",$1);
						yyerror(error_message);
					}
					//create a CALL_EXPR node
					$$ = ast_create_node(CALL_EXPR);
					$$->name = $1;
					$$->s1.call_args = $3;
					$$->symbol = sym;
					$$->var_type = sym->type;
				}
			;

/*Arguments to a function call. 0 or more args*/
args		: /*empty*/ {
					if (yaccdebug)
							fprintf(stderr,"Parsed args from EMPTY\n");
					$$=NULL;
				}
			| arg_list {
					if (yaccdebug)
							fprintf(stderr,"Parsed args from arg_list\n");
					$$=$1;
				}
			;

/*Argument List: One or more arguments, comma-separted*/
arg_list	: expr {
					if (yaccdebug)
							fprintf(stderr,"Parsed arg_list from single expr\n");
					//type checking
					if ($1->var_type == TYPE_VOID) {
						yyerror("Cannot use void expression as argument!\n");
					}
					//add temporary variable to symbol table
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create an ARG node
					$$ = ast_create_node(ARG);
					$$->s1.expr = $1;
					$$->symbol = temp;
				}
			| expr ',' arg_list {
					if (yaccdebug)
							fprintf(stderr,"Chained expr into arg_list\n");
					//type checking
					if ($1->var_type == TYPE_VOID) {
						yyerror("Cannot use void expression as argument!\n");
					}
					//add temporary variable to symbol table
					Symtab_Node *temp;
					temp = symtab_create_temp(symtab_temp_vars,$1->var_type,symtab_level,symtab_offset);
					if (!symtab_insert(temp)) {
						yyerror("Error creating temporary variable!\n");
					}
					symtab_offset++;
					symtab_temp_vars++;
					//create an ARG node
					$$ = ast_create_node(ARG);
					$$->next = $3;
					$$->s1.expr = $1;
					$$->symbol = temp;
				}
			;

%%

/***********************
* BEGIN PROGRAM
************************/

main(int argc, char* argv[]) {
	//Parse arguments
	//index of argument with output file if specified
	int output_file_override = 0;
	int i;
	for (i=1;i<argc;i++) {
		if (!strcmp(argv[i],"-help")) {
			printf("Cminus Compiler Help:\n");
			printf("\tUsage: cminus [-help] [-o <output_file>] [-d <debug_flags]\n");
			printf("\tInput is read from stdin\n");
			printf("Options:\n");
			printf("\t-help:\tPrint usage information. This will not compile anything\n");
			printf("\t-o:\tSpecify output file. Defaults to 'out.asm'\n");
			printf("\t-d:\tToggle various debug flags.\n");
			printf("\t   \tEach character refers to a different set of debug information to print.\n");
			printf("\t   \t\t'y': Print YACC debug information.\n");
			printf("\t   \t\t'a': Print Abstract Syntax Tree debug information.\n");
			printf("\t   \t\t'l': Print Lexer debug information.\n");
			printf("\t   \t\t's': Print Symbol Table debug information.\n");
			printf("\t   \t\t'e': Print Emitter debug information.\n");
			exit(0);
		}
		if (strcmp(argv[i],"-o") == 0) {
			i++;
			if (i >= argc) {
				printf("Missing argument to '-o' option!\nUse option -help for details.\n");
				exit(1);
			}
			output_file_override = i;
		}
		else if (strcmp(argv[i],"-d") == 0) {
			i++;
			if (i >= argc) {
				printf("Missing argument to '-d' option!\nUse option -help for details.\n");
				exit(1);
			}
			//Parse debug options
			int j;
			for(j=0;j<strlen(argv[i]);j++) {
				char c = argv[i][j];
				switch (c) {
					case 'y': yaccdebug		= 1; break;
					case 'a': ast_debug		= 1; break;
					case 'l': lexdebug		= 1; break;
					case 's': symtab_debug	= 1; break;
					case 'e': emit_debug	= 1; break;
					default: printf("Unrecognized character '%c' in debug flags!\nUse option -help for details.\n");
				}
			}
		}
	}

	//Parse input
	yyparse();

	if (ast_debug) {
		//Print Abstract Syntax Tree
		ast_display_all();
	}
	if (symtab_debug) {
		//Print global symbol table
		fprintf(stderr,"Global Symbol table:\n");
		symtab_display();
	}

	//Call emitter
	if (output_file_override)
		emit_all(argv[output_file_override],ast_root);
	else
		emit_all("out.asm",ast_root);
}
