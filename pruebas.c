#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct {
    double S;
    double E;
    double I;
    double R;
} Celda;

#define FILAS 5
#define COLUMNAS 5

void distribuir_infectados_aleatorio(Celda matriz[FILAS][COLUMNAS], int num_infectados) {
    int infectados_colocados = 0;

    while (infectados_colocados < num_infectados) {
        int fila = rand() % FILAS;
        int columna = rand() % COLUMNAS;

        if (matriz[fila][columna].I == 0 && matriz[fila][columna].S >= 5.0) {
            matriz[fila][columna].S -= 5.0;
            matriz[fila][columna].I = 5.0;
            infectados_colocados++;
        }
    }
}

void actualizar_celda_con_vecinos(Celda matriz[FILAS][COLUMNAS], int fila, int columna, double beta, double sigma, double gamma, double dt) {
    Celda *celda = &matriz[fila][columna];
    double S = celda->S;
    double E = celda->E;
    double I = celda->I;
    double R = celda->R;

    double I_vecinos = 0;
    int vecinos_contados = 0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;

            int fila_vecino = fila + i;
            int columna_vecino = columna + j;

            if (fila_vecino >= 0 && fila_vecino < FILAS && columna_vecino >= 0 && columna_vecino < COLUMNAS) {
                I_vecinos += matriz[fila_vecino][columna_vecino].I;
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

    celda->S += dS;
    celda->E += dE;
    celda->I += dI;
    celda->R += dR;

    if (celda->S < 0) celda->S = 0;
    if (celda->E < 0) celda->E = 0;
    if (celda->I < 0) celda->I = 0;
    if (celda->R < 0) celda->R = 0;

    if (E > 0) {
        celda->I += (sigma * E * dt);
        celda->E -= (sigma * E * dt);
    }

    if (I > 0) {
        celda->R += (gamma * I * dt);
        celda->I -= (gamma * I * dt);
    }
}

void imprimir_matriz_estados(Celda matriz[FILAS][COLUMNAS]) {
    for (int i = 0; i < FILAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            char estado = 'S';

            if (matriz[i][j].E > 0) {
                estado = 'E';
            }
            if (matriz[i][j].I > 0) {
                estado = 'I';
            }
            if (matriz[i][j].R > 0) {
                estado = 'R';
            }

            printf("%c ", estado);
        }
        printf("\n");
    }
    printf("\n");
}

int main() {
    srand(time(NULL));

    double beta = 0.5;
    double sigma = 1.0 / 2.0;
    double gamma = 1.0 / 15.0;
    double dt = 1.0;

    Celda matriz[FILAS][COLUMNAS];

    for (int i = 0; i < FILAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            matriz[i][j].S = 100.0;
            matriz[i][j].E = 0.0;
            matriz[i][j].I = 0.0;
            matriz[i][j].R = 0.0;
        }
    }

    distribuir_infectados_aleatorio(matriz, 5);

    printf("Día 1:\n");
    imprimir_matriz_estados(matriz);

    for (int t = 1; t < 10; t++) {
        for (int i = 0; i < FILAS; i++) {
            for (int j = 0; j < COLUMNAS; j++) {
                actualizar_celda_con_vecinos(matriz, i, j, beta, sigma, gamma, dt);
            }
        }

        printf("Día %d:\n", t + 1);
        imprimir_matriz_estados(matriz);
    }

    return 0;
}
