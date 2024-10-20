#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Definición de constantes para los estados de las celdas
#define ESTADO_S 1 // Susceptible
#define ESTADO_E 2 // Expuesto
#define ESTADO_I 3 // Infectado
#define ESTADO_R 4 // Sanado
#define TAMAÑO_CELDA 5

#define TASA_RECLUTAMIENTO 0.1
#define TASA_INFECCION 0.4 // Reducir la tasa de infección
#define TASA_MORBILIDAD 0.3 // Reducir la tasa de morbilidad
#define TASA_RECUPERACION 0.3 // Aumentar la tasa de recuperación para que todos se recuperen en 10 días
#define TASA_PERDIDA_INMUNIDAD 0.3
#define TASA_MORTALIDAD_NO_ENFERMEDAD 0.1
#define TASA_MORTALIDAD_ENFERMEDAD 0.2

// Estructura para representar una celda del autómata (matriz de 5x5)
typedef struct {
    int **datos; // Matriz 5x5
    char grupo[20]; // Nombre del grupo
} Celda;

// Estructura para representar el autómata celular
typedef struct {
    int filas;
    int columnas;
    Celda **celdas; // Matriz dinámica de celdas
} Automata;

// Función para inicializar la matriz de datos de la celda
int **inicializarDatos() {
    int **datos = (int **)malloc(TAMAÑO_CELDA * sizeof(int *));
    if (!datos) {
        fprintf(stderr, "Error al asignar memoria para datos de la celda.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < TAMAÑO_CELDA; i++) {
        datos[i] = (int *)malloc(TAMAÑO_CELDA * sizeof(int));
        if (!datos[i]) {
            fprintf(stderr, "Error al asignar memoria para datos de la celda.\n");
            exit(EXIT_FAILURE);
        }
        // Inicializar la celda con 0
        memset(datos[i], 0, TAMAÑO_CELDA * sizeof(int)); // Inicializar con 0
    }
    return datos;
}

// Función para crear una celda de 5x5
Celda crearCelda() {
    Celda celda;
    celda.datos = inicializarDatos();
    strcpy(celda.grupo, ""); // Inicializar el grupo como una cadena vacía
    return celda;
}

// Función para crear un autómata de tamaño dinámico
Automata crearAutomata(int columnas, int filas) {
    Automata automata;
    automata.filas = filas;
    automata.columnas = columnas;

    // Asignar memoria para la matriz de celdas
    automata.celdas = (Celda **)malloc(filas * sizeof(Celda *));
    if (!automata.celdas) {
        fprintf(stderr, "Error al asignar memoria para el autómata.\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < filas; i++) {
        automata.celdas[i] = (Celda *)malloc(columnas * sizeof(Celda));
        if (!automata.celdas[i]) {
            fprintf(stderr, "Error al asignar memoria para las celdas del autómata.\n");
            exit(EXIT_FAILURE);
        }
        for (int j = 0; j < columnas; j++) {
            automata.celdas[i][j] = crearCelda(); // Crear y asignar una nueva celda
        }
    }

    return automata;
}

// Función para crear una submatriz de "S" en un rango de celdas y asignar un grupo
void crearSubmatriz(Automata *automata, int filaInicio, int columnaInicio, int columnas, int filas, const char *grupo) {
    // Validar límites de la matriz
    if (filaInicio < 0 || filaInicio + filas > automata->filas || columnaInicio < 0 || columnaInicio + columnas > automata->columnas) {
        printf("Error: rango de celdas fuera de límites.\n");
        return;
    }

    // Insertar "S" en la submatriz del rango de celdas y asignar el grupo
    for (int i = filaInicio; i < filaInicio + filas; i++) {
        for (int j = columnaInicio; j < columnaInicio + columnas; j++) {
            Celda *celda = &automata->celdas[i][j];
            for (int x = 0; x < TAMAÑO_CELDA; x++) {
                for (int y = 0; y < TAMAÑO_CELDA; y++) {
                    celda->datos[x][y] = ESTADO_S; // Asignar "S" (1 representa susceptible)
                }
            }
            strcpy(celda->grupo, grupo); // Asignar el nombre del grupo a la celda
        }
    }
}

// Función para asignar un número específico de infectados aleatoriamente en un grupo
void asignarInfectadosAleatorios(Automata *automata, const char *grupo, int numeroInfectados) {
    srand(time(NULL)); // Semilla para la generación de números aleatorios
    int infectadosAsignados = 0;

    // Iterar sobre las celdas para encontrar el grupo especificado
    for (int i = 0; i < automata->filas && infectadosAsignados < numeroInfectados; i++) {
        for (int j = 0; j < automata->columnas && infectadosAsignados < numeroInfectados; j++) {
            Celda *celda = &automata->celdas[i][j];

            if (strcmp(celda->grupo, grupo) == 0) { // Verificar si es el grupo deseado
                // Asignar aleatoriamente el estado "Infectado" (I) a algunas celdas
                for (int x = 0; x < TAMAÑO_CELDA && infectadosAsignados < numeroInfectados; x++) {
                    for (int y = 0; y < TAMAÑO_CELDA && infectadosAsignados < numeroInfectados; y++) {
                        if (celda->datos[x][y] == ESTADO_S && (rand() % (TAMAÑO_CELDA * TAMAÑO_CELDA)) < 1) {
                            celda->datos[x][y] = ESTADO_I; // Asignar "I" (Infectado)
                            infectadosAsignados++;
                        }
                    }
                }
            }
        }
    }
}

// Función para simular el modelo SEIR
void simularPaso(Automata *automata) {
    Automata automataTemp = crearAutomata(automata->columnas, automata->filas);

    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            Celda *celda = &automata->celdas[i][j];

            for (int x = 0; x < TAMAÑO_CELDA; x++) {
                for (int y = 0; y < TAMAÑO_CELDA; y++) {
                    int estadoActual = celda->datos[x][y];
                    int nuevoEstado = estadoActual;

                    if (estadoActual == ESTADO_S) {
                        int infectadoCerca = 0;
                        for (int dx = -1; dx <= 1 && !infectadoCerca; dx++) {
                            for (int dy = -1; dy <= 1 && !infectadoCerca; dy++) {
                                int vecinoFila = i + dx;
                                int vecinoColumna = j + dy;
                                if (dx == 0 && dy == 0) continue;

                                if (vecinoFila >= 0 && vecinoFila < automata->filas &&
                                    vecinoColumna >= 0 && vecinoColumna < automata->columnas) {
                                    Celda *celdaVecina = &automata->celdas[vecinoFila][vecinoColumna];
                                    for (int vx = 0; vx < TAMAÑO_CELDA && !infectadoCerca; vx++) {
                                        for (int vy = 0; vy < TAMAÑO_CELDA && !infectadoCerca; vy++) {
                                            if (celdaVecina->datos[vx][vy] == ESTADO_I) {
                                                infectadoCerca = 1;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if (infectadoCerca && rand() % 100 < TASA_INFECCION * 100) {
                            nuevoEstado = ESTADO_E;
                        }
                    } else if (estadoActual == ESTADO_E) {
                        if (rand() % 100 < TASA_MORBILIDAD * 100) {
                            nuevoEstado = ESTADO_I;
                        }
                    } else if (estadoActual == ESTADO_I) {
                        if (rand() % 100 < TASA_RECUPERACION * 100) {
                            nuevoEstado = ESTADO_R;
                        }
                    } else if (estadoActual == ESTADO_R) {
                        if (rand() % 100 < TASA_PERDIDA_INMUNIDAD * 100) {
                            nuevoEstado = ESTADO_S;
                        }
                    }

                    automataTemp.celdas[i][j].datos[x][y] = nuevoEstado;
                }
            }
        }
    }

    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            for (int x = 0; x < TAMAÑO_CELDA; x++) {
                for (int y = 0; y < TAMAÑO_CELDA; y++) {
                    automata->celdas[i][j].datos[x][y] = automataTemp.celdas[i][j].datos[x][y];
                }
            }
        }
    }

    for (int i = 0; i < automataTemp.filas; i++) {
        for (int j = 0; j < automataTemp.columnas; j++) {
            for (int x = 0; x < TAMAÑO_CELDA; x++) {
                free(automataTemp.celdas[i][j].datos[x]);
            }
            free(automataTemp.celdas[i][j].datos);
        }
        free(automataTemp.celdas[i]);
    }
    free(automataTemp.celdas);
}

// Estructura para almacenar los conteos de estados por grupo
typedef struct {
    char grupo[20];
    int S;
    int E;
    int I;
    int R;
} ConteoGrupo;

// Función para contar los estados por grupo
void contarEstadosPorGrupo(Automata automata, ConteoGrupo *conteos, int *numGrupos) {
    *numGrupos = 0;
    for (int i = 0; i < automata.filas; i++) {
        for (int j = 0; j < automata.columnas; j++) {
            Celda *celda = &automata.celdas[i][j];
            int encontrado = 0;
            for (int k = 0; k < *numGrupos; k++) {
                if (strcmp(conteos[k].grupo, celda->grupo) == 0) {
                    encontrado = 1;
                    for (int x = 0; x < TAMAÑO_CELDA; x++) {
                        for (int y = 0; y < TAMAÑO_CELDA; y++) {
                            switch (celda->datos[x][y]) {
                                case ESTADO_S: conteos[k].S++; break;
                                case ESTADO_E: conteos[k].E++; break;
                                case ESTADO_I: conteos[k].I++; break;
                                case ESTADO_R: conteos[k].R++; break;
                            }
                        }
                    }
                    break;
                }
            }
            if (!encontrado) {
                strcpy(conteos[*numGrupos].grupo, celda->grupo);
                conteos[*numGrupos].S = conteos[*numGrupos].E = conteos[*numGrupos].I = conteos[*numGrupos].R = 0;
                for (int x = 0; x < TAMAÑO_CELDA; x++) {
                    for (int y = 0; y < TAMAÑO_CELDA; y++) {
                        switch (celda->datos[x][y]) {
                            case ESTADO_S: conteos[*numGrupos].S++; break;
                            case ESTADO_E: conteos[*numGrupos].E++; break;
                            case ESTADO_I: conteos[*numGrupos].I++; break;
                            case ESTADO_R: conteos[*numGrupos].R++; break;
                        }
                    }
                }
                (*numGrupos)++;
            }
        }
    }
}

// Función para imprimir el estado de una celda
void imprimirEstadoCelda(int estado) {
    switch (estado) {
        case ESTADO_S: printf("S "); break;
        case ESTADO_E: printf("E "); break;
        case ESTADO_I: printf("I "); break;
        case ESTADO_R: printf("R "); break;
        default: printf("0 "); break;
    }
}

// Función para imprimir el autómata y los conteos de estados por grupo
void imprimirAutomata(Automata automata) {
    for (int i = 0; i < automata.filas; i++) {
        for (int x = 0; x < TAMAÑO_CELDA; x++) {
            for (int j = 0; j < automata.columnas; j++) {
                Celda *celda = &automata.celdas[i][j];
                for (int y = 0; y < TAMAÑO_CELDA; y++) {
                    imprimirEstadoCelda(celda->datos[x][y]); // Imprimir el estado de la celda
                }
                printf("   "); // Espacio entre celdas
            }
            printf("\n"); // Línea en blanco entre filas de celdas
        }
        printf("\n"); // Línea en blanco entre grupos de celdas
    }

    // Contar y imprimir los estados por grupo
    ConteoGrupo conteos[100];
    int numGrupos;
    contarEstadosPorGrupo(automata, conteos, &numGrupos);
    printf("Conteo de estados por grupo:\n");
    for (int i = 0; i < numGrupos; i++) {
        printf("Grupo %s: S=%d, E=%d, I=%d, R=%d\n", conteos[i].grupo, conteos[i].S, conteos[i].E, conteos[i].I, conteos[i].R);
    }
}

// Función principal
int main() {
    Automata automata = crearAutomata(7, 6); // Crear un autómata de 7x6

    // Crear una submatriz de "S" y asignar un grupo
    crearSubmatriz(&automata, 0, 1, 2, 2, "amarillo");
    crearSubmatriz(&automata, 1, 0, 1, 2, "salmon");
    crearSubmatriz(&automata, 3, 0, 2, 3, "azul");
    crearSubmatriz(&automata, 2, 2, 2, 2, "verde");
    crearSubmatriz(&automata, 4, 3, 1, 2, "rojo");
    crearSubmatriz(&automata, 1, 4, 1, 1, "morado");
    crearSubmatriz(&automata, 1, 5, 2, 4, "gris");
    crearSubmatriz(&automata, 5 ,4, 2, 1, "celeste");

    // Asignar infectados aleatorios
    asignarInfectadosAleatorios(&automata, "azul", 3);

    printf("Estado inicial del autómata:\n");
    imprimirAutomata(automata);

    // Simular 10 pasos del modelo SEIR
    for (int paso = 0; paso < 10; paso++) {
        printf("\nEstado después del paso %d:\n", paso + 1);
        simularPaso(&automata);
        imprimirAutomata(automata);
    }

    // Liberar memoria
    for (int i = 0; i < automata.filas; i++) {
        for (int j = 0; j < automata.columnas; j++) {
            for (int x = 0; x < TAMAÑO_CELDA; x++) {
                free(automata.celdas[i][j].datos[x]);
            }free(automata.celdas[i][j].datos);
        }
        free(automata.celdas[i]);
    }
    free(automata.celdas);

    return 0;
}
