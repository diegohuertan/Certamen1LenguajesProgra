%{
#include "automataCelular.h"
#include "automataCelular.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaración de la función para convertir la cadena en una lista de subarrays
int** convertirCadenaASubarrays(char* cadena, int* longitud);
%}

/* token detection rules (re) */

%%

[0-9]+       { yylval.ival = atoi(yytext); return NUMERO; }
"vecindad" { return VECINDAD; }
"crear automata simetrico" { return CREARAUTOMATA; }
"simular"   { return SIMULAR; }
"asimetrico" { return ASIMETRICO; }
"asignar"   { return ASIGNAR; }
"S"          { return S; }
"E"          { return E; }
"I"          { return I; }
"R"          { return R; }
(s[0-9]+[ \t]e[0-9]+[ \t]+i[0-9]+[ \t]+r[0-9]+[ \t]*)+ {
    // Convertir la cadena en una lista de subarrays y pasarla a Bison
    int longitud;
    yylval.subarraylist = convertirCadenaASubarrays(yytext, &longitud);
    return ESTADOSSEIR;
}
[a-z]+    { yylval.strval = strdup(yytext); return COLOR; }

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

// Implementación de la función para convertir la cadena en una lista de subarrays
int** convertirCadenaASubarrays(char* cadena, int* longitud) {
    int** lista = NULL;
    int count = 0;

    char* token = strtok(cadena, " \t\n");
    while (token != NULL) {
        if (token[0] == 's') {
            lista = realloc(lista, (count + 1) * sizeof(int*));
            lista[count] = malloc(4 * sizeof(int));
            lista[count][0] = atoi(token + 1); // Convertir el número después de 's'

            // Captura e, i, r para el mismo grupo
            token = strtok(NULL, " \t\n");
            if (token != NULL && token[0] == 'e') {
                lista[count][1] = atoi(token + 1); // Convertir el número después de 'e'
            }
            token = strtok(NULL, " \t\n");
            if (token != NULL && token[0] == 'i') {
                lista[count][2] = atoi(token + 1); // Convertir el número después de 'i'
            }
            token = strtok(NULL, " \t\n");
            if (token != NULL && token[0] == 'r') {
                lista[count][3] = atoi(token + 1); // Convertir el número después de 'r'
            }

            count++;
        }
        token = strtok(NULL, " \t\n");
    }

    *longitud = count;
    return lista;
}
