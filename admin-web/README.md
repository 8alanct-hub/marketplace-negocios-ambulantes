# Ecosistema · Panel web de administración

Panel para el administrador de la app **Ecosistema para negocios y emprendimientos independientes**.
Hecho con **HTML, CSS y JavaScript** (sin frameworks ni instalaciones).

## Cómo abrirlo

- **En tu computador:** doble clic en `index.html`.
- **En internet:** con GitHub Pages (ver abajo).

Cuenta de prueba (modo prueba):
- Correo: `admin@test.com`
- Contraseña: `Prueba123`

## Modo prueba y modo API

En `js/config.js`:

```js
const CONFIG = { API_URL: '' };   // vacío = modo prueba
```

- **Modo prueba** (`API_URL` vacío): usa datos de prueba y guarda los cambios en el navegador,
  así todas las pantallas ven lo mismo. Para volver a los datos originales: consola del
  navegador (F12) → `Datos.reiniciarPrueba()` → recargar.
- **Modo API** (`API_URL` con la dirección de la API): todo se lee y se guarda en la base de datos.
  Lo que la API debe responder está en **[API.md](API.md)**.

## Publicarlo con GitHub Pages

1. Sube la carpeta `admin-web` al repositorio.
2. En GitHub: **Settings → Pages**.
3. En *Source* elige **Deploy from a branch**, rama **main**, carpeta **/ (root)** y **Save**.
4. En unos minutos queda en: `https://USUARIO.github.io/REPOSITORIO/admin-web/`

GitHub Pages solo publica la web (la parte visual). La base de datos y la API van en otro
servidor; la web se conecta a ella con la dirección de `js/config.js`.

> Importante: mientras esté en modo prueba, la contraseña de prueba está escrita en
> `js/datos.js` y cualquiera que vea el código la puede leer. Con la API real eso desaparece,
> porque la contraseña la valida el servidor.

## Pantallas

| Archivo | Pantalla | Qué hace |
|---|---|---|
| `index.html` | Inicio de sesión | Solo administradores. Ojo para ver la contraseña. |
| `dashboard.html` | Dashboard | Cifras de usuarios, negocios, reportes y moderación. Reportes recientes (clic = cuadro con el detalle). |
| `usuarios.html` | Usuarios | Lista A–Z, buscador, filtros. Suspender (pide motivo) o reactivar cuenta. |
| `negocios.html` | Negocios | Lista A–Z, buscador, filtros. Ver sus reportes. Reactivar. (Suspender se hace desde Reportes.) |
| `reportes.html` | Reportes | Quejas sobre un **negocio**. Resolver, en revisión, descartar, enviar a Moderación, suspender el negocio. |
| `moderacion.html` | Moderación | Un **contenido** puntual (foto, producto, descripción). Mantener, quitar o enviar a Reportes. |

### Reportes vs. Moderación

- **Reportes**: el problema es el negocio (servicio o comportamiento). Se puede suspender el negocio.
- **Moderación**: el problema es solo una foto, un producto o la descripción. Se quita ese contenido; el negocio sigue activo.
- Un caso puede pasar de una bandeja a la otra con «Enviar a Reportes» / «Enviar a Moderación», y siempre muestra su **origen**.

## Estructura

```
admin-web/
├── index.html, dashboard.html, usuarios.html, negocios.html, reportes.html, moderacion.html
├── API.md               ← lo que la API debe responder (para conectar la base de datos)
├── css/
│   └── estilos.css      ← estilos compartidos (mismo estilo que la app)
└── js/
    ├── config.js        ← dirección de la API (vacío = modo prueba)
    ├── datos.js         ← MODELO: el ÚNICO archivo que habla con los datos / la API
    ├── comun.js         ← sesión, menú lateral, cuadro central, avisos, buscador
    └── login.js, dashboard.js, usuarios.js, negocios.js, reportes.js, moderacion.js
                         ← la lógica de cada pantalla
```
