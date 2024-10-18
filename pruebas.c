#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdbool.h>

typedef struct {
    double S;
    double E;
    double I;
    double R;
} seir;

typedef struct {
    seir estado;
} celula;

typedef struct {
    char color[50];
    celula **celulas;
    int filas;
    int columnas;
} automataCelular;

#define FILAS 5
#define COLUMNAS 5

void inicializar_automata(automataCelular *automata, int filas, int columnas, const char *color) {
    automata->filas = filas;
    automata->columnas = columnas;
    strcpy(automata->color, color);

    automata->celulas = (celula **)malloc(filas * sizeof(celula *));
    for (int i = 0; i < filas; i++) {
        automata->celulas[i] = (celula *)malloc(columnas * sizeof(celula));
        for (int j = 0; j < columnas; j++) {
            automata->celulas[i][j].estado.S = 100.0;
            automata->celulas[i][j].estado.E = 0.0;
            automata->celulas[i][j].estado.I = 0.0;
            automata->celulas[i][j].estado.R = 0.0;
        }
    }
}

void liberar_automata(automataCelular *automata) {
    for (int i = 0; i < automata->filas; i++) {
        free(automata->celulas[i]);
    }
    free(automata->celulas);
}

void distribuir_infectados_aleatorio(automataCelular *automata, int num_infectados) {
    int infectados_colocados = 0;

    while (infectados_colocados < num_infectados) {
        int fila = rand() % automata->filas;
        int columna = rand() % automata->columnas;

        if (automata->celulas[fila][columna].estado.I == 0 && automata->celulas[fila][columna].estado.S >= 5.0) {
            automata->celulas[fila][columna].estado.S -= 5.0;
            automata->celulas[fila][columna].estado.I = 5.0;
            infectados_colocados++;
        }
    }
}

void actualizar_celda_con_vecinos(automataCelular *automata, int fila, int columna, double beta, double sigma, double gamma, double dt) {
    celula *celda = &automata->celulas[fila][columna];
    double S = celda->estado.S;
    double E = celda->estado.E;
    double I = celda->estado.I;
    double R = celda->estado.R;

    double I_vecinos = 0;
    int vecinos_contados = 0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;

            int fila_vecino = fila + i;
            int columna_vecino = columna + j;

            if (fila_vecino >= 0 && fila_vecino < automata->filas && columna_vecino >= 0 && columna_vecino < automata->columnas) {
                I_vecinos += automata->celulas[fila_vecino][columna_vecino].estado.I;
                vecinos_contados++;
            }
        }
    }

    if (vecinos_contados > 0) {
        I_vecinos /= vecinos_contados;
    }

    double dS = -beta * S * I_vecinos * dt;
    double dE = (beta * S * I_vecinos - sigma * E) * dt;
    double dI = (sigma * E - gamma * I) * dt;
    double dR = gamma * I * dt;

    celda->estado.S += dS;
    celda->estado.E += dE;
    celda->estado.I += dI;
    celda->estado.R += dR;

    if (celda->estado.S < 0) celda->estado.S = 0;
    if (celda->estado.E < 0) celda->estado.E = 0;
    if (celda->estado.I < 0) celda->estado.I = 0;
    if (celda->estado.R < 0) celda->estado.R = 0;

    if (E > 0) {
        celda->estado.I += (sigma * E * dt);
        celda->estado.E -= (sigma * E * dt);
    }

    if (I > 0) {
        celda->estado.R += (gamma * I * dt);
        celda->estado.I -= (gamma * I * dt);
    }
}

void actualizar_conexion_matrices(automataCelular *automata1, automataCelular *automata2, double beta, double sigma, double gamma, double dt) {
    int hay_infectados = 0;

    // Verificar si hay infectados en la última fila de automata1
    for (int j = 0; j < automata1->columnas; j++) {
        if (automata1->celulas[automata1->filas - 1][j].estado.I > 0) {
            hay_infectados = 1;
            break;
        }
    }

    // Si hay infectados en la última fila de automata1, actualizar la primera fila de automata2
    if (hay_infectados) {
        for (int j = 0; j < automata2->columnas; j++) {
            double I_vecinos = automata1->celulas[automata1->filas - 1][j].estado.I;
            double S = automata2->celulas[0][j].estado.S;
            double E = automata2->celulas[0][j].estado.E;
            double I = automata2->celulas[0][j].estado.I;
            double R = automata2->celulas[0][j].estado.R;

            double dS = -beta * S * I_vecinos * dt;
            double dE = (beta * S * I_vecinos - sigma * E) * dt;
            double dI = (sigma * E - gamma * I) * dt;
            double dR = gamma * I * dt;

            automata2->celulas[0][j].estado.S += dS;
            automata2->celulas[0][j].estado.E += dE;
            automata2->celulas[0][j].estado.I += dI;
            automata2->celulas[0][j].estado.R += dR;

            if (automata2->celulas[0][j].estado.S < 0) automata2->celulas[0][j].estado.S = 0;
            if (automata2->celulas[0][j].estado.E < 0) automata2->celulas[0][j].estado.E = 0;
            if (automata2->celulas[0][j].estado.I < 0) automata2->celulas[0][j].estado.I = 0;
            if (automata2->celulas[0][j].estado.R < 0) automata2->celulas[0][j].estado.R = 0;
        }
    }
}

void imprimir_matriz_estados(automataCelular *automata) {
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            char estado = 'S';

            if (automata->celulas[i][j].estado.E > 0) {
                estado = 'E';
            }
            if (automata->celulas[i][j].estado.I > 0) {
                estado = 'I';
            }
            if (automata->celulas[i][j].estado.R > 0) {
                estado = 'R';
            }

            printf("%c ", estado);
        }
        printf("\n");
    }
    printf("\n");
}

void imprimir_matrices_juntas(automataCelular *automata1, automataCelular *automata2) {
    for (int i = 0; i < automata1->filas; i++) {
        for (int j = 0; j < automata1->columnas; j++) {
            char estado = 'S';

            if (automata1->celulas[i][j].estado.E > 0) {
                estado = 'E';
            }
            if (automata1->celulas[i][j].estado.I > 0) {
                estado = 'I';
            }
            if (automata1->celulas[i][j].estado.R > 0) {
                estado = 'R';
            }

            printf("%c ", estado);
        }
        printf("   ");
        for (int j = 0; j < automata2->columnas; j++) {
            char estado = 'S';

            if (automata2->celulas[i][j].estado.E > 0) {
                estado = 'E';
            }
            if (automata2->celulas[i][j].estado.I > 0) {
                estado = 'I';
            }
            if (automata2->celulas[i][j].estado.R > 0) {
                estado = 'R';
            }

            printf("%c ", estado);
        }
        printf("\n");
    }
    printf("\n");
}

void inicializar_simulacion(automataCelular *automata1, automataCelular *automata2) {
    inicializar_automata(automata1, FILAS, COLUMNAS, "Rojo");
    inicializar_automata(automata2, FILAS, COLUMNAS, "Verde");

    distribuir_infectados_aleatorio(automata1, 2);
    distribuir_infectados_aleatorio(automata2, 0);
}

void simular_dia(automataCelular *automata1, automataCelular *automata2, double beta, double sigma, double gamma, double dt) {
    for (int i = 0; i < automata1->filas; i++) {
        for (int j = 0; j < automata1->columnas; j++) {
            actualizar_celda_con_vecinos(automata1, i, j, beta, sigma, gamma, dt);
            actualizar_celda_con_vecinos(automata2, i, j, beta, sigma, gamma, dt);
        }
    }

    // Actualizar conexión entre matrices
    actualizar_conexion_matrices(automata1, automata2, beta, sigma, gamma, dt);
}

void imprimir_estado_dia(automataCelular *automata1, automataCelular *automata2, int dia, bool imprimir_juntas) {
    printf("Día %d:\n", dia);
    if (imprimir_juntas) {
        // Imprimir ambas matrices juntas
        imprimir_matrices_juntas(automata1, automata2);
    } else {
        // Imprimir matrices por separado
        printf("Automata 1:\n");
        imprimir_matriz_estados(automata1);
        printf("Automata 2:\n");
        imprimir_matriz_estados(automata2);
    }
}

int main() {
    srand(time(NULL));

    double beta = 0.5;
    double sigma = 1.0 / 2.0;
    double gamma = 1.0 / 15.0;
    double dt = 1.0;

    automataCelular automata1;
    automataCelular automata2;

    inicializar_simulacion(&automata1, &automata2);

    imprimir_estado_dia(&automata1, &automata2, 1, true);

    for (int t = 1; t < 10; t++) {
        simular_dia(&automata1, &automata2, beta, sigma, gamma, dt);
        imprimir_estado_dia(&automata1, &automata2, t + 1, false);
    }

    liberar_automata(&automata1);
    liberar_automata(&automata2);

    return 0;
}