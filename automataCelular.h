#ifndef AUTOMATA_CELULAR_H
#define AUTOMATA_CELULAR_H

// Definición de tipos (seir, celula, automataCelular)
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

typedef struct conexion {
    automataCelular* origen;
    int fila_origen;
    int columna_origen;
    automataCelular* destino;
    int fila_destino;
    int columna_destino;
} conexion;

typedef struct automataCelularAsimetrico {
    char nombre[50];
    automataCelular* automata;
    conexion** conexiones;
    int num_conexiones;
} automataCelularAsimetrico;

// Declaraciones de funciones
automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir* estados);
seir crearSeir(int s, int e, int i, int r);
void imprimirAutomata(automataCelular* automata);
void imprimirVecindad(int vecindad[8][2]);
void obtenerVecindadMoore(automataCelular* automata, int i, int j, int vecindad[8][2]);
void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna);


#endif // AUTOMATA_CELULAR_H