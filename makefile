# Build Cminus Compiler
# 16 April, 2018 - Cameron Tauxe

all: cminus clean

#link object files (lex must be compiled before yacc)
cminus: lex.yy.o y.tab.o common.o ast.o symtab.o emit.o
	gcc -o cminus lex.yy.o y.tab.o common.o ast.o symtab.o emit.o

#Compile lex.yy.o (requires yacc output first)
lex.yy.o: lex.yy.c y.tab.c
	gcc -c lex.yy.c

# Get Lex output (with header file)
lex.yy.c: cminus_lex.l
	lex cminus_lex.l

#Compile y.tab.o (yacc output should already be generated)
y.tab.o:
	gcc -c y.tab.c

# Get Yacc output (also generates header file)
#update if headers change
y.tab.c: cminus_yacc.y common.h ast.h symtab.h
	yacc -d cminus_yacc.y

#Compile common
common.o: common.c common.h
	gcc -c common.c

# Compile ast
ast.o: ast.c ast.h common.h
	gcc -c ast.c

# Compile symtab
symtab.o: symtab.c symtab.h common.h
	gcc -c symtab.c

# Compile emit
emit.o: emit.c emit.h common.h
	gcc -c emit.c

clean:
	rm y.tab.o
	rm common.o
	rm ast.o
	rm symtab.o
	rm emit.o
	rm lex.yy.o
	rm y.tab.c
	rm y.tab.h
	rm lex.yy.c
