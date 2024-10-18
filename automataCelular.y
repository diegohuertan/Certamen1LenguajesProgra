/* Declarations-definitions */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdbool.h>
extern FILE *yyin;

int yylex();
void yyerror(const char*);

typedef struct seir {
    int estados[4];
} seir;

typedef struct celula {
    seir estado;
} celula;

typedef struct automataCelular {
    char color[50];
    celula **celulas;
    int filas;
    int columnas;
} automataCelular;

automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir estado);
seir crearSeir(int s, int e, int i, int r);
void imprimirAutomata(automataCelular* automata);
void imprimirVecindad(int vecindad[8][2]);
void obtenerVecindadMoore(automataCelular* automata, int i, int j, int vecindad[8][2]);

automataCelular* automata;

%}

%union {
    int ival;
    char strval[50];
}

/* token detection rules (re) */

%token<strval> CREARAUTOMATA DEFAULT S E I R COLOR VECINDAD
%token<ival> NUMERO
%token ENDLINE

/* Sintax detection rules (re) */

%%
instrucciones:
    instrucciones instruccion
    | instruccion
    ;

instruccion:
    funcion endline
    | endline
    ;

funcion: CREARAUTOMATA COLOR NUMERO NUMERO S NUMERO E NUMERO I NUMERO R NUMERO {
        seir estado = crearSeir($6, $8, $10, $12);
        automata = crearAutomataSimetrico($2, $3, $4, estado);
        imprimirAutomata(automata);
    }
    |
    VECINDAD NUMERO NUMERO {
        int vecindad[8][2];
        obtenerVecindadMoore(automata, $2 ,$3, vecindad);
        imprimirVecindad(vecindad);
    }
    ;
endline: ENDLINE
    ;

%%

automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir estado) {
    automataCelular* automata = (automataCelular*)malloc(sizeof(automataCelular));
    strcpy(automata->color, color);
    automata->filas = filas;
    automata->columnas = columnas;
    automata->celulas = (celula**)malloc(filas * sizeof(celula*));
    for (int i = 0; i < filas; i++) {
        automata->celulas[i] = (celula*)malloc(columnas * sizeof(celula));
    }
    for (int i = 0; i < filas; i++) {
        for (int j = 0; j < columnas; j++) {
            automata->celulas[i][j].estado = estado;
        }
    }
    return automata;
}

seir crearSeir(int s, int e, int i, int r) {
    seir estado;
    estado.estados[0] = s;
    estado.estados[1] = e;
    estado.estados[2] = i;
    estado.estados[3] = r;
    return estado;
}

void obtenerVecindadMoore(automataCelular* automata, int i, int j, int vecindad[8][2]) {
    // Definir desplazamientos de Moore
    int dx[] = {-1, -1, -1, 0, 0, 1, 1, 1};
    int dy[] = {-1, 0, 1, -1, 1, -1, 0, 1};
    int k = 0;

    // Iterar sobre los 8 vecinos
    for (int d = 0; d < 8; d++) {
        int ni = i + dx[d]; // Nueva fila
        int nj = j + dy[d]; // Nueva columna

        // Verificar si está dentro de los límites del autómata
        if (ni >= 0 && ni < automata->filas && nj >= 0 && nj < automata->columnas) {
            vecindad[k][0] = ni;
            vecindad[k][1] = nj;
        } else {
            // Si el vecino está fuera de los límites, poner -1 para indicar que no es válido
            vecindad[k][0] = -1;
            vecindad[k][1] = -1;
        }
        k++;
    }
}

void imprimirVecindad(int vecindad[8][2]) {
    for (int k = 0; k < 8; k++) {
        printf("Vecino %d: (%d, %d)\n", k, vecindad[k][0], vecindad[k][1]);
    }
}

void imprimirAutomata(automataCelular* automata) {
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            printf("%d %d %d %d\n", automata->celulas[i][j].estado.estados[0], automata->celulas[i][j].estado.estados[1], automata->celulas[i][j].estado.estados[2], automata->celulas[i][j].estado.estados[3]);
        }
    }
}

void yyerror(const char* msg) {
    printf("error: %s\n", msg);
}

int main(int argc, char **argv) {
    // Intentar abrir el archivo de comandos predeterminado
    yyin = fopen("universo.txt", "r");
    if (yyin) {
        yyparse();
        fclose(yyin);  // Cierra el archivo después de procesarlo
    }

    // Cambiar la entrada a stdin para continuar leyendo instrucciones
    yyin = stdin;
    yyparse();

    return 0;
}