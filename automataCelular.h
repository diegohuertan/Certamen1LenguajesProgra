#ifndef AUTOMATA_CELULAR_H
#define AUTOMATA_CELULAR_H

#define TAMAÑO_CELDA 10
#define ESTADO_S 1

// Definición de tipos (seir, celula, automataCelular)
typedef struct seir {
    int estados[4];
} seir;

typedef struct celula {
    seir estado;
} celula;

typedef struct conexion {
    struct automataCelular* conectado;
    struct conexion* siguiente;
} conexion;

typedef struct automataCelular {
    char color[50];
    celula **celulas;
    int filas;
    int columnas;
} automataCelular;

typedef struct automataAsimetrico {
    int filas;
    int columnas;
    automataCelular** automatas;
    conexion* conexiones; // Lista de conexiones
} automataAsimetrico;

typedef struct listaAutomatas {
    automataCelular** automatas;
    int cantidad;
    int capacidad;
} listaAutomatas;

// Declaraciones de funciones
automataCelular* crearAutomataSimetrico(char* color, int filas, int columnas, seir* estados);
automataAsimetrico* crearAutomataAsimetrico(int filas, int columnas);
void asignarAutomataSimetrico(automataAsimetrico* automata, int fila, int columna, automataCelular* simetrico);
celula* crearCelula(seir* estado);
seir crearSeir(int s, int e, int i, int r);
void imprimirAutomata(automataCelular* automata);
void imprimirAutomataAsimetrico(automataAsimetrico* automata);
void imprimirVecindad(int vecindad[8][2]);
void obtenerVecindadMoore(automataCelular* automata, int i, int j, int vecindad[8][2]);
void actualizar_celda_con_vecinos(automataCelular* automata, int fila, int columna);
listaAutomatas* crearListaAutomatas(int capacidadInicial);
void agregarAutomata(listaAutomatas* lista, automataCelular* automata);
void conectarAutomatas(automataCelular* automata1, automataCelular* automata2);
void agregarConexion(automataCelular* automata, automataCelular* conectado);
void desconectarAutomata(automataCelular* automata1, automataCelular* automata2);
void eliminarConexiones(automataCelular* automata, automataCelular* conectado);

#endif // AUTOMATA_CELULAR_H