%{
    #include "automataCelular.tab.h"
    #include <string.h>
    #include <stdlib.h>
%}

/* token detection rules (re) */

%%

[0-9]+       { yylval.ival = atoi(yytext); return NUMERO; }
[a-z]+    { strcpy(yylval.strval, yytext); return COLOR; }
"crear automata simetrico" { return CREARAUTOMATA; }
"tipo vecindad" { return TIPOVECINDAD; }
"S"          { return S; }
"E"          { return E; }
"I"          { return I; }
"R"          { return R; }
\n           { return ENDLINE; }

%%

int yywrap() {
    if (yyin != stdin) {
        fclose(yyin);  // Cerrar el archivo si no es stdin
        yyin = stdin;  // Cambiar la entrada a stdin
        return 0;      // Continuar procesando
    }
    return 1;  // Finalizar el análisis cuando se alcance EOF en stdin
}