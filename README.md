# Chimera Party Online
 
## How 2 Chimera Party when you don't know how 2 Chimera Party

### Añadir un juego

#### Configuración inicial

* **Crear una nueva carpeta dentro de la carpeta `games`:** En esta carpeta vivirá tu juego, así que debes ponerle un nombre descriptivo (o sea, no la dejes como "Nueva carpeta"). Todas las acciones descritas a continuación deben ser realizadas dentro de esta carpeta. **NO** cambies nada fuera de tu carpeta o podrías afectar otros juegos o incluso el juego principal.
* **Crear el archivo `config.tres`**
  * Haz click derecho en tu carpeta y selecciona `New Resource`
  * En la ventana emergente, busca `config` (puedes usar la barra de búsqueda) para crear la configuración de tu juego, a este archivo lo debes llamar `config.tres`
* **Crear la escena principal de tu juego**
  * Haz click derecho en tu carpeta y selecciona `New Scene`, esta escena debe llamarse `index` y no la debes mover a una carpeta interior.
  * Selecciona qué tipo de nodo será tu escena principal y guarda tu escena.

### Rellenar el archivo config.tres
En este archivo debes colocar algunos datos sobre tu juego. Al clickear en él sólo verás que tiene una propiedad llamada `Modes`, con un Array de largo 0, aquí debes colocar tantos elementos como modos de juego vayas a implementar, los modos de juego disponibles son:
* Free For All: Este modo acepta de dos a cuatro jugadores, todos contra todos.
* 2v2: Este modo solo se juega cuando hay cuatro jugadores, los que serán divididos en equipos de dos.
* 1v3: Este modo solo se juega cuando hay cuatro jugadores, y generalmente es asimétrico, con un jugador siendo considerablemente más fuerte que el resto.

Cuando hayas decidido qué modos de juego implementarás, tienes que agregar el recurso correspondiente al array `Modes`. Al clickear en la zona que dice `[empty]`, se desplegará una lista con todos los tipos de recurso disponibles; esta lista es muy larga, pero está en orden alfabético; aquí tienes que buscar las opciones `New GameMode1v3`, `New GameMode2v2` o `New GameModeFFA`, dependiendo del modo de juego que vayas a configurar.

Todos los modos de juego comparten algunas propiedades, con 2v2 y 1v3 agregando algunas propias. Las propiedades comunes son:
* `Display Name`: Este es el nombre con el que será presentado tu minijuego.
* `Description`: Este es un texto breve que saldrá en la pantalla de presentación de tu juego, lo puedes usar para explicar las reglas y contextualizar.
* `Input 0-7`: Los grupos de inputs que usarás en tu juego, no necesitas rellenarlos todos, solo los que vayas a usar. Por ejemplo, si en tu juego puedes moverte con las flechas y disparar con el botón A, puedes marcar las casillas `Left`, `Right`, `Up` y `Down` en `Input 0` y la casilla `A` en `Input 1`.
* `Description 0-7`: La descripción del grupo de inputs respectivo. En el ejemplo anterior, en `Description 0` podrías colocar "Moverse" y en `Description 1`, podrías poner "Disparar".

Las propiedades del modo 1v3 son:
* `Use Groups`: Marca esta opción si el jugador solitario tendrá inputs diferentes al resto de jugadores.
* `Team First Input`: Este es el índice donde comienzan las inputs de los jugadores en equipo cuando `use_groups` está seleccionado. Así, si las inputs del jugador solitario están descritas en `Input 0` e `Input 1`, las del resto de jugadores estarán a partir de `Input 2`, y `team_first_input` debe ser 2. Esto significa que siempre debes definir las inputs del equipo después de las del jugador que estará solo.
* `Solo Name`: El nombre que se le dará al jugador solitario en la pantalla de introducción. Por ejemplo, si en tu juego un dragón se enfrenta a un equipo de cazadores, `solo_name` podría ser "Dragón".
* `Team Name`: El nombre que se le dará al equipo en la pantalla de introducción. Por ejemplo, si en tu juego un dragón se enfrenta a un equipo de cazadores, `team_name` podría ser "Cazadores".

Las propiedades del modo 2v2 son:
* `Use Groups`: Marca esta opción si el equipo A tendrá controles distintos al equipo B.
* `Team B First Input`: Si los equipos tienen controles distintos, este es el índice en que empiezan a definirse los controles del equipo B. Por ejemplo, si los controles del equipo A están descritos en `Input 0` e `Input 1`, los del resto de jugadores estarán a partir de `Input 2`, y `team_b_first_input` debe ser 2. Esto quiere decir que siempre debes colocar primero los controles del equipo A.
* `Team A Name`: El nombre que se le dará al equipo A en la pantalla de introducción.
* `Team B Name`: El nombre que se le dará al equipo B en la pantalla de introducción.


### Implementar el juego

A partir de aquí se explicará a grandes rasgos cómo utilizar la API de Chimera Party Online y algunos elementos básicos para implementar jugabilidad online en Godot; si prefieres ver esto funcionando en un juego, puedes ver el código del juego `hexfall` dentro de la carpeta `games` para entender su funcionamiento.
