/*
* This header file contains forward-declarations of various types used in the
* compiler. This is so that individual components can compile without needing
* to include the headers of other components, should just have to include
* common.h
*
* Also includes definitions for some functions to get string representations
* of enums
*
* - Cameron Tauxe
*
* 4 Apr, 2018
*	- Did I just make dependency hell better or worse? We'll soon see
* 20 Apr, 2018
*	- Added WRITE_STR_STMT to AST_NODE types
*/

#ifndef COMMON
#define COMMON

/****************
* Global Typedefs
*****************/

//Variable type enum
typedef enum VAR_TYPE VAR_TYPE;
//Operator Enum
typedef enum OPERATOR OPERATOR;

/****************
* AST Typedefs
*****************/

/**
* Enum for the type of an abstract syntax tree node.
* These typically correspond to individual productions of the
* cminus grammar.
*/
typedef enum AST_TYPE AST_TYPE;

/**
* Some Node types may require extra children for information.
* The nature of this extra data depends on the type so it is
* stored in a union so that it can be given a descriptive name.
*/
typedef struct AST_Node AST_Node;

/**
* Struct defining a single node on the abstract syntax tree.
* Not all the values defined here are used by all types of nodes.
* (i.e. many may be NULL most of the time)
*/
typedef union AST_EXTRA_NODE AST_EXTRA_NODE;

/****************
* symtab Typedefs
*****************/

/**
* Struct for a node on the linked list.
* Representing a single symbol
**/
typedef struct Symtab_Node Symtab_Node;

/****************
* Global Type Implementations
*****************/

//Implement VAR_TYPE
enum VAR_TYPE {
	TYPE_INT,
	TYPE_VOID
};

/**
* Define string representations for all var_types
*/
static char INT_STRING[] = "int";
static char VOID_STRING[] = "void";

/**
* Helper function to get a string representation of
* of a VAR_TYPE
*/
char *var_type_to_string(VAR_TYPE t);

//Implement OPERATOR
enum OPERATOR {
	PLUS,
	MINUS,
	TIMES,
	DIVIDE,
	EQ, //(EQ)ual
	NE, //(N)ot (E)qual
	GE, //(G)reater or (E)qual
	LE, //(L)ess or (E)qual
	GT, //(G)reater (T)han
	LT,  //(L)ess (T)han
	UNKNOWN_OP
};

/**
* Define string representations for all operators
*/
static char PLUS_STRING[] = "+";
static char MINUS_STRING[] = "-";
static char TIMES_STRING[] = "*";
static char DIVIDE_STRING[] = "/";
static char EQ_STRING[] = "==";
static char NE_STRING[] = "!=";
static char GE_STRING[] = ">=";
static char LE_STRING[] = "<=";
static char GT_STRING[] = ">";
static char LT_STRING[] = "<";
static char UNKNOWN_OP_STRING[] = "??";

/**
* Helper function to get a string representation of
* an operator
*/
char *operator_to_string(OPERATOR op);

/****************
* AST Type Implementations
*****************/

//Implment AST_TYPE
/*
* The comments alongside each value explain the purpose of each field
* of the AST_Node struct as it is used by this type
*/
enum AST_TYPE  {
	PROGRAM, 	//root ast_node
				//next: first declaration

	VAR_DECL,	//next: next declaration
				//name: ID string
				//symbol: Symtab_Node representing declared variable
				//value: array size (NULL if not an array)
				//var_type: variable type

	FUN_DECL, 	//next: next declaration
				//name: ID string
				//symbol: Symtab_Node representing declared variable
				//value: offset size of the function (including temp variables)
				//var_type: return type
				//s1.fun_params: PARAM node (NULL if params are void)
				//s2.fun_body: corresponding BLOCK node

	PARAM,		//next: next parameter
				//name: ID string
				//symbol: Symtab_Node representing parameter
				//var_type: parameter type

	BLOCK,		//next: next statement
				//s1.block_decls: (VAR_DECL node)
				//s2.block_stmts: statements (STMT nodes)

	EXPR_STMT,	//next: next statement
				//s1.expr: EXPR node

	IF_STMT,	//next: next statement
				//s1.condition: condition (EXPR nodes)
				//s2.if_body: (STMT nodes)
				//s3.else_body: (STMT nodes) (NULL if no else part)

	LOOP_STMT,	//next: next statement
				//s1.condition: condition (EXPR nodes)
				//s2.loop_body: (STMT nodes)

	RET_STMT,	//next: next statement
				//s1.expr: expression (EXPR nodes) (can be NULL)

	READ_STMT,	//next: next statement
				//s1.var: VAR node

	WRITE_STMT,	//next: next statement
				//s1.expr: EXPR nodes
				
	WRITE_STR_STMT,	//next: next statement
					//value: Unique ID for this write statement
						//(this is needed by the emitter)
					//name: The string to write

	VAR_EXPR,	//name: ID string
				//var_type: the type of the variable
				//symbol: Symtab_Node representing the variable
				//s1.expr: If an array access, this is the offset expression

	ASS_EXPR,	//assignment expression
				//s1.var: VAR_EXPR node (left side)
				//s2.expr: EXPR nodes (right side)
				//var_type: the type of the expression's value
				//symbol: Symtab_Node representing the temporary variable holding
					//this expression's value

	SIMP_EXPR,	//s1.expr_left: left side of expression (EXPR nodes)
				//s2.expr_right: right side of expression (EXPR nodes)
				//op: operator (AST_OPERATOR)
				//var_type: the type of the expression's value
				//symbol: Symtab_Node representing the temporary variable holding
					//this expression's value

	NUM_EXPR,	//value: integer value
				//var_type: the type of the experssion's value (always INT in this case)

	CALL_EXPR,	//s1.call_args: arguments (ARG node)
				//name: ID string
				//var_type: the return type of the function
				//symbol: Symtab_Node representing the function

	ARG,		//next: next argument
				//s1.expr: EXPR (nodes)
				//symbol: temporary variable holding the expression's value
	UNKNOWN_TYPE
};

//Implement AST_EXTRA_NODE
union AST_EXTRA_NODE {
	AST_Node	*fun_body, //body of a function declaration (a BLOCK node)
				*fun_params, //parameters to a function declaration (tree of PARAM nodes)
				*block_stmts, //statements inside a block (tree of STMT nodes)
				*block_decls, //local declarations inside a block (tree of VAR_DECL nodes)
				*expr, //expression associated with a statement (tree of EXPR nodes)
				*expr_right, //right side of a SIMP_EXPR (tree of EXPR nodes)
				*expr_left, //left side of a SIMP_EXPR (tree of EXPR nodes)
				*var, //variable in an assignment (VAR_EXPR node)
				*call_args, //arguments to a function call (tree of ARG nodes)
				*if_body, //body of an if statement (tree of STMT nodes)
				*else_body, //body of an else statement (tree of STMT nodes)
				*loop_body, //body of a loop (tree of STMT nodes)
				*condition, //condition for a loop or if (tree of EXPR nodes)
				*any;
};

//Implment AST_Node
struct AST_Node {
	//this should be defined for all types
	AST_TYPE type;
	//this will be defined in most EXPR-type nodes
	OPERATOR op;
	//this will be defined in any node that references a variable
	//(or the effective type of an expression)
	VAR_TYPE var_type;
	//most types that involve an identifier will use this
	//(WRITE_STR_STMTs also use this for their string)
	char *name;
	//types that reference something on the symbol will use this
	//(expressions will use this to hold temporary variables)
	Symtab_Node *symbol;
	//types with a static, numeric value will use this
	int value;
	//types that are a part of a sequence will use this
	AST_Node *next;
	//types that require additional children define them here
	//(there can be up to three additional children)
	AST_EXTRA_NODE s1, s2, s3;
};

/****************
* symtab Type Implementations
*****************/

//Implement Symtab_Node
struct Symtab_Node
{
	//string of the symbol's name
	char *symbol;
	//offset from stack base address to the adress of this symbol
	//if level is 0, then this is a static variable and the offset is from
	//the beginning of static memory
	int offset;
	//The array size of the variable (0 if a function)
	int size;
	//The scope of the symbol. 0 for static variables, otherwise is the number
	//of nested code blocks the symbol is declared in
	int level;
	//Whether or not the symbol represents a function
	int isFunc;
	//Whether or not the symbol represents a variable array
	int isArr;
	//If the symbol is a function, this is a pointer to the node on
	//the AST reprenting the function's parameters
	//Null if the symbol is not a function or if it is but has no parameters
	AST_Node *params;
	//The fun_decl or var_decl AST Node representing this symbol's declaration
	AST_Node *declaration;
	//The type of the symbol, INT or VOID
	VAR_TYPE type;
	//Reference to the next node in the linked list
	Symtab_Node *next;
};

#endif
