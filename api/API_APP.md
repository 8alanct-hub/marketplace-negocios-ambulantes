# Rutas de la app móvil (`/api/app`)

Las usa la app de Flutter (carpeta `marketplace_ambulante`). El código está en `src/rutas/app.js`.

- Todo se envía y se recibe en **JSON**. Los ids viajan como texto (`"7"`) y las fechas en formato ISO (`2026-11-17T15:00:00.000Z`).
- Menos `registro` y `login`, todas las rutas piden el encabezado `Authorization: Bearer <token>`. El token dura 30 días.
- Si algo falla, la respuesta trae `{ "mensaje": "..." }` con un texto listo para mostrar.
- Las cuentas suspendidas reciben un **403** y no pueden usar la app. Las de administrador entran solo por el panel web.

## Cuentas

| Método | Ruta | Envía | Devuelve |
|---|---|---|---|
| POST | `/registro` | `{ nombre, apellido, telefono, correo, clave }` | `{ ok }` |
| POST | `/login` | `{ correo, clave }` | `{ usuario, token }` |
| GET | `/yo` | — | usuario |
| PATCH | `/yo/rol` | `{ rol: 'usuario' \| 'negocio' }` | usuario |

`usuario` es `{ id, nombre, apellido, telefono, correo, rol }`. `rol` es `null` si la persona todavía no eligió en "¿Eres un?".

## Catálogos

| GET | `/modalidades` | `[{ id, nombre, descripcion }]` |
|---|---|---|
| GET | `/categorias` | `[{ id, nombre }]` |

## Mi negocio (dueño)

| Método | Ruta | Envía | Devuelve |
|---|---|---|---|
| GET | `/yo/negocio` | — | negocio o `null` |
| POST | `/yo/negocio` | `{ tipo: 'fijo' \| 'ambulante' }` | negocio (lo crea o cambia su tipo) |
| PUT | `/yo/negocio` | negocio completo | negocio |
| PUT | `/yo/negocio/modalidades` | `{ ids: ['1','2'] }` | `{ ok }` |
| GET | `/yo/negocio/pedidos` | — | pedidos recibidos |

`negocio` es `{ id, propietarioId, tipo, nombre, descripcion, telefono, direccion, latitud, longitud, ubicacionActualizada, logoUrl, bannerUrl, estado, motivoSuspension }`. `estado` puede ser `'activo'` o `'suspendido'`. Si el negocio está suspendido, el dueño no puede hacer cambios.

## Negocios y productos

| Método | Ruta | Devuelve |
|---|---|---|
| GET | `/negocios` | negocios del Marketplace (activos, con nombre y ubicación) |
| GET | `/negocios/:id` | negocio (si está suspendido, solo lo ve su dueño) |
| GET | `/negocios/:id/modalidades` | `['1','2']` |
| GET | `/negocios/:id/productos` | productos (el dueño también ve los que ocultó el administrador) |
| POST | `/productos` | crea `{ categoriaId, nombre, descripcion, precio, imagenUrl, stock, disponible }` |
| PUT | `/productos/:id` | edita (mismo cuerpo) |
| DELETE | `/productos/:id` | lo desactiva (se conserva por los pedidos viejos) |

## Imágenes

| Método | Ruta | Envía | Devuelve |
|---|---|---|---|
| POST | `/imagenes` | `{ mime: 'image/jpeg', base64 }` (máx. 5 MB) | `{ url }` |
| GET | `/api/imagenes/:id` | — (pública, sin token) | la imagen |

Las fotos se guardan en la tabla `imagenes` (ver `database/04_imagenes.sql`). La `url` que devuelve es la que se guarda en `logoUrl`, `bannerUrl` o `imagenUrl`.

## Pedidos

| Método | Ruta | Envía | Devuelve |
|---|---|---|---|
| GET | `/yo/pedidos` | — | pedidos que hizo el usuario |
| POST | `/pedidos` | `{ negocioId, modalidadPagoId, detalles: [{ productoId, cantidad }] }` | pedido |
| POST | `/pedidos/:id/cancelar` | — | pedido (solo si sigue pendiente) |
| PATCH | `/pedidos/:id/estado` | `{ estado, motivo }` | pedido (lo usa el negocio) |

- El precio y el nombre de cada producto los pone la API desde la base, no la app.
- Flujo de estados: `pendiente → aceptado → en_preparacion → listo → entregado`.
- Desvíos posibles: `rechazado` (desde pendiente) y `cancelado` (desde un pedido en curso). Los dos piden motivo.
- Al **aceptar** un pedido se descuentan las unidades del inventario.

## Chat

| Método | Ruta | Envía | Devuelve |
|---|---|---|---|
| GET | `/yo/conversaciones` | — | chats del usuario |
| POST | `/conversaciones` | `{ negocioId }` | conversación (la crea si no existe) |
| GET | `/conversaciones/:id/mensajes?despues=<idMensaje>` | — | mensajes (solo los nuevos si se pasa `despues`) |
| POST | `/conversaciones/:id/mensajes` | `{ texto }` | mensaje |

La app revisa si hay mensajes nuevos cada 3 segundos mientras el chat está abierto.
