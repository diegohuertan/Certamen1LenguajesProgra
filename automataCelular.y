%{
#include "automataCelular.h"
extern FILE *yyin;

// Declaración de constantes globales
const double BETA = 0.3;   // Tasa de infección
const double SIGMA = 0.5;  // Tasa de morbilidad (E -> I)
const double GAMMA = 1.0 / 3.0; // Tasa de recuperación (7 días)
const double DT = 0.7;      // Paso de tiempo
const int POBLACION_MAXIMA = 100;

// Declaraciones de funciones
int yylex();
void yyerror(const char*);
automataCelular* automata;
seir* convertirSubarraysASeir(int** subarrays, int length); // Declaración de la función
%}

%union {
    int ival;
    char* strval;
    int** subarraylist;  // Para almacenar una lista de subarrays
}

/* Definiciones de tokens */
%type <subarraylist> celulas
%token<strval> CREARAUTOMATA DEFAULT S E I R COLOR VECINDAD SIMULAR
%token<ival> NUMERO
%token<subarraylist> ESTADOSSEIR
%token ENDLINE

/* Sintax detection rules (re) */

%%
instrucciones:
    instrucciones instruccion
    | instruccion
;

instruccion:
    funcion ENDLINE
    | ENDLINE
    ;

funcion: CREARAUTOMATA COLOR NUMERO NUMERO celulas {
        seir* listaseir = convertirSubarraysASeir($5, $3 * $4);  // Cambiar seir** a seir*
        automata = crearAutomataSimetrico($2, $3, $4, listaseir); // Cambiar listaseir2 a listaseir
        imprimirAutomata(automata);
    }
    |
    VECINDAD NUMERO NUMERO {
        int vecindad[8][2];
        obtenerVecindadMoore(automata, $2 ,$3, vecindad);
        imprimirVecindad(vecindad);
    }
    |
    SIMULAR {
        // Simular el autómata celular
        for (int i = 0; i < automata->filas; i++) {
            for (int j = 0; j < automata->columnas; j++) {
                actualizar_celda_con_vecinos(automata, i, j);
            }
        }
        imprimirAutomata(automata);
    }
    ;
celulas:
    ESTADOSSEIR {
        $$ = $1;  // Asigna el valor del subarray a $$ para que esté disponible
        printf("ESTADOSSEIR:\n");
        for (int i = 0; i < 2 * 2; i++) {
            printf("(%d, %d, %d, %d)\n", $1[i][0], $1[i][1], $1[i][2], $1[i][3]);
        }
    }
    | ENDLINE {
        $$ = NULL;  // También asigna NULL en este caso para el retorno
    }
    ;

%%

seir* convertirSubarraysASeir(int** subarrays, int length) {
    seir* listaseir = (seir*)malloc(length * sizeof(seir));
    for (int i = 0; i < length; i++) {
        listaseir[i] = crearSeir(subarrays[i][0], subarrays[i][1], subarrays[i][2], subarrays[i][3]);
    }
    return listaseir;
}

automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir* estados) { // Cambiar seir** a seir*
    automataCelular* automata = (automataCelular*)malloc(sizeof(automataCelular));
    strcpy(automata->color, color);
    automata->filas = filas;
    automata->columnas = columnas;
    automata->celulas = (celula**)malloc(filas * sizeof(celula*));
    
    int estado_index = 0;
    
    for (int i = 0; i < filas; i++) {
        automata->celulas[i] = (celula*)malloc(columnas * sizeof(celula));
        for (int j = 0; j < columnas; j++) {
            // Asigna un estado de la lista a cada celda
            automata->celulas[i][j].estado = estados[estado_index++];
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

void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna) {
    celula* celda = &automata->celulas[fila][columna];
    double S = celda->estado.estados[0];
    double E = celda->estado.estados[1];
    double I = celda->estado.estados[2];
    double R = celda->estado.estados[3];
    double poblacion_maxima = POBLACION_MAXIMA;

    // Acumular infectados de los vecinos (Vecindad de Moore)
    double I_vecinos = 0;
    int vecinos_contados = 0;
    int vecindad[8][2];
    obtenerVecindadMoore(automata, fila, columna, vecindad);

    for (int k = 0; k < 8; k++) {
        int ni = vecindad[k][0];
        int nj = vecindad[k][1];
        if (ni != -1 && nj != -1) {
            I_vecinos += automata->celulas[ni][nj].estado.estados[2];
            vecinos_contados++;
        }
    }

    if (vecinos_contados > 0) {
        I_vecinos /= vecinos_contados;
    }

    // Cálculo de los cambios
    double dS = -BETA * S * I_vecinos * DT;
    double dE = (BETA * S * I_vecinos - SIGMA * E) * DT;
    double dI = (SIGMA * E - GAMMA * I) * DT;
    double dR = GAMMA * I * DT;

    // Actualizar los valores de la celda
    celda->estado.estados[0] += dS;
    celda->estado.estados[1] += dE;
    celda->estado.estados[2] += dI;
    celda->estado.estados[3] += dR;

    // Asegurarse de que no haya valores negativos
    if (celda->estado.estados[0] < 0) celda->estado.estados[0] = 0;
    if (celda->estado.estados[1] < 0) celda->estado.estados[1] = 0;
    if (celda->estado.estados[2] < 0) celda->estado.estados[2] = 0;
    if (celda->estado.estados[3] < 0) celda->estado.estados[3] = 0;

    // Asegurarse de que la población total no exceda la población máxima
    double total_poblacion = celda->estado.estados[0] + celda->estado.estados[1] + celda->estado.estados[2] + celda->estado.estados[3];
    if (total_poblacion > poblacion_maxima) {
        double factor = poblacion_maxima / total_poblacion;
        celda->estado.estados[0] *= factor;
        celda->estado.estados[1] *= factor;
        celda->estado.estados[2] *= factor;
        celda->estado.estados[3] *= factor;
    }
}

void yyerror(const char* msg) {
    printf("error: %s\n", msg);
}

int main(int argc, char **argv) {
    // Intentar abrir el archivo de comandos predeterminado
    yyin = fopen("automata.txt", "r");
    if (yyin) {
        yyparse();
        fclose(yyin);  // Cierra el archivo después de procesarlo
    }

    // Cambiar la entrada a stdin para continuar leyendo instrucciones
    yyin = stdin;
    yyparse();

    return 0;
}