/**
* Header file for cminus symbol table implemented as a linked list.
* Note that this specifies a single, static symbol table. With this
* implementation, having more than one symbol table in a single program
* is not possible.
*
* See symtable.c for implementations
*
* Cameron Tauxe
*
* 28 Feb, 2018
*	- Declarations moved from old symtable.c into this file
*	- Renamed identifiers to have 'symtab' prefix
*	- Removed getAddr() function.
*	- symtab_search() now returns a pointer to the found Symtab_Node
*	- symtab_delete() now returns whether or not it actually deleted a node
* 1 Apr, 2018
*	- Added level, offset, isFunc, params and type fields to Symtab_Node struct
*	- Seperated creating and inserting nodes into different functions
*	- Added symtab_search_recursive function
* 4 Apr, 2018
*	- Moved type definitions to common.h
* 7 Apr, 2018
*	- Added symtab_compare_params
*/

#ifndef SYMTAB_H
#define SYMTAB_H

#include"common.h"

/*
* Debug flag. If true, debug statements may be printed to stderr
*/
static int symtab_debug = 0;

/*
* Tracks the current scope level (while parsing)
*/
static int symtab_level = 0;

/*
* Tracks the current offset value for adding new symbols to the table (while parsing)
*/
static int symtab_offset = 0;
//variable to remember the original offset value before parsing a function
static int symtab_global_offset = 0;
//track the highest offset achieved while parsing a function
//used to calculate the "size" of a function
static int symtab_max_offset = 0;

/*
* Tracks of the number of temporary variables (used in evaluating expressions)
* that have been declared so far.
*/
static int symtab_temp_vars = 0;

/*
* int tracking the current size of the symbol table
*/
static int symtab_size = 0;

//The current first and last nodes in the list.
Symtab_Node *symtab_first,*symtab_last;

/**
* Create a Symtab_Node representing a new variable.
* Mallocs a new Symtab_Node struct and initializes it
* with the given symbol, type, level and offset.
* The new node will not be attached to the symbol table
* and must be added with symtab_insert
**/
Symtab_Node* symtab_create_variable(char* symbol, VAR_TYPE type, int level, int offset);

/**
* Creates a Symtab_Node representing a new variable.
* Mallocs a new Symtab_Node struct and initializes it
* with the given symbol, type, level, offset and size.
* The new node will not be attached to the symbol table
* and must be added with symtab_insert
**/
Symtab_Node* symtab_create_array(char* symbol, VAR_TYPE type, int level, int offset, int size);

/**
* Creates a Symtab_Node representing a new temporary variable.
* Mallocs a new Symtab_Node struct and initializes it
* with the given type, level and offset.
* The symbol is formatted as "_T[num]".
* The new node will not be attached to the symbol table
* and must be added with symtab_insert.
* This function will NOT automatically increment symtab_temp_vars
* that must be done yourself contingent on symtab_insert succeeding
**/
Symtab_Node* symtab_create_temp(int num, VAR_TYPE type, int level, int offset);

/**
* Create a Symtab_Node representing a new function.
* Mallocs a new Symtab_Node struct and initializes it
* with the the given symbol, type, and parameters.
* The new node will not be attached to the symbol table
* and must be added with symtab_insert
**/
Symtab_Node* symtab_create_function(char* symbol, VAR_TYPE type, AST_Node *params);

/**
* Insert a new node into the table.
* The given node will be appended to the end of the table
* To add the node, there must not be any other nodes with the same symbol
* at the same level already in the table.
* Returns 1 if completed succesfully
* Returns 0 if an error prevents adding the symbol
**/
int symtab_insert(Symtab_Node *node);

/**
* Print the current symbol table
* (printed to stderr)
**/
void symtab_display();

/**
* Check if a symbol already exists in the symbol table.
* Checks if a node with a symbol matching sym exists at the given level
* in the list.
* Returns a pointer to the node if it is found
* Otherwise returns NULL
**/
Symtab_Node* symtab_search(char* sym, int level);

/**
* Check if a symbol already exists in the symbol table.
* Checks if a node with a symbol matching sym exists at the given level
* OR ANY LOWER LEVEL in the list.
* Returns a pointer to the node if it is found
* Otherwise returns NULL
**/
Symtab_Node* symtab_search_recursive(char* sym, int level);

/**
* Delete a symbol from the table.
* Removes the given node from the list.
* Returns 1 if the node was removed.
* Returns 0 if the node was not removed
* (because it was not in the list to begin with)
**/
int symtab_delete(Symtab_Node *to_delete);

/**
* Delete all symbols at a given level from the table.
* Returns the total size of all deleted symbols
**/
int symtab_delete_level(int level);

/**
* Compare the parameters of a function to the arguments of a call to that function.
* Ensures that there are the same number of parameters and that they are all the same types.
* Returns 1 if they match, otherwise returns 0
**/
int symtab_compare_params(AST_Node *param_list, AST_Node *arg_list);


#endif
