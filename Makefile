#target: dependences
#	rules (instructions)

VERSION := v1
CC := gcc
INLCUDEPATH := -I .


automataCelular : automataCelular.tab.c lex.yy.c
	$(CC) $(INLCUDEPATH) $(VERSION)/automataCelular.tab.c $(VERSION)/lex.yy.c -ll -o automataCelular


automataCelular.tab.c:
	mkdir -p $(VERSION)
	bison -d automataCelular.y
	mv automataCelular.tab.* $(VERSION)

lex.yy.c:
	lex automataCelular.l
	mv lex.yy.c $(VERSION)

