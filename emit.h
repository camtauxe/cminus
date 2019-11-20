/**
 * Header file for cminus assembly emitter.
 *
 * Writes NASM code to an output file given a reference
 * to the abstract syntax tree and symbol table.
 *
 * See emit.c for implementations.
 *
 * Cameron Tauxe
 *
 * 16 April, 2018
 *	- Initial version
 * 17 April, 2018
 *	- Most functions renamed for brevity
 *	- Added functions to enable emitting functions
 **/

#ifndef EMIT
#define EMIT

#include <stdio.h>
#include "common.h"

//Debug flag. If true, all output will also be written to stderr
//(along with some additional information)
int emit_debug;

//Pointer to output FILE
static FILE *emit_file;
//whether or not the file has been set yet
static int emit_file_set = 0;

//keep track of labels and strings created so far
static int emit_labels = 0;
static int emit_strings = 0;

/**
 * Emit code for an entire program.
 * filename is the name of the file to write to
 * prog_root is root AST_Node representing the program
 **/
void emit_all(char *filename, AST_Node *prog_root);

/**
 * Write the "header" of the NASM code.
 * Writes the "%include 'io64.inc'",
 * the .data section, with all global varaibles and strings
 * and the beginning of the .text section with "global main"
 * if a main function is defined
 * first_decl is either a VAR_DECL or FUN_DECL type node
 * representing the first declaration of the program
 **/
void emit_head(AST_Node *first_decl);

/**
 * Search the entire tree (starting from the given root)
 * for WRITE_STR_STMTs and add their strings to the .data section
 * of the NASM code.
 **/
void emit_search_strings(AST_Node *prog_root);

/**
 * Write a function to the output file.
 * This includes the label declaring the function,
 * and all the necessary stack frame management.
 * fun_decl is a FUN_DECL node representing the function
 **/
void emit_function(AST_Node *fun_decl);

/**
 * Write code to exectute a statement to the output file.
 * stmt is a node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing a statement.
 **/
void emit_statement(AST_Node *stmt);

/**
 * Write code to execute a BLOCK statement to the output file.
 * stmt is a node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing a statement.
 **/
void emit_block_stmt(AST_Node *stmt);

/**
 * Write code to execute an IF/ELSE statement to the output file.
 * stmt is a node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing a statement.
 **/
void emit_if_stmt(AST_Node *stmt);

/**
 * Write code to execute a LOOP (while) statement to the output file.
 * stmt is a node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing a statement.
 **/
void emit_loop_stmt(AST_Node *stmt);

/**
 * Write code to execute a RETURN statement to the output file.
 * stmt is a node representing the statement.
 * After returning, the return value will be in register RSI
 **/
void emit_ret_stmt(AST_Node *stmt);

/**
 * Write code to execute a read statement to the output file.
 * stmt is a node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing a statement.
 **/
void emit_read_stmt(AST_Node *stmt);

/**
 * Write code to exectute a write statement to the output file.
 * stmt is a WRITE_STMT type node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing the statement.
 **/
void emit_write_stmt(AST_Node *stmt);

/**
 * Write code to exectute a write string statement to the output file.
 * stmt is a WRITE_STR_STMT type node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing the statement.
 **/
void emit_write_str_stmt(AST_Node * stmt);

/**
 * Write code to execute an expression statement to the output file.
 * stmt is a EXPR_STMT type node representing the statement.
 * No assumptions should be made about the value of any registers
 * before or after executing the statement.
 **/
void emit_expr_stmt(AST_Node *stmt);

/**
 * Write code to evaluate an expression to the output file.
 * expr is a node representing the expression.
 * After evaluating, the expression's value will be in register RSI
 **/
void emit_handle_expr(AST_Node *expr);

/**
 * Write code to peform an operation to the output file.
 * op is the operation to perform.
 * Assumes the operation's LHS is in RAX
 * and that the RHS is in RBX
 * After performing the operation, the result will be in RAX
 * RBX may be changed as well.
 **/
void emit_handle_operator(OPERATOR op);

/**
 * Write code to handle a variable reference to the output file.
 * var is a VAR_EXPR node representing the variable reference
 * After evaluating, the address of the variable will be in register RAX
 * (this will handle array access, so the value of RAX will be with
 * the offset already applied)
 **/
void emit_handle_var(AST_Node *var);

/**
 * Write a line of SASM code to the console.
 * Writes the line begining with the given label and ending with the given comment.
 * (given label has to include the ':')
 * (given comment has to include the ';')
 * Written line is formatted like so:
 * [label]\t[line]\t\t[comment]\n
 **/
void emit_write_line(char *label, char *line, char *comment);

/*
 * Write a string to the output file.
 * Unlike emit_write_line no special formatting is performed
 * (except for a newline at the end)
 */
void emit_write_plain_line(char *text);

/**
 * Write a newline to the output file
 */
void emit_newline();

#endif
