import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from matplotlib.gridspec import GridSpec

class SEIRDashboard:
    def __init__(self, csv_path):
        # Configurar el estilo
        plt.style.use('default')
        
        # Crear figura con dos subplots
        self.fig = plt.figure(figsize=(15, 10))
        gs = GridSpec(2, 1, height_ratios=[1, 1.5], hspace=0.3)
        
        # Crear los dos axes
        self.ax1 = self.fig.add_subplot(gs[0])  # Barras
        self.ax2 = self.fig.add_subplot(gs[1])  # Evolución temporal
        
        # Colores para cada estado SEIR
        self.colors = {
            'Susceptible': 'blue',
            'Expuesto': 'orange',
            'Infectado': 'red',
            'Recuperado': 'green'
        }
        
        # Cargar datos
        self.data = pd.read_csv(csv_path)
        self.time_steps = sorted(self.data['Tiempo'].unique())
        
        # Preparar datos para la evolución temporal
        self.prepare_temporal_data()
        
    def prepare_temporal_data(self):
        """Prepara los datos para la gráfica de evolución temporal"""
        # Agrupar por Tiempo y calcular promedios
        self.temporal_data = self.data.groupby('Tiempo').agg({
            'Susceptible': 'mean',
            'Expuesto': 'mean',
            'Infectado': 'mean',
            'Recuperado': 'mean'
        }).reset_index()
        
    def update(self, frame):
        """Actualiza ambas gráficas en cada frame"""
        # Limpiar los axes
        self.ax1.clear()
        self.ax2.clear()
        
        # Obtener datos del frame actual
        current_data = self.data[self.data['Tiempo'] == frame].mean()
        
        # Actualizar gráfico de barras
        estados = ['Susceptible', 'Expuesto', 'Infectado', 'Recuperado']
        valores = [current_data[estado] for estado in estados]
        labels = ['Susceptible', 'Expuesto', 'Infectado', 'Recuperado']
        colors = [self.colors[label] for label in labels]
        
        # Crear barras
        bars = self.ax1.bar(labels, valores, color=colors)
        
        # Añadir valores encima de las barras
        for bar in bars:
            height = bar.get_height()
            self.ax1.text(bar.get_x() + bar.get_width()/2., height,
                         f'{height:.1f}%',
                         ha='center', va='bottom')
        
        # Configurar gráfico de barras
        self.ax1.set_ylim(0, 100)
        self.ax1.set_ylabel('Promedio de individuos')
        self.ax1.set_title(f'Estado de la población en Tiempo {frame}')
        
        # Actualizar gráfico de evolución temporal
        temporal_data = self.temporal_data[self.temporal_data['Tiempo'] <= frame]
        
        for estado, color, label in zip(['Susceptible', 'Expuesto', 'Infectado', 'Recuperado'], 
                                      colors, 
                                      labels):
            self.ax2.plot(temporal_data['Tiempo'], 
                         temporal_data[estado],
                         color=color,
                         label=label)
        
        # Configurar gráfico de evolución temporal
        self.ax2.set_xlabel('Tiempo')
        self.ax2.set_ylabel('Promedio de individuos')
        self.ax2.set_title('Evolución temporal de la población')
        self.ax2.legend()
        self.ax2.grid(True)
        
        # Título general
        self.fig.suptitle('Simulación de Contagio', y=0.95)
        
    def animate(self, interval=500):
        """Crear la animación"""
        anim = FuncAnimation(
            self.fig,
            self.update,
            frames=self.time_steps,
            interval=interval,
            repeat=True
        )
        return anim

def visualize_seir_dashboard(csv_path):
   
    try:
        # Crear dashboard
        dashboard = SEIRDashboard(csv_path)
        
        # Crear y mostrar animación
        anim = dashboard.animate()
        plt.show()
        
    except Exception as e:
        print(f"Error al visualizar los datos: {str(e)}")

if __name__ == "__main__":
    visualize_seir_dashboard('datos_simulacion.csv')