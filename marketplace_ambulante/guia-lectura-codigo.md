# Guía para leer el código — Ecosistema para Negocios

Ruta para entender la app en orden: primero la idea general y después archivo por archivo, siguiendo cómo viaja la información.

---

## Paso 0: la idea que lo une todo

La app está dividida en 3 capas (MVVM) más una carpeta de apoyo:

| Carpeta | Pregunta que responde | Ejemplo |
|---|---|---|
| `lib/model` | ¿Qué datos hay y de dónde salen? | `Negocio`, `NegocioRepositoryMock` |
| `lib/viewmodel` | ¿Qué hace la app con esos datos? | `MarketplaceViewModel` ordena por distancia |
| `lib/view` | ¿Cómo se ve en pantalla? | `MarketplaceScreen` dibuja las tarjetas |
| `lib/core` | Herramientas que usan todos | tema, rutas, validadores |

La regla de oro es que **la View nunca habla con el Model**. Siempre pasa por el ViewModel:

```
View  ──pide──▶  ViewModel  ──pide──▶  Repositorio (Model)
View  ◀─estado──  ViewModel  ◀─datos───  Repositorio
```

---

## Paso 1: el arranque (2 archivos)

1. **`main.dart`**: solo hace `runApp(ProviderScope(...))`. El `ProviderScope` es la "caja" donde vive todo Riverpod. Sin él no funciona ningún provider.
2. **`app.dart`**: crea el `MaterialApp.router`, le pone el tema y el router.

---

## Paso 2: los datos, la capa Model (lee en este orden)

1. **Los modelos**: `usuario.dart`, `negocio.dart`, `producto.dart`, `pedido.dart`, `chat.dart`.
   - Son clases simples con campos (`nombre`, `precio`…).
   - Fíjate en `copyWith`: crea una copia cambiando solo algunos campos. Se usa porque los objetos no se modifican, se reemplazan.
   - Compara cada modelo con la tabla de `modelo-de-datos.md`: son casi lo mismo.
2. **Los contratos**, por ejemplo `negocio_repository.dart`.
   - Es una `abstract class`: dice *qué* se puede pedir (`obtenerCercanos`, `guardar`…), pero no *cómo*.
3. **Los mocks**, por ejemplo `negocio_repository_mock.dart` y `mock_usuarios.dart`.
   - Implementan el contrato con listas en memoria y un `Future.delayed` que simula la espera de internet.
   - Por eso los datos se borran al presionar `R`.
4. **`repository_providers.dart`**: el archivo más importante para el futuro.
   - Es el único lugar donde se decide "usa el Mock".
   - Cuando exista MySQL, solo se cambia aquí `NegocioRepositoryMock()` por `NegocioRepositoryApi()`.
5. **Servicios del teléfono**: `ubicacion_service.dart` (GPS) e `imagen_service.dart` (cámara y galería). Siguen la misma idea: un contrato y una implementación.

---

## Paso 3: la lógica, la capa ViewModel

1. **`sesion_viewmodel.dart`**: guarda quién inició sesión. Muchos otros archivos lo observan.
2. **`estado_formulario.dart`** y **`resultado.dart`**: son las "respuestas" que el ViewModel le da a la View.
   - `EstadoFormulario` dice si está cargando y si hubo error.
   - `Resultado` puede ser `Exito`, `Fallo(mensaje)` o `RequiereAjustes`, que muestra el pop-up de permisos.
3. **`sign_in_viewmodel.dart`**: el más simple. Léelo línea por línea:
   - `build()` define el estado inicial.
   - `iniciarSesion()` hace estas cosas en orden:
     1. Pone `cargando: true`.
     2. Llama al repositorio con `ref.read(authRepositoryProvider)`.
     3. Si sale bien, guarda la sesión.
     4. Si falla, guarda el error en el estado.
   - Al final, `signInViewModelProvider` es lo que la pantalla usa para encontrarlo.
4. Después sigue con los que tienen un archivo `_state` aparte: `marketplace_viewmodel` con `marketplace_state`, `panel_negocio_viewmodel` con su state y `configuracion_negocio_viewmodel` con su state.

---

## Paso 4: lo que se ve, la capa View

1. **`sign_in_screen.dart`**: busca estas 3 líneas, que son el patrón de todas las pantallas:
   - `ref.watch(signInViewModelProvider)`: observa el estado. Si cambia, la pantalla se redibuja (por ejemplo, para mostrar el error).
   - `ref.read(...notifier).iniciarSesion(...)`: le pide al ViewModel una acción. Se usa `read` porque es un clic, no algo que se observa.
   - `context.go(AppRoutes.segunUsuario(usuario))`: navega a otra pantalla.
2. **`widgets/`**: piezas reutilizables, como los campos de login (`auth_widgets.dart`), el chip de estado del pedido (`pedido_widgets.dart`) y el pop-up de permisos (`permisos_widgets.dart`).
3. Después lee las pantallas en el orden en que las usa una persona:
   - Sign up → Sign in → ¿Eres un?
   - Lado negocio: Tipo de negocio → Configuración → Panel.
   - Lado usuario: Inicio usuario (las pestañas de abajo) → Marketplace → Página del negocio → Confirmar pedido → Mis pedidos → Chats → Chat → Perfil → Acerca de.

---

## Paso 5: la navegación (`core/router/app_router.dart`)

- `AppRoutes` tiene todas las rutas (`/iniciar-sesion`, `/marketplace`, `/negocios/:id`…).
- `segunUsuario()` decide a dónde va cada quien después del login: sin rol va a "¿Eres un?", el cliente al Marketplace y el negocio al Panel.
- `redirect` es el "guardia": si no hay sesión, te devuelve al login.

---

## Paso 6: sigue un flujo completo con el dedo

Para fijar todo lo anterior, recorre **"iniciar sesión"** saltando entre archivos:

1. Escribes el correo y presionas el botón (`sign_in_screen.dart`, `onPressed: _iniciarSesion`).
2. La pantalla llama a `iniciarSesion` del ViewModel (`sign_in_viewmodel.dart`).
3. El ViewModel le pregunta al repositorio (`auth_repository_mock.dart`, que busca en `mock_usuarios.dart`).
4. El repositorio responde con el usuario, o con una `AuthException` si la contraseña está mal.
5. El ViewModel guarda la sesión (`sesion_viewmodel.dart`) y actualiza su estado.
6. La pantalla navega (`app_router.dart`, `segunUsuario`).

Después haz lo mismo con **"el negocio acepta un pedido"**: `panel_negocio_screen` → `panel_negocio_viewmodel` → `pedido_repository_mock`.

---

## Paso 7: los tests como "manual de uso"

En `test/viewmodel/` cada test explica en una frase qué debe pasar y luego lo prueba. Por ejemplo, `auth_viewmodel_test.dart` muestra cómo se usa cada ViewModel sin abrir la app. Es de lo más fácil de leer.

---

## Consejos para estudiarlo

- **Para ver un archivo por dentro:** en VS Code, `Ctrl + clic` sobre un nombre te lleva a donde está definido.
- **Para ver todos los lugares donde se usa algo:** clic derecho sobre el nombre y elige "Find All References".
- **Para comprobar que entendiste:** cambia algo pequeño, presiona `R` y mira qué pasa. Por ejemplo, cambia el texto de error en `sign_in_viewmodel` o la latencia del mock.
- **Las 3 palabras de Riverpod que más vas a ver:**
  - `ref.watch`: observar y redibujar cuando cambie.
  - `ref.read`: usar una sola vez, en un clic.
  - `ref.invalidate`: "vuelve a cargar", por ejemplo después de guardar.
