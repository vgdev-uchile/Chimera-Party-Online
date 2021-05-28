# Chimera Party Online

Chimera Party Online es un juego party para 2 a 4 jugadores desarrollado por la comunidad de desarrollo de videojuegos de la Universidad de Chile (VGDev UChile). La idea detrás de Chimera Party es tener un juego en que toda la comunidad pueda contribuir, permitiendo que gente con distintos niveles de experiencia cree sus minijuegos y los incorpore fácilmente al juego base para que todos puedan disfrutarlos.

## How 2 Chimera Party when you only want 2 party

Para hostear un juego de Chimera Party tienes que abrir el juego, seleccionar "Comenzar", escribir el nombre que usarás y seleccionar "Crear".

Para unirte a un juego de Chimera Party tienes que abrir el juego, seleccionar "Comenzar", escribir el nombre que usarás y la IP del jugador que está hosteando el juego, luego seleccionar "Unirse".

Una vez dentro del lobby debes seleccionar el color de jugador que usarás y presionar "Listo". Si todos los jugadores presionan "Listo" el juego comenzará, así que no lo presionen todos si es que aún están esperando que alguien se conecte.

### Controles

Los controles se seleccionarán automáticamente dependiendo de qué botones presiones en el lobby, los controles disponibles son:
* WASD, J, K
* Flechas, Z, X
* D-pad, A/X/B, B/O/A (para control de XBox/PlayStation/Nintendo)

# How 2 Chimera Party when you don't know how 2 Chimera Party

## Índice
1. [Añadir un juego](#add-game)

   1.1 [Configuración inicial](#initial-config)
   
   1.2 [Rellenar config.tres](#fill-config)

   1.3 [Añadir una imagen de introducción](#intro-img)
   
2. [API de Chimera Party](#implementation)

   2.1 [Cargar jugadores](#load-players)
   
   2.2 [Inicializar jugadores](#init-players)
   
   2.3 [Terminar el juego](#end-game)
   
3. [Online Básico](#online-101)

4. [Probar tu juego](#test)

5. [Compartir tu juego](#share)

6. [Consideraciones](#aaahh)


## Añadir un juego <a name="add-game"></a>

### Configuración inicial <a name="initial-config"></a>

* **Crear una nueva carpeta dentro de la carpeta `games`:** En esta carpeta vivirá tu juego, así que debes ponerle un nombre descriptivo (o sea, no la dejes como "Nueva carpeta"). Todas las acciones descritas a continuación deben ser realizadas dentro de esta carpeta. **NO** cambies nada fuera de tu carpeta o podrías afectar otros juegos o incluso el juego principal.
* **Crear el archivo `config.tres`**
  * Haz click derecho en tu carpeta y selecciona `New Resource`
  * En la ventana emergente, busca `config` (puedes usar la barra de búsqueda) para crear la configuración de tu juego, a este archivo lo debes llamar `config.tres`
* **Crear la escena principal de tu juego**
  * Haz click derecho en tu carpeta y selecciona `New Scene`, esta escena debe llamarse `index` y no la debes mover a una carpeta interior.
  * Selecciona qué tipo de nodo será tu escena principal y guarda tu escena.

### Rellenar el archivo config.tres <a name="fill-config"></a>
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

### Añadir una imagen de introducción <a name="intro-img"></a>

Dentro de la carpeta principal de tu juego (junto a `config.tres` e `index.tscn`), debes incluir una imagen llamada `intro.png`, de dimensiones `1280x720`. Esta imagen será utilizada en la pantalla de introducción de tu juego. Puedes incluir un pantallazo de tu juego terminado o crear una imagen especial para esta pantalla.


## Chimera API <a name="implementation"></a>

A partir de aquí se explicará a grandes rasgos cómo utilizar la API de Chimera Party Online y algunos elementos básicos para implementar jugabilidad online en Godot; si prefieres ver esto funcionando en un juego, puedes ver el código del juego `hexfall` dentro de la carpeta `games` para entender su funcionamiento.

### Cargar jugadores <a name="load-players"></a>

Al inicializar tu juego, debes obtener los jugadores desde el juego principal; puedes obtener el arreglo de jugadores y guardarlo dentro de una variable en la función `_ready()` de tu script principal con `players = Party.get_players().duplicate()`, este arreglo contiene objetos del tipo `Player`, que tiene las siguientes propiedades:
* `name`: el nombre que se puso el jugador al iniciar el juego.
* `nid`: Network ID, esta variable se usa para configurar el online.
* `local`: ni idea, mejor no tocarlo.
* `slot`: El número del jugador, está entre 0 y 3 y puedes usarlo como un ID.
* `keyset`: Los botones que el jugador eligió para jugar, esto es necesario para configurar los controles de tu personaje.
* `color`: Entero entre 0 y 3 que indica el color que eligió el jugador. Los colores son:
  * 0 - Verde
  * 1 - Rojo
  * 2 - Amarillo
  * 3 - Azul
 
   Pero no necesitas recordarlos, ya que usando la variable `color` puedes obtener el objeto de tipo `Color` correspondiente llamando a `Party.get_colors()[color]`, o el nombre del color, llamando a `Party.get_color_names()[color]`
* `points`: los puntos que tiene el jugador. Estos son los puntos acumulados a través de los juegos y son independientes del sistema de puntaje que puedas implementar dentro de tu juego (a menos que quieras utilizar estos puntajes dentro de tu juego...)

### Inicializar jugadores <a name="init-players"></a>

Una vez hayas obtenido el arreglo de jugadores, puedes instanciar las escenas que vayan a usar, un ejemplo básico sería:

```gdscript
# Cargamos la escena de los jugadores al principio
var player_scene = preload("ruta/de/mi/escena")
# *puedes arrastrar tu escena dentro de los
# paréntesis y se rellenará automáticamente

var players # Aquí guardaremos a los jugadores

# Nodo, hijo de index, en que colocaremos a los jugadores
var player_container = $Players

func _ready():
	players = Party.get_players().duplicate()
	for i in range(players.size()):
		var p = player_scene.instance()
		p.init(players[i]) # Esta función se explicará más adelante
		player_container.add_child(p)
		# Definir aquí la posición inicial del jugador
		# y otras cosas que quieras hacer
```

La función `init()` debes definirla en la escena del personaje jugador; esta se encargará de configurar la escena con los datos de su jugador correspondiente, una función `init()` debería ser como mínimo similar a esta:

```gdscript
var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

func init(player: Player):
	# Esta línea hará que el objeto sepa quién es su "dueño"
	set_network_master(player.nid)
	
	# Esto configura los controles para cada botón
	# según haya elegido el jugador
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	
	# Aquí puedes agregar otras cosas como:
	# obtener el nombre del jugador con player.name
	# obtener el color con player.color
	# También puedes guardar player en una
	# variable para acceder a ella después
```

### Terminar el juego <a name="end-game"></a>

Cuando acabe tu juego (se recomienda hacer juegos cortos, que tomen entre uno y cinco minutos), debes llamar la función `Party.end_game(puntajes_finales)`, que toma como argumento un arreglo de diccionarios con los puntajes de cada jugador, para ilustrarlo mejor, esta estructura debería ser así:

```python
puntajes_finales = [
	{
		"player": players[0],
		"points": puntaje_0
	},
	{
		"player": players[1],
		"points": puntaje_1
	}, ...
]
```

Llamar `Party.end_game()` hará que se vuelva inmediatamente al juego principal, así que si quieres mostrar alguna pantalla de término especial puedes activar un temporizador cuando tu juego acabe "oficialmente" y llamar `end_game()` cuando este haga _timeout_.

Cuánto puntaje asignes a cada jugador es decisión tuya, pero en general los juegos de Chimera Party otorgan entre 0 y 100 puntos a cada jugador dependiendo de su desempeño (léase: 100 al ganador, 0 al perdedor, con puntajes intermedios para los demás), pero esto no significa que no puedas, por ejemplo, hacer que los jugadores pierdan puntaje, o dar más de 100 puntos en un juego, solo ten en mente que si tu minijuego da 9999 puntos al ganador o algo por el estilo, el juego se va a desbalancear, y dejará de ser divertido para los demás al no poder remontarlo.


## Online Básico <a name="online-101"></a>

Implementar jugabilidad online puede ser algo complicado, pero por suerte Chimera Party facilita mucho el trabajo y no hay que preocuparse de demasiadas cosas. Aquí se mecionarán solo algunas cosas que necesitas saber para implementar un minijuego en Chimera Party Online.

* `is_network_master()`: ¿Recuerdas que en la función `init()` hay una línea que dice `set_network_master(player.nid)`? Eso permite que la escena del personaje jugador sepa quién la está controlando, y al usar `is_network_master()` podemos hacer que algunas cosas se ejecuten solo en el personaje correspondiente a un jugador y no en los demás. Como ejemplo, si cada personaje tiene una cámara propia (ya sea porque es un juego 3D o porque el mapa es más grande que la pantalla), nos gustaría que cada jugador tenga como cámara actual la que le corresponde a su personaje, esto lo podemos hacer con:

```gdscript
func _ready():
	if is_network_master():
		$Camera.current = true
```

Tambien pueden haber ocasiones en que quieras usar `is_network_master()` fuera de los personajes jugadores, como por ejemplo, para llamar una función aleatoria desde el script principal del juego, así el host será el encargado de llamar la función aleatoria y luego informará del resultado a los demás jugadores, evitando que hayan inconsistencias.

* `rpc()`: Significa _Remote Procedure Call_, y permite a una escena llamar una función en los demás computadores. `rpc()` toma como argumento el nombre de la función que va a llamar (este debe ser una string) y los argumentos que le debe pasar a la función, si es que los tiene. La función que llamarás con `rpc()` debe estar en el nodo que está llamando `rpc()`. Un ejemplo de uso sería el siguiente:

```gdscript
remotesync func pegarle_al_francisco(cuanto):
	print("Le pegaste al Francisco {cuanto} veces!".format({"cuanto": cuanto}))
	
func _input(event):
	if not is_network_master():
		return
	if event.is_action_pressed(action_a):
		rpc("pegarle_al_francisco", 10)
```

* `rset()`: significa _Remote set_, esto es similar a `rpc()` pero para asignar valores a variables, toma como argumentos el nombre de la variable (como string) y el valor que se le asignará. Un ejemplo de uso es:

```gdscript
remotesync var numbers = [1, 2, 3, 4, 5, 6]

func begin_game():
	if is_network_master():
		numbers.shuffle()
		rset("numbers", numbers)
```

Como habrás visto, en los ejemplos anteriores se anteponía la palabra `remotesync` al definir las variables y funciones que se llamaban con `rpc()` y `rset()`, esto es porque por razones de seguridad, Godot bloquea el llamado de cualquier función o el cambio de cualquier variable a través de estas funciones si no tienen alguna de las siguientes palabras clave:  `remote`, `remotesync`, `puppet`, `master`, `mastersync`, `puppetsync`. A continuación se explicará qué significa cada una de estas palabras:

* `remote` y `remotesync`: `remote` llama una función (o setea una variable) en el computador de todos los demás jugadores, excepto el que la llama; `remotesync` hace lo mismo pero también llama la función en quien usa `rpc()`.
* `puppet` y `master`: llama la función (o setea la variable) solo si `is_network_master() == true`, para `master`, o si `is_network_master() == false`, para `puppet`.
* `puppetsync` y  `mastersync`: lo mismo que `puppet` y `master`, pero también llaman la función para quien usa `rpc()`, o setean la variable para quien usa `rset()`.

Aquí hay un ejemplo del juego `hexfall` donde se usan variables `puppet` para sincronizar el personaje de un jugador en los demás computadores con las inputs del jugador en su computador:

```gdscript
# networking
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = Vector2()


func _physics_process(delta):
	...
		var target_vel
		if is_network_master():
			target_vel = Vector2(
				Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
				Input.get_action_strength(move_down) - Input.get_action_strength(move_up))
			rset("puppet_target_vel", target_vel)
		else:
			target_vel = puppet_target_vel
		if target_vel.length_squared() > 1:
			target_vel = target_vel.normalized()
		if stopped:
			target_vel = Vector2()
		var speed = SPEED
		
		linear_vel = linear_vel.linear_interpolate(target_vel * speed, 0.2)
		linear_vel = move_and_slide(linear_vel)
		
		# fix position
		if is_network_master():
			rset("puppet_pos", position)
		else:
			position = lerp(position, puppet_pos, 0.5)
			puppet_pos = position
```

Si aún no queda claro lo de `master` y `puppet`, por defecto todo tiene como `master` el computador del host, y será un `puppet` en los computadores de los demás jugadores, así que el host es el que tiene "la verdad" de lo que pasa en el juego, con sus `puppet` siendo solo una aproximación del `master`; al hacer `set_network_master()` para los personajes de los jugadores, hacemos que cada jugador sea `master` de su propio personaje, y por lo tanto, tenga la instancia "verdadera" de su personaje.

Y si aún no queda claro... usa `remotesync`; es complicado este tema, y no tiene nada de malo que no lo entiendas completamente a la primera, segunda o tercera, pero `remotesync` es lo más cercano a llamar una función o setear una variable en todas partes, que probablemente es lo que querrás hacer la mayoría de las veces, a menos que quieras hacer algo solo para los demás jugadores, en cuyo caso debes usar `remote`. Cabe notar que probablemente verás la palabra `sync` en el código de otros juegos, esto es un alias de `remotesync`, pero actualmente es considerado obsoleto y se recomienda usar solamente `remotesync`.

## Probar tu juego <a name="test"></a>

Para probar tu juego dentro de tu computador, puedes correr dos instancias de Chimera Party (esto significa abrir tu proyecto de Godot en dos ventanas distintas y correrlo en ambas) y en la primera seleccionar `Test` en el menú principal, luego seleccionas tu juego en el menú desplegable (aparecerá con el nombre de su carpeta), presionas "Comenzar" y luego "Crear". En la otra ventana, solo presionas "Comenzar" y luego "Unirse", esto iniciará tu juego inmediatamente sin tener que pasar por el lobby ni tener que esperar a que salga aleatoriamente tu juego.

## Compartir tu juego <a name="share"></a>

Para compartir tu juego basta con enviar la carpeta del minijuego a tus amigos; con solo poner dentro de la carpeta `games` la carpeta de un minijuego, Chimera Party lo detectará y será añadido a los juegos que pueden salir. 

## Consideraciones <a name="aaahh"></a>

* Ya se dijo al principio, pero vale la pena repetirlo: **NO** modifiques nada fuera de la carpeta de tu minijuego, en el peor de los casos puedes estropear el juego de otra persona o incluso el juego principal.
* Usa \*.ogg para tus archivos de música: Si añades música en formato \*.wav, estarás añadiendo mucho peso al juego, limítate a usar \*.wav para efectos de sonido cortos y usa \*.ogg para la música de fondo.
* Intenta no usar `class_name` en tus scripts, especialmente si quieres usar un nombre muy genérico, ya que podría acabar generando conflictos si dos personas quieren usar el mismo `class_name`, o alguien quiere nombrar una variable igual que tu clase; incluso podrías intentar usar uno de los nombres definidos por Chimera Party y romper el juego.
* Dale un nombre distintivo a la carpeta de tu minijuego: sería terrible tener la carpeta `games` llena de `Nueva carpeta`, `Nueva carpeta 1`, `Nueva carpeta 2`, ...; o `Mi juego`, `Mi juego 2`, `Mi otro juego`, ...; además, para probar tu juego es mucho más fácil encontrarlo en el menú si le das un nombre descriptivo.

### Referencias

[Documentación High Level Multiplayer en inglés](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)


[Documentación High Level Multiplayer en español](https://docs.godotengine.org/es/stable/tutorials/networking/high_level_multiplayer.html)
