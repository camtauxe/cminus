/**
* Implementation of symtable.h (see header file for details)
*
* Code sourced from: forgetcode.com/C/101-Symbol-table
* (now heavily modified)
*
* 1 Feb, 2018
*	- Formatting and documentation by Cameron Tauxe
* 7 Feb, 2018
*	- Modified to be used by other programs (instead of directly by user)
*		- Removed main()
*		- Removed modify()
*		- Removed scanf calls. Delete() and Insert() now use parameters instead of asking user.
*		- Other cleanup
* 9 Feb, 2018
*	- Added printErr option to Insert()
*	- Removed label field from Symtab struct. Uses symbol instead
* 28 Feb, 2018
*	- Declarations moved to symtable.h
*	- Updated to 28 Feb, 2018 refactor of symtable.h
* 1 Apr, 2018
*	- Implemented 1 Apr, 2018 changes to symtab.h
* 4 Apr, 2018
*	- Implemented 4 Apr, 2018 changes to symtab.h
* 7 Apr, 2018
*	- Implemented 7 Apr, 2018 changes to symtab.h
* 8 Apr, 2018
*	- symtab_compare_params now checks that isArr matches
* 16 Apr, 2018
*	- Fixed scalar variables having a size of 0
* 18 Apr, 2018
*	- Improved parameter/argument matching
* 21 Apr, 2018
*	- Fixed symtab_search_recursive not working for levels 2 or higher
* 23 Apr, 2018
*	- parameter/argument matching no longer cares about arrays
*
*	Cameron Tauxe
**/

#include"symtab.h"
#include<stdio.h>
#include<malloc.h>
#include<string.h>
#include<stdlib.h>

//symtab_create_variable implementation
Symtab_Node* symtab_create_variable(char* symbol, VAR_TYPE type, int level, int offset) {
	Symtab_Node* p;
	p = malloc(sizeof(Symtab_Node));
	p->symbol = symbol;
	p->type = type;
	p->level = level;
	p->offset = offset;
	p->isFunc = 0;
	p->params = NULL;
	p->isArr = 0;
	p->size = 1;
	p->next = NULL;
	return p;
}

//symtab_create_array implementation
Symtab_Node* symtab_create_array(char* symbol, VAR_TYPE type, int level, int offset, int size) {
	Symtab_Node* p;
	p = malloc(sizeof(Symtab_Node));
	p->symbol = symbol;
	p->type = type;
	p->level = level;
	p->offset = offset;
	p->isFunc = 0;
	p->params = NULL;
	p->isArr = 1;
	p->size = size;
	p->next = NULL;
	return p;
}

//symtab_create_temp implementation
Symtab_Node* symtab_create_temp(int num, VAR_TYPE type, int level, int offset) {
	Symtab_Node* p;
	//create name for temp variable
	char *symbol;
	char buffer[100];
	sprintf(buffer,"_T%d",num);
	symbol = strdup(buffer);
	//create symbol
	p = malloc(sizeof(Symtab_Node));
	p->symbol = symbol;
	p->type = type;
	p->level = level;
	p->offset = offset;
	p->isFunc = 0;
	p->params = NULL;
	p->isArr = 0;
	p->size = 0;
	p->next = NULL;
	return p;
}

//symtab_create_function implementation
Symtab_Node* symtab_create_function(char* symbol, VAR_TYPE type, AST_Node *params) {
	Symtab_Node* p;
	p = malloc(sizeof(Symtab_Node));
	p->symbol = symbol;
	p->type = type;
	p->isFunc = 1;
	p->params = params;
	p->level = 0;
	p->offset = 0;
	p->isArr = 0;
	p->size = 0;
	p->next = NULL;
	return p;
}

//symtab_insert implementation
int symtab_insert(Symtab_Node *node) {
	//Search for symbol already in table
	Symtab_Node *found;//search result
	found=symtab_search(node->symbol,node->level);
	//Don't insert if the symbol already exists in the table
	if(found != NULL) {
		if (symtab_debug)
			fprintf(stderr,"Cannot insert symbol '%s' because it already exists in the symbol table.\n", node->symbol);
		return 0;
	}
	//Add symbol to the table if it doesn't already exist
	else
	{
		//If this is the first node being added, it is both the first and last node in the list
		if(symtab_size == 0) {
			symtab_first = node;
			symtab_last = node;
		}
		//Otherwise append to the end of the list
		else {
			symtab_last->next = node;
			symtab_last = node;
		}
		symtab_size++;

		if (symtab_debug) {
			fprintf(stderr,"New symbol '%s' inserted!\n",node->symbol);
			symtab_display();
		}

		return 1;
	}
}

//symtab_display implementation
void symtab_display() {
	int i;//iterating index
	Symtab_Node *p;//pointer to current node when iterating
	p=symtab_first;

	fprintf(stderr,"\n\tSYMBOL\t\tTYPE\tLEVEL\tOFFSET\tFUNC?\tARR?\tSIZE\n");
	//Iterate through linked list, printing information
	for(i=0;i<symtab_size;i++) {
		fprintf(stderr,"\t%s\t\t%s\t%d\t%d\t%d\t%d\t%d\n",
			p->symbol,
			var_type_to_string(p->type),
			p->level,
			p->offset,
			p->isFunc,
			p->isArr,
			p->size);
		p=p->next;
	}
}

//symtab_search implementation
Symtab_Node* symtab_search(char* sym, int level) {
	int i; //iterating index
	Symtab_Node *p; //pointer to current node when iterating
	p=symtab_first;

	//Iterate through linked list
	for(i=0;i<symtab_size;i++) {
		if(strcmp(p->symbol,sym) == 0 && p->level == level)
			return p;
		p=p->next;
	}
	return NULL; //return NULL if node was not found
}

Symtab_Node* symtab_search_recursive(char* sym, int level) {
	Symtab_Node *p; //search result

	//Base case. Level is 0
	if (level <= 0)
		return symtab_search(sym,level);

	p = symtab_search(sym,level);
	if (p != NULL)
		return p;
	//If the symbol isn't found at current level, search next lowest level
	else
		return symtab_search_recursive(sym,level-1);
}

//symtab_delete implementation
int symtab_delete(Symtab_Node *to_delete)
{
	int i;
	Symtab_Node *previous; //pointer to previous node

	//If the matched node was the first in the list,
	//remove it by setting first to point to first->next
	if(to_delete == symtab_first) {
		symtab_first=symtab_first->next;
		//free(to_delete);
		symtab_size--;

		if (symtab_debug) {
			fprintf(stderr,"Symbol deleted!\n");
			symtab_display();
		}
		return 1;
	}
	//If the matched node is the last in the list
	//remove it by setting the previous node's next to NULL
	else if(to_delete == symtab_last) {
		//iterate to second-to-last node
		previous = symtab_first;
		for (i=0;i<symtab_size;i++) {
			if (previous->next == symtab_last) {
				previous->next = NULL;
				break;
			}
			previous = previous->next;
		}
		symtab_last = previous;
		//free(to_delete);
		symtab_size--;
		if (symtab_debug) {
			fprintf(stderr,"Symbol deleted!\n");
			symtab_display();
		}
		return 1;
	}

	//If the matched node is anywhere else in the list,
	//remove it by setting its previous node's next to its next

	//iterate to second-to-last node
	previous = symtab_first;
	for (i=0;i<symtab_size;i++) {
		if (previous->next == to_delete) {
			previous->next = to_delete->next;
			//free(to_delete);
			symtab_size--;
			if (symtab_debug) {
				fprintf(stderr,"Symbol deleted!\n");
				symtab_display();
			}
			return 1;
		}
		previous = previous->next;
	}

	//If the code execution gets here, it means the node was not in the list
	return 0;
}

//symtab_delete_level implementation
int symtab_delete_level(int level) {
	int deleted = 0;
	//Continually search the table for nodes with the given level,
	//deleting them until there are no more.
	Symtab_Node *found;
	int i;
	Symtab_Node *p; //current node while iterating

	do {
		found = NULL;
		p = symtab_first;
		for(i=0;i<symtab_size;i++) {
			if (p->level == level) {
				found = p;
				break;
			}
			p=p->next;
		}

		if (found != NULL) {
			symtab_delete(found);
			deleted += found->size;
		}
	} while(found != NULL);

	return deleted;
}

//symtab_compare_params implementation
int symtab_compare_params(AST_Node *param_list, AST_Node *arg_list) {
	//if both lists are empty, return true
	if (param_list == NULL && arg_list == NULL)
		return 1;
	if (param_list != NULL && arg_list != NULL) {
		//If neither are empty, check types and then recurse
		if (param_list->var_type == arg_list->s1.expr->var_type) {
			return symtab_compare_params(param_list->next,arg_list->next);
		}
		return 0;
	}
	//If one is empty and the other isn't return false
	return 0;
}
