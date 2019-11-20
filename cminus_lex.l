/*
* Lexer for the Cminus language.
*
* Will return the following as tokens (without additional values):
* INT VOID IF ELSE WHILE RETURN READ WRITE
* RELOP_EQ RELOP_NE RELOP_GT RELOP_LT RELOP_GE RELOP_LE
*
* Will return the following as tokens (with additional values):
* ID (string)
* NUM (integer)
* STRING (string) (note that the value will include the quotes around the string)
*
* Will return the following characters as themselves
* [ ] ( ) { } ; , + - * / =
*
* Any other characters are discarded
*
* Cameron Tauxe
*
* 21 Feb, 2018
*	-Initial version.
*	-Lexes input
* 23 Feb, 2018
*	-Fixed accidentally commented-out closing brackets causing lex.yy.c compilation to fail
*	-Disabled lexdebug flag
*	-Removed printerror flag
* 1 March, 2018
*	-Disabled print constants flag
*	-Identifiers can now include underscores and digits
*	-Fixed "Found NUM token" debug readout not printing newline after
* 2 March, 2018
*	-Includes ast.h (needed by y.tab.h)
* 1 April, 2018
*	-No longer allows variable names to start with '_'
* 20 April, 2018
*	-Matches strings
*
* TODO:
*	-Make debug flags toggle-able with command-line options instead of hardcoded
*/

/* Definitions */
letter 	[a-zA-Z]
digit	[0-9]
ID		({letter})({letter}|_|{digit})*
NUM		{digit}{digit}*
string	\"[^\t\r\n]*\"

bracket [\[\]\{\}\(\)]
control [;,=]
mathop	[+\-\*\/]

%{
	#include "common.h"
	#include "y.tab.h"
	#include <stdio.h>
	#include <string.h>

	//Flag indicating whether or not to print debug statements
	int lexdebug = 0;

	//Flag inidicating whether or not to print found constant values
	int printconstant = 0;

	//keep track of current line number while parsing
	int linenum = 1;
%}

%%
	/* Rules */

	/* Reserve Words*/
int		{ if (lexdebug) fprintf(stderr,"Found reserve word 'int'\n");		return (INT);}
void	{ if (lexdebug) fprintf(stderr,"Found reserve word 'void'\n"); 		return (VOID);}
if		{ if (lexdebug) fprintf(stderr,"Found reserve word 'if'\n");		return (IF);}
else	{ if (lexdebug) fprintf(stderr,"Found reserve word 'else'\n");		return (ELSE);}
while	{ if (lexdebug) fprintf(stderr,"Found reserve word 'while'\n");		return (WHILE);}
return	{ if (lexdebug) fprintf(stderr,"Found reserve word 'return'\n");	return (RETURN);}
read	{ if (lexdebug) fprintf(stderr,"Found reserve word 'read'\n");		return (READ);}
write	{ if (lexdebug) fprintf(stderr,"Found reserve word 'write'\n");		return (WRITE);}

	/*Tokens*/
{ID} {
	if (lexdebug) fprintf(stderr,"Found ID token (value:%s)\n", yytext);
	yylval.string = strdup(yytext);
	return (ID);
}
{NUM} {
	//lexdebug flag will override printconstant flag
	if (lexdebug) fprintf(stderr,"Found NUM token (value:%s)\n", yytext);
	else if (printconstant) fprintf(stderr, "Found constant: %s\n", yytext);
	yylval.integer = atoi((const char *)yytext);
	return (NUM);
}
{string} {
	if (lexdebug) fprintf(stderr,"Found STRING token (value:%s)\n", yytext);
	yylval.string = strdup(yytext);
	//Note that yylval includes the quotes around the string
	return (STRING);
}

	/*Control Characters*/
{bracket}|{control} {
	if (lexdebug) fprintf(stderr, "Found control character: %s\n", yytext);
	return (*yytext);
}

	/*Operators*/
{mathop} {
	if (lexdebug) fprintf(stderr, "Found math operator: %s\n", yytext);
	return (*yytext);
}
	/*Relation operators*/
	/*(Relation operators are returned as tokens because some are two characters)*/
\<=	{ if (lexdebug) fprintf(stderr, "Found relation operator '<='\n");	return (RELOP_LE); /*(L)ess than or (E)qual*/}
\>=	{ if (lexdebug) fprintf(stderr, "Found relation operator '>='\n");	return (RELOP_GE); /*(G)reater than or (E)qual*/}
==	{ if (lexdebug) fprintf(stderr, "Found relation operator '=='\n");	return (RELOP_EQ); /*(EQ)ual*/}
!=	{ if (lexdebug) fprintf(stderr, "Found relation operator '!='\n");	return (RELOP_NE); /*(N)ot (E)qual*/}
\<	{ if (lexdebug) fprintf(stderr, "Found relation operator '<'\n"); 	return (RELOP_LT); /*(L)ess (T)han*/}
\>	{ if (lexdebug) fprintf(stderr, "Found relation operator '>'\n");	return (RELOP_GT); /*(G)reater (T)han*/}

	/*Whitespace*/
[ \t]			{/*Ignore Spaces and tabs*/}
(\r\n|\r|\n)	{linenum++; /*increment line number counter*/}
%%

int yywrap(void) {
	return 1;
}
