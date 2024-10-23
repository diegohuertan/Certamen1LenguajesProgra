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
%token<strval> CREARAUTOMATA DEFAULT S E I R COLOR VECINDAD SIMULAR ASIMETRICO ASIGNAR CONECTAR AISLAR IMPRIMIR
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
    
    free(listaseir); // Liberar la memoria después de usar listaseir
}

    |
    VECINDAD NUMERO NUMERO {
        int vecindad[8][2];
        obtenerVecindadMoore(automata, $2 ,$3, vecindad);
        imprimirVecindad(vecindad);
    }
    |
    SIMULAR NUMERO{
        for (int pasos=0; pasos <=$2; pasos++){
        for (int act = 0; act < listaAutomatasGlobal->cantidad; act++) {
            automataCelular* simetrico = listaAutomatasGlobal->automatas[act];
                for (int i = 0; i < simetrico->filas; i++) {
                    for (int j = 0; j < simetrico->columnas; j++) {
                        actualizar_celda_con_vecinos(simetrico, i, j);
                    }
                }
            }
            imprimirAutomataAsimetrico(automataAsimetricoGlobal);
                 printf("Simulacion numero: %d \n",pasos);

        }

    }
    |
    ASIMETRICO NUMERO NUMERO {
        automataAsimetricoGlobal = crearAutomataAsimetrico($2, $3);
    }
    |
    ASIGNAR NUMERO NUMERO NUMERO {
        if ($4 < listaAutomatasGlobal->cantidad) {
            automataCelular* simetrico = listaAutomatasGlobal->automatas[$4];
            asignarAutomataSimetrico(automataAsimetricoGlobal, $2, $3, simetrico);
        } else {
            fprintf(stderr, "Error: índice de autómata simétrico fuera de rango.\n");
        }
    }
    |
    AISLAR {
        eliminarConexiones(automataAsimetricoGlobal);
    }
    | 
    IMPRIMIR {
        imprimirAutomataAsimetrico(automataAsimetricoGlobal);
    } 
    ;
celulas:
    ESTADOSSEIR {
        $$ = $1;  // Asigna el valor del subarray a $$ para que esté disponible
        
    }
    | ENDLINE {
        $$ = NULL;  // También asigna NULL en este caso para el retorno
    }
    ;
conectar:
    CONECTAR NUMERO NUMERO NUMERO NUMERO {
        conectarAutomatas(&automataAsimetricoGlobal->automatas[$2][$3], &automataAsimetricoGlobal->automatas[$4][$5]);
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
    if (automata == NULL || automata->celulas == NULL) {
        fprintf(stderr, "Error: Automata o celulas no inicializadas.\n");
        return;
    }

    // Imprimir matriz y contenido del automata simetrico
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            printf(" (%2d,%2d,%2d,%2d) ", automata->celulas[i][j].estado.estados[0], automata->celulas[i][j].estado.estados[1], automata->celulas[i][j].estado.estados[2], automata->celulas[i][j].estado.estados[3]);
        }
        printf("\n");
    }
}

void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna) {
    if (automata == NULL || automata->celulas == NULL) {
        fprintf(stderr, "Error: Automata o celulas no inicializadas.\n");
        return;
    }

    if (fila < 0 || fila >= automata->filas || columna < 0 || columna >= automata->columnas) {
        fprintf(stderr, "Error: Indices fuera de los limites. fila: %d, columna: %d\n", fila, columna);
        return;
    }

    celula* celda = &automata->celulas[fila][columna];
    
    double Susceptible = celda->estado.estados[0];
    double Expuesto = celda->estado.estados[1];
    double Infectado = celda->estado.estados[2];
    double Recuperado = celda->estado.estados[3];
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

    // Acumular infectados de los autómatas vecinos conectados
    conexion* actual = automata->conexiones;
    
    while (actual != NULL) {
        automataCelular* automataVecino = actual->conectado;
        if (automataVecino && automataVecino->celulas) {
            I_vecinos += automataVecino->celulas[1][1].estado.estados[2]; // Ajusta el índice según sea necesario
            vecinos_contados++;
        }
        actual = actual->siguiente;
    }

    if (vecinos_contados > 0) {
        I_vecinos /= vecinos_contados;
    }

    // Inicializar el generador de números aleatorios
    srand(time(NULL));

    // Cálculo de las probabilidades de cambio de estado
    double prob_infeccion = PROB_INFECCION * I_vecinos;
    double prob_morbilidad = PROB_MORBILIDAD * Expuesto;
    double prob_recuperacion = PROB_RECUPERACION * Infectado;

    // Actualizar los valores de la celda basados en probabilidades
    if ((double)rand() / RAND_MAX < prob_infeccion && Susceptible > 0) {
        Susceptible -= 1;
        Expuesto += 1;
    }
    if ((double)rand() / RAND_MAX < prob_morbilidad && Expuesto > 0) {
        Expuesto -= 1;
        Infectado += 1;
    }
    if ((double)rand() / RAND_MAX < prob_recuperacion && Infectado > 0) {
        Infectado -= 1;
        Recuperado += 1;
    }

    // Asegurarse de que no haya valores negativos
    if (Susceptible < 0) Susceptible = 0;
    if (Expuesto < 0) Expuesto = 0;
    if (Infectado < 0) Infectado = 0;
    if (Recuperado < 0) Recuperado = 0;

    // Asegurarse de que la población total no exceda la población máxima
    double total_poblacion = Susceptible + Expuesto + Infectado + Recuperado;
    if (total_poblacion > poblacion_maxima) {
        double factor = poblacion_maxima / total_poblacion;
        Susceptible *= factor;
        Expuesto *= factor;
        Infectado *= factor;
        Recuperado *= factor;
    }

    // Actualizar los valores de la celda
    celda->estado.estados[0] = Susceptible;
    celda->estado.estados[1] = Expuesto;
    celda->estado.estados[2] = Infectado;
    celda->estado.estados[3] = Recuperado;
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
    printf("\n=== Autómata Asimétrico %dx%d ===\n\n", automata->filas, automata->columnas);
    
    // Para cada fila del autómata principal
    for (int i = 0; i < automata->filas; i++) {
        int maxSubFilas = 0;
        int* anchoSubmatrices = malloc(automata->columnas * sizeof(int));
        
        // Calcular el ancho estándar para todas las submatrices
        int anchoEstandar = 30; // Ancho mínimo para mantener consistencia
        
        // Calcular la altura máxima y anchos
        for (int j = 0; j < automata->columnas; j++) {
            automataCelular* subAutomata = &automata->automatas[i][j];
            if (subAutomata->celulas != NULL) {
                if (subAutomata->filas > maxSubFilas) {
                    maxSubFilas = subAutomata->filas;
                }
                // Calcular el ancho necesario para esta submatriz
                int anchoNecesario = subAutomata->columnas * 14;
                anchoSubmatrices[j] = anchoNecesario > anchoEstandar ? anchoNecesario : anchoEstandar;
            } else {
                anchoSubmatrices[j] = anchoEstandar;
            }
        }
        
        // Si no hay submatrices con contenido, asegurar altura mínima
        if (maxSubFilas == 0) maxSubFilas = 1;
        
        // Línea superior de la fila actual
        for (int j = 0; j < automata->columnas; j++) {
            printf("┌");
            for (int k = 0; k < anchoSubmatrices[j]; k++) printf("─");
            printf("┐ ");
        }
        printf("\n");
        
        // Imprimir el contenido de las submatrices
        for (int subFila = 0; subFila < maxSubFilas; subFila++) {
            for (int j = 0; j < automata->columnas; j++) {
                automataCelular* subAutomata = &automata->automatas[i][j];
                printf("│");
                
                if (subAutomata->celulas != NULL && subFila < subAutomata->filas) {
                    // Calcular espaciado inicial para centrar
                    int espacioInicial = (anchoSubmatrices[j] - (subAutomata->columnas * 14)) / 2;
                    for (int s = 0; s < espacioInicial; s++) printf(" ");
                    
                    // Imprimir los estados
                    for (int l = 0; l < subAutomata->columnas; l++) {
                        printf("(%2d,%2d,%2d,%2d) ", 
                            subAutomata->celulas[subFila][l].estado.estados[0],
                            subAutomata->celulas[subFila][l].estado.estados[1],
                            subAutomata->celulas[subFila][l].estado.estados[2],
                            subAutomata->celulas[subFila][l].estado.estados[3]);
                    }
                    
                    // Espaciado final para centrar
                    int espacioFinal = anchoSubmatrices[j] - espacioInicial - (subAutomata->columnas * 14);
                    for (int s = 0; s < espacioFinal; s++) printf(" ");
                } else {
                    // Centrar [vacío] en el espacio disponible
                    int espacios = (anchoSubmatrices[j] - 8) / 2;
                    for (int s = 0; s < espacios; s++) printf(" ");
                    printf("[vacío]");
                    for (int s = 0; s < anchoSubmatrices[j] - espacios - 8; s++) printf(" ");
                }
                printf("│ ");
            }
            printf("\n");
        }
        
        // Línea inferior de la fila actual
        for (int j = 0; j < automata->columnas; j++) {
            printf("└");
            for (int k = 0; k < anchoSubmatrices[j]; k++) printf("─");
            printf("┘ ");
        }
        printf("\n\n");
        
        free(anchoSubmatrices);
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

void eliminarConexiones(automataAsimetrico* automata) {
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            automataCelular* subAutomata = &automata->automatas[i][j];
            if (subAutomata->conexiones) {
                conexion* actual = subAutomata->conexiones;
                while (actual) {
                    conexion* siguiente = actual->siguiente;
                    free(actual);
                    actual = siguiente;
                }
                subAutomata->conexiones = NULL;
            }
        }
    }
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