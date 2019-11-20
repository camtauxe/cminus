/**
* Header file for a cminus abstract syntax tree.
* Note that this specifies a single, static tree. With this
* implementation, having more than one tree in a single program
* is not possible.
*
* See ast.c for implementations
*
* Cameron Tauxe
*
* 28 Feb, 2018
*	- Initial Version
* 1 March, 2018
*	- Defined all AST_TYPEs and AST_OPERATORs
*	- Corrected behavior of ast_attach_left (was described incorrectly)
* 2 March, 2018
*	- Fixed ast_debug causing linker problems
*	- Removed ast_display_node
*	- Added ast_operator_to_string, ast_indent
*	- Added string representations for operataors
*	- Added variable types
* 4 April, 2018
*	- Type definitions moved to common.h
*/

#ifndef AST_H
#define AST_H

#include"common.h"

//Debug flag. If true, debug statements may be printed to stderr
static int ast_debug = 0;

/*
* The root node of the abstract syntax tree
*/
AST_Node* ast_root;

/**
* Instantiate a new abstract syntax tree node (using malloc)
* with the given type.
* Returns a pointer to the newly created node
*/
AST_Node* ast_create_node(AST_TYPE _type);

/*
* Attach the node 'child' to the left-most child of the node 'parent'
* Will go through parent's children until one without a left-hand
* child is found and attach child there.
*/
//Currently unused
//void ast_attach_left(AST_Node *parent, AST_Node *child);

/*
* Print the entirety of the abstract syntax tree.
* This is a shorthand for calling ast_display(0, ast_root)
*/
void ast_display_all();

/*
* Print the abstact syntax tree starting from the given node 'root'
* as the root.
* 'level' indicates how much to indent before printing
*/
void ast_display(int level, AST_Node *root);

/**
* Helper function to indent stdout n times
* (used by display functions)
*/
void ast_indent(int n);

#endif
