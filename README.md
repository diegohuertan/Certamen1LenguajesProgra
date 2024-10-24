# Explicacion de las intrucciones

- primero debemos realizar el make para poder iniciar los archivos
- Luego iniciamos el ejecutable que en nuestro caso le colocamos automataCelular por lo que seria ./automataCelular
- al ejecutar el programa, nosotros lo diseñamos de forma que en un txt le entregamos las intrucciones para crear cada automata simetrico, crear el automata asimetrico, asignar cada automata simetrico dentro del automata asimetrico y las conexiones
 
1) La instrucción para crear el automata simetrico:
 crear automata simetrico rojo 2 2 s98 e1 i1 r0 s90 e5 i5 r0 s80 e15 i5 r0 s98 e1 i1 r0

En esta instruccion le damos el color del automata simetrico, el tamaño de la "matriz" que seria 2 x 2 en el caso anterior mencionado y despues definimos el comportamiento SEIR para cada celda del automata que es una matriz junto con la cantidad de personas en cada estado del comportamiento

2) La instruccion para crear el automata asimetrico:
asimetrico 2 2
donde colocamos la palabra reservada asimetrico y el tamaño de este, en el ejemplo antes mencionado seria una matriz de 2 x 2

3) La instruccion para asignar los automatas simetricos:
asignar 1 2 0
Colocamos la palabra reservada asignar junto con 3 numeros donde los 2 primeros seriaa la posicion donde se ubicaria en la matriz del automata asimetrico y el 3er numero seria el indice donde se almacenará este automata dentro de una lista

4) La instruccion para conectar los automatas simetricos entre si:
conectar 0 0 0 1
Colocamos la palabra reservada conectar junto con 4 numeros los cuales, los 2 primeros son la posicion del automata simetrico 1, por asi decirlo, dentro del automata asimetrico y los 2 ultimos serian la posicion del automata simetrico 2, dentro del automata asimetrico

5) La intruccion para simular los contagios entre las poblaciones entre los automatas siemtricos seria:
simular 15
Colocamos la palabra reservada simular junto con un numero, este numero es la cantidad de simulaciones que se realizará

6) La intruccion para "aislar" una poblacion de las demas poblaciones seria:
aislar 1 2
Colocamos la palabra reservada aislar junto con 2 numeros, estos numeros serian la posicion del automata simetrico que queremos aislar de los demas, ya que el programa lo iniciamos con todos los automatas simetricos conectados. En el ejemplo de la instruccion estariamos desconectando todos los automatas que tiene una conexion con ese automata.

7) La instruccion para imprimir el automata asimetrico con sus automatas simetricos correspondientes seria:
imprimir
Con esta palabra reservada mostramos por pantalla el conjunto de automatas celulares completo
