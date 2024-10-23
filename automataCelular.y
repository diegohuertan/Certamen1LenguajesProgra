%{
#include "automataCelular.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <limits.h>
#include <stdbool.h>
extern FILE *yyin;


// Declaración de constantes globales
const double PROB_INFECCION = 0.8;   // Probabilidad de infección
const double PROB_MORBILIDAD = 0.8;  // Probabilidad de morbilidad (E -> I)
const double PROB_RECUPERACION = 0.8; // Probabilidad de recuperación (I -> R)
const int POBLACION_MAXIMA = 100;

// Declaraciones de funciones
int yylex();
void yyerror(const char*);
automataCelular* automata;
seir* convertirSubarraysASeir(int** subarrays, int length); // Declaración de la función
listaAutomatas* listaAutomatasGlobal;
automataAsimetrico* automataAsimetricoGlobal;
%}

%union {
    int ival;
    char* strval;
    int** subarraylist;  // Para almacenar una lista de subarrays
}

/* Definiciones de tokens */
%type <subarraylist> celulas
%token<strval> CREARAUTOMATA DEFAULT S E I R COLOR VECINDAD SIMULAR ASIMETRICO ASIGNAR CONECTAR
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
    | conectar ENDLINE
    | ENDLINE
    ;

funcion: CREARAUTOMATA COLOR NUMERO NUMERO celulas {
    if (!listaAutomatasGlobal) {
        listaAutomatasGlobal = crearListaAutomatas(10);
        if (!listaAutomatasGlobal) {
            yyerror("No se pudo crear la lista de autómatas");
            YYERROR;
        }
    }
    
    if ($5 == NULL) {
        yyerror("Error: celulas es NULL");
        YYERROR;
    }
    
    seir* listaseir = convertirSubarraysASeir($5, $3 * $4);
    if (!listaseir) {
        yyerror("Error al convertir estados SEIR");
        YYERROR;
    }
    
    automataCelular* automata = crearAutomataSimetrico($2, $3, $4, listaseir);
    if (!automata) {
        free(listaseir);
        yyerror("Error al crear autómata simétrico");
        YYERROR;
    }
    
    agregarAutomata(listaAutomatasGlobal, automata);
    imprimirAutomata(automata);
    
    free(listaseir); // Liberar la memoria después de usar listaseir
}

    |
    VECINDAD NUMERO NUMERO {
        int vecindad[8][2];
        obtenerVecindadMoore(automata, $2 ,$3, vecindad);
        imprimirVecindad(vecindad);
    }
    |
    SIMULAR {
        for (int sim = 0; sim < 6; sim++) {
            printf("Simulación %d:\n", sim);
        for (int iter = 0; iter < 20; iter++) {
        for (int i = 0; i < automata->filas; i++) {
            for (int j = 0; j < automata->columnas; j++) {
                actualizar_celda_con_vecinos(automata, i, j);
            }
        }
        }
        imprimirAutomata(automata);
    }
    }
    |
    ASIMETRICO NUMERO NUMERO {
        automataAsimetricoGlobal = crearAutomataAsimetrico($2, $3);
        imprimirAutomataAsimetrico(automataAsimetricoGlobal);
    }
    |
    ASIGNAR NUMERO NUMERO NUMERO {
        if ($4 < listaAutomatasGlobal->cantidad) {
            automataCelular* simetrico = listaAutomatasGlobal->automatas[$4];
            asignarAutomataSimetrico(automataAsimetricoGlobal, $2, $3, simetrico);
            imprimirAutomataAsimetrico(automataAsimetricoGlobal);
        } else {
            fprintf(stderr, "Error: índice de autómata simétrico fuera de rango.\n");
        }
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
conectar:
    CONECTAR NUMERO NUMERO NUMERO NUMERO {
        conectarAutomatas(&automataAsimetricoGlobal->automatas[$2][$3], &automataAsimetricoGlobal->automatas[$4][$5]);
        imprimirAutomataAsimetrico1(automataAsimetricoGlobal);
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

automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir* estados) { 
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
    printf("Automata: %s\n",automata->color);

    // Imprimir encabezado de columnas
    printf("     ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("   Col %d   ", j);
    }
    printf("\n");

    // Imprimir separador
    printf("     ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("-----------");
    }
    printf("\n");

    // Imprimir filas con etiquetas y contenido
    for (int i = 0; i < automata->filas; i++) {
        printf("Fila %d |", i);
        for (int j = 0; j < automata->columnas; j++) {
            printf(" (%2d,%2d,%2d,%2d) ", automata->celulas[i][j].estado.estados[0], automata->celulas[i][j].estado.estados[1], automata->celulas[i][j].estado.estados[2], automata->celulas[i][j].estado.estados[3]);
        }
        printf("\n");
    }
}
void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna) {
    celula* celda = &automata->celulas[fila][columna];
    double s = celda->estado.estados[0];
    double e = celda->estado.estados[1];
    double i = celda->estado.estados[2];
    double r = celda->estado.estados[3];

    // Lógica de actualización
    if (s > 0) {
        s -= 1;
        e += 1;
    } else if (e > 0) {
        e -= 1;
        i += 1;
    } else if (i > 0) {
        i -= 1;
        r += 1;
    }

    // Asegurarse de que los valores no sean negativos
    if (s < 0) s = 0;
    if (e < 0) e = 0;
    if (i < 0) i = 0;
    if (r < 0) r = 0;

    // Aplicar un factor de ajuste
    double factor = 1.0; // Puedes ajustar este valor según sea necesario
    s *= factor;
    e *= factor;
    i *= factor;
    r *= factor;

    // Actualizar los estados de la celda
    celda->estado.estados[0] = s;
    celda->estado.estados[1] = e;
    celda->estado.estados[2] = i;
    celda->estado.estados[3] = r;
}


automataAsimetrico* crearAutomataAsimetrico(int filas, int columnas) {
    automataAsimetrico* automata = (automataAsimetrico*)malloc(sizeof(automataAsimetrico));
    automata->filas = filas;
    automata->columnas = columnas;
    automata->automatas = (automataCelular**)malloc(filas * sizeof(automataCelular*));
    if (!automata->automatas) {
        fprintf(stderr, "Error al asignar memoria para el autómata.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < filas; i++) {
        automata->automatas[i] = (automataCelular*)malloc(columnas * sizeof(automataCelular));
        if (!automata->automatas[i]) {
            fprintf(stderr, "Error al asignar memoria para las celdas del autómata.\n");
            exit(EXIT_FAILURE);
        }
        for (int j = 0; j < columnas; j++) {
            // Inicializar cada celda como un autómata vacío
            strcpy(automata->automatas[i][j].color, "vacio");
            automata->automatas[i][j].filas = 0;
            automata->automatas[i][j].columnas = 0;
            automata->automatas[i][j].celulas = NULL;
        }
    }
    return automata;
}

celula* crearCelula(seir* estado) {
    celula* celda = (celula*)malloc(sizeof(celula));
    celda->estado = *estado;
    return celda;
}

void asignarAutomataSimetrico(automataAsimetrico* automata, int fila, int columna, automataCelular* simetrico) {
    if (fila >= 0 && fila < automata->filas && columna >= 0 && columna < automata->columnas) {
        automata->automatas[fila][columna] = *simetrico;
    } else {
        fprintf(stderr, "Error: posición fuera de los límites del autómata asimétrico.\n");
    }
}

listaAutomatas* crearListaAutomatas(int capacidadInicial) {
    listaAutomatas* lista = (listaAutomatas*)malloc(sizeof(listaAutomatas));
    if (!lista) {
        fprintf(stderr, "Error al asignar memoria para la lista de autómatas.\n");
        exit(EXIT_FAILURE);
    }
    lista->automatas = (automataCelular**)malloc(capacidadInicial * sizeof(automataCelular*));
    if (!lista->automatas) {
        fprintf(stderr, "Error al asignar memoria para la lista de autómatas.\n");
        exit(EXIT_FAILURE);
    }
    lista->cantidad = 0;
    lista->capacidad = capacidadInicial;
    return lista;
}

void agregarAutomata(listaAutomatas* lista, automataCelular* automata) {
    if (lista->cantidad == lista->capacidad) {
        lista->capacidad *= 2;
        lista->automatas = (automataCelular**)realloc(lista->automatas, lista->capacidad * sizeof(automataCelular*));
        if (!lista->automatas) {
            fprintf(stderr, "Error al reasignar memoria para la lista de autómatas.\n");
            exit(EXIT_FAILURE);
        }
    }
    lista->automatas[lista->cantidad++] = automata;
}


void imprimirAutomataAsimetrico(automataAsimetrico* automata) {
    printf("Automata Asimetrico:\n");

    // Imprimir encabezado de columnas
    printf("     ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("   Col %d   ", j);
    }
    printf("\n");

    // Imprimir separador
    printf("     ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("-----------");
    }
    printf("\n");

    // Imprimir filas con etiquetas y contenido
    for (int i = 0; i < automata->filas; i++) {
        printf("Fila %d |", i);
        for (int j = 0; j < automata->columnas; j++) {
            automataCelular* subAutomata = &automata->automatas[i][j];
            if (subAutomata->celulas != NULL) {
                printf(" [%s] ", subAutomata->color);
            } else {
                printf(" [vacio] ");
            }
        }
        printf("\n");
    }

    // Imprimir las submatrices
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            automataCelular* subAutomata = &automata->automatas[i][j];
            if (subAutomata->celulas != NULL) {
                printf("Submatriz en (%d, %d):\n", i, j);
                imprimirAutomata(subAutomata);
                printf("\n");
            }
        }
    }
}

void conectarAutomatas(automataCelular* automata1, automataCelular* automata2) {
    if (automata1 && automata2) {
        agregarConexion(automata1, automata2);
        agregarConexion(automata2, automata1);  // Conexión bidireccional
    }
}

void agregarConexion(automataCelular* automata, automataCelular* conectado) {
    conexion* nuevaConexion = (conexion*)malloc(sizeof(conexion));
    nuevaConexion->conectado = conectado;
    nuevaConexion->siguiente = automata->conexiones;
    automata->conexiones = nuevaConexion;
}

void imprimirAutomataAsimetrico1(automataAsimetrico* automata) {
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            printf("[%s]", automata->automatas[i][j].color);
            conexion* actual = automata->automatas[i][j].conexiones;
            while (actual) {
                printf(" -> Conectado a [%s]", actual->conectado->color);
                actual = actual->siguiente;
            }
            printf("\t");
        }
        printf("\n");
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