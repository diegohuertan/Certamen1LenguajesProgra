%{
#include "automataCelular.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <limits.h>
#include <stdbool.h>
extern FILE *yyin;

// Definiciones de constantes
const int POBLACION_MAXIMA = 100;

// Declaraciones de funciones
int yylex();
void yyerror(const char*);
automataCelular* automata;
seir* convertirSubarraysASeir(int** subarrays, int length);
listaAutomatas* listaAutomatasGlobal;
automataAsimetrico* automataAsimetricoGlobal;
%}

%union {
    int ival;
    double fval;
    char* strval;
    int** subarraylist; 
}

/* Definiciones de tokens */
%type <subarraylist> celulas
%token<strval> CREARAUTOMATA DEFAULT S E I R COLOR VECINDAD SIMULAR ASIMETRICO ASIGNAR CONECTAR AISLAR IMPRIMIR CONEXIONES
%token<ival> NUMERO
%token<fval> FLOAT
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
    
    free(listaseir); 
}

    |
    VECINDAD NUMERO NUMERO {
        int vecindad[8][2];
        obtenerVecindadMoore(automata, $2 ,$3, vecindad);
        imprimirVecindad(vecindad);
    }
    |
SIMULAR NUMERO FLOAT FLOAT FLOAT {
    for (int pasos = 0; pasos <= $2; pasos++) {
        for (int act = 0; act < listaAutomatasGlobal->cantidad; act++) {
            automataCelular* simetrico = listaAutomatasGlobal->automatas[act];
            
            celula** temp_celulas = malloc(simetrico->filas * sizeof(celula*));
            for (int i = 0; i < simetrico->filas; i++) {
                temp_celulas[i] = malloc(simetrico->columnas * sizeof(celula));
                for (int j = 0; j < simetrico->columnas; j++) {
                    temp_celulas[i][j] = simetrico->celulas[i][j];
                }
            }
            
            for (int i = 0; i < simetrico->filas; i++) {
                for (int j = 0; j < simetrico->columnas; j++) {
                    celula** celulas_original = simetrico->celulas;
                    simetrico->celulas = temp_celulas;
                    actualizar_celda_con_vecinos(simetrico, i, j, pasos, $3, $4, $5);
                    simetrico->celulas = celulas_original;
                }
            }
            
            for (int i = 0; i < simetrico->filas; i++) {
                for (int j = 0; j < simetrico->columnas; j++) {
                    simetrico->celulas[i][j] = temp_celulas[i][j];
                }
            }
            
            for (int i = 0; i < simetrico->filas; i++) {
                free(temp_celulas[i]);
            }
            free(temp_celulas);
        }
        
        imprimirAutomataAsimetrico(automataAsimetricoGlobal);

        printf("Simulacion numero: %d \n", pasos);
    }
}
    |
    ASIMETRICO NUMERO NUMERO {
        automataAsimetricoGlobal = crearAutomataAsimetrico($2, $3);
    }
    |
    ASIGNAR NUMERO NUMERO NUMERO {
        if ($4 < 8) {
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
        $$ = $1;  
        
    }
    | ENDLINE {
        $$ = NULL;  
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
    int dx[] = {-1, -1, -1, 0, 0, 1, 1, 1};
    int dy[] = {-1, 0, 1, -1, 1, -1, 0, 1};
    int k = 0;

    for (int d = 0; d < 8; d++) {
        int ni = i + dx[d]; 
        int nj = j + dy[d]; 

        if (ni >= 0 && ni < automata->filas && nj >= 0 && nj < automata->columnas) {
            vecindad[k][0] = ni;
            vecindad[k][1] = nj;
        } else {
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

    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            printf(" (%2d,%2d,%2d,%2d) ", automata->celulas[i][j].estado.estados[0], automata->celulas[i][j].estado.estados[1], automata->celulas[i][j].estado.estados[2], automata->celulas[i][j].estado.estados[3]);
        }
        printf("\n");
    }
}

void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna, int pasos, double prob_infeccion, double prob_morbilidad, double prob_recuperacion) {
    if (automata == NULL || automata->celulas == NULL) {
        fprintf(stderr, "Error: Automata o celulas no inicializadas.\n");
        return;
    }

    if (fila < 0 || fila >= automata->filas || columna < 0 || columna >= automata->columnas) {
        return;
    }

    celula* celda = &automata->celulas[fila][columna];
    
    double Susceptible = celda->estado.estados[0];
    double Expuesto = celda->estado.estados[1];
    double Infectado = celda->estado.estados[2];
    double Recuperado = celda->estado.estados[3];
    double poblacion_maxima = POBLACION_MAXIMA;

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

    conexion* actual = automataAsimetricoGlobal->conexiones;

    while (actual != NULL) {
        automataCelular* automataVecino = actual->conectado;
        if (automataVecino && automataVecino->celulas) {
            I_vecinos += automataVecino->celulas[0][0].estado.estados[2]; 
            vecinos_contados++;
        }
        actual = actual->siguiente;
    }

    double infeccionVecinos = 0;

    if (vecinos_contados > 0) {
        infeccionVecinos =(I_vecinos / vecinos_contados)/100;
    }

    double umbral_infeccion = prob_infeccion;  
    double umbral_morbilidad = prob_morbilidad; 
    double umbral_recuperacion = prob_recuperacion;
    
    double nuevo_Susceptible = Susceptible;
    double nuevo_Expuesto = Expuesto;
    double nuevo_Infectado = Infectado;
    double nuevo_Recuperado = Recuperado;
    

    if ((double)rand() / RAND_MAX < umbral_infeccion + infeccionVecinos && Susceptible > 0) {
        nuevo_Susceptible -= 1;
        nuevo_Expuesto += 1;
    }

    if ((double)rand() / RAND_MAX < umbral_morbilidad && Expuesto > 0) {
        nuevo_Expuesto -= 1;
        nuevo_Infectado += 1;
    }

    if ((double)rand() / RAND_MAX < umbral_recuperacion && Infectado > 0) {
        nuevo_Infectado -= 1;
        nuevo_Recuperado += 1;
    }
    
    

    nuevo_Susceptible = (nuevo_Susceptible < 0) ? 0 : nuevo_Susceptible;
    nuevo_Expuesto = (nuevo_Expuesto < 0) ? 0 : nuevo_Expuesto;
    nuevo_Infectado = (nuevo_Infectado < 0) ? 0 : nuevo_Infectado;
    nuevo_Recuperado = (nuevo_Recuperado < 0) ? 0 : nuevo_Recuperado;
    
    double total_poblacion = nuevo_Susceptible + nuevo_Expuesto + nuevo_Infectado + nuevo_Recuperado;
    if (total_poblacion > poblacion_maxima) {
        double factor = poblacion_maxima / total_poblacion;
        nuevo_Susceptible *= factor;
        nuevo_Expuesto *= factor;
        nuevo_Infectado *= factor;
        nuevo_Recuperado *= factor;
    }
    
    celda->estado.estados[0] = nuevo_Susceptible;
    celda->estado.estados[1] = nuevo_Expuesto;
    celda->estado.estados[2] = nuevo_Infectado;
    celda->estado.estados[3] = nuevo_Recuperado;

    exportarDatosSimulacionCSV("datos_simulacion.csv", pasos);
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
    
    for (int i = 0; i < automata->filas; i++) {
        int maxSubFilas = 0;
        int* anchoSubmatrices = malloc(automata->columnas * sizeof(int));
        
        int anchoEstandar = 30; 
        
        for (int j = 0; j < automata->columnas; j++) {
            automataCelular* subAutomata = &automata->automatas[i][j];
            if (subAutomata->celulas != NULL) {
                if (subAutomata->filas > maxSubFilas) {
                    maxSubFilas = subAutomata->filas;
                }
                int anchoNecesario = subAutomata->columnas * 14;
                anchoSubmatrices[j] = anchoNecesario > anchoEstandar ? anchoNecesario : anchoEstandar;
            } else {
                anchoSubmatrices[j] = anchoEstandar;
            }
        }
        
        if (maxSubFilas == 0) maxSubFilas = 1;
        
        for (int j = 0; j < automata->columnas; j++) {
            printf("┌");
            for (int k = 0; k < anchoSubmatrices[j]; k++) printf("─");
            printf("┐ ");
        }
        printf("\n");
        
        for (int subFila = 0; subFila < maxSubFilas; subFila++) {
            for (int j = 0; j < automata->columnas; j++) {
                automataCelular* subAutomata = &automata->automatas[i][j];
                printf("│");
                
                if (subAutomata->celulas != NULL && subFila < subAutomata->filas) {
                    int espacioInicial = (anchoSubmatrices[j] - (subAutomata->columnas * 14)) / 2;
                    for (int s = 0; s < espacioInicial; s++) printf(" ");
                    
                    for (int l = 0; l < subAutomata->columnas; l++) {
                        printf("(%2d,%2d,%2d,%2d) ", 
                            subAutomata->celulas[subFila][l].estado.estados[0],
                            subAutomata->celulas[subFila][l].estado.estados[1],
                            subAutomata->celulas[subFila][l].estado.estados[2],
                            subAutomata->celulas[subFila][l].estado.estados[3]);
                    }
                    
                    int espacioFinal = anchoSubmatrices[j] - espacioInicial - (subAutomata->columnas * 14);
                    for (int s = 0; s < espacioFinal; s++) printf(" ");
                } else {
                    int espacios = (anchoSubmatrices[j] - 8) / 2;
                    for (int s = 0; s < espacios; s++) printf(" ");
                    printf("[vacío]");
                    for (int s = 0; s < anchoSubmatrices[j] - espacios - 8; s++) printf(" ");
                }
                printf("│ ");
            }
            printf("\n");
        }
        
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
        agregarConexion(automata2, automata1); 
    }
}


void agregarConexion(automataCelular* automata, automataCelular* conectado) {
    if (automata == NULL || conectado == NULL) {
        fprintf(stderr, "Error: automata o conectado es NULL.\n");
        return;
    }

    conexion* nuevaConexion = (conexion*)malloc(sizeof(conexion));
    if (nuevaConexion == NULL) {
        fprintf(stderr, "Error: no se pudo asignar memoria para nuevaConexion.\n");
        return;
    }

    nuevaConexion->conectado = conectado;
    nuevaConexion->siguiente = automataAsimetricoGlobal->conexiones;
    automataAsimetricoGlobal->conexiones = nuevaConexion;
}

void eliminarConexiones() {
automataAsimetricoGlobal->conexiones = NULL;
}
void exportarDatosSimulacionCSV(const char* nombreArchivo, int tiempo) {
    FILE* archivo = fopen(nombreArchivo, "a"); 
    if (!archivo) {
        fprintf(stderr, "Error al abrir el archivo para escribir.\n");
        return;
    }

    fseek(archivo, 0, SEEK_END);
    if (ftell(archivo) == 0) {
        fprintf(archivo, "Automata,Fila,Columna,Susceptible,Expuesto,Infectado,Recuperado,Tiempo\n");
    }

    for (int a = 0; a < listaAutomatasGlobal->cantidad; a++) {
        automataCelular* automata = listaAutomatasGlobal->automatas[a];

        for (int i = 0; i < automata->filas; i++) {
            for (int j = 0; j < automata->columnas; j++) {
                seir estado = automata->celulas[i][j].estado;
                
                fprintf(archivo, "%d,%d,%d,%d,%d,%d,%d,%d\n", 
                        a, i, j, 
                        estado.estados[0], estado.estados[1], estado.estados[2], estado.estados[3],
                        tiempo);
            }
        }
    }

    fclose(archivo);
    printf("Datos de la simulación exportados exitosamente a %s.\n", nombreArchivo);
}

void yyerror(const char* msg) {
    printf("error: %s\n", msg);
}

int main(int argc, char **argv) {
    yyin = fopen("automata.txt", "r");
    if (yyin) {
        yyparse();
        fclose(yyin);  
    }

    yyin = stdin;
    yyparse();

    return 0;
}