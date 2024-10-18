%{
    #include "automataCelular.tab.h"
    #include <string.h>
    #include <stdlib.h>
%}

/* token detection rules (re) */

%%

[0-9]+       { yylval.ival = atoi(yytext); return NUMERO; }
"vecindad" { return VECINDAD; }
"crear automata simetrico" { return CREARAUTOMATA; }
"simular"   { return SIMULAR; }
"S"          { return S; }
"E"          { return E; }
"I"          { return I; }
"R"          { return R; }
[a-z]+    { strcpy(yylval.strval, yytext); return COLOR; }

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