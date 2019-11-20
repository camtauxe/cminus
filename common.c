/**
* Implements functions defined in common.h
*
* Cameron Tauxe
*
* 4 Apr, 2018
*/

#include"common.h"

//operator_to_string implementation
char* operator_to_string(OPERATOR op) {
	switch (op) {
		case PLUS:		return PLUS_STRING;
		case MINUS: 	return MINUS_STRING;
		case TIMES: 	return TIMES_STRING;
		case DIVIDE:	return DIVIDE_STRING;
		case EQ:		return EQ_STRING;
		case NE:		return NE_STRING;
		case GE:		return GE_STRING;
		case LE:		return LE_STRING;
		case GT:		return GT_STRING;
		case LT:		return LT_STRING;
		default:		return UNKNOWN_OP_STRING;
	}
}

//var_type_to_string implementation
char* var_type_to_string(VAR_TYPE t) {
	//this is a little silly with only two types,
	//but I like expandability
	switch (t) {
		case TYPE_INT:	return INT_STRING;
		default: TYPE_VOID:	return VOID_STRING;
	}
}
