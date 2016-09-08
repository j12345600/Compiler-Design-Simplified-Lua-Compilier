
a.out: y.tab.c lex.yy.c y.tab.h symbolTable.h symbolTable.cpp
	g++ -o p -w lex.yy.c y.tab.c symbolTable.cpp

lex.yy.c: lex.l y.tab.h
	flex lex.l

y.tab.c: yacc.y
	bison -y -d yacc.y
clean:
	rm a.out lex.yy.c y.tab.c y.tab.h
