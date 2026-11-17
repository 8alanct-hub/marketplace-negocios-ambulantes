# API que necesita el panel de administración

Guía para conectar la web con la base de datos.
La web **ya está lista**: solo hay que poner la dirección de la API en `js/config.js`:

```js
const CONFIG = {
  API_URL: 'https://mi-api.ejemplo.com/api',   // sin "/" al final
};
```

Con `API_URL` vacío la web funciona en **modo prueba** (datos de prueba en el navegador).
Todo lo que habla con la API está en **`js/datos.js`** (objeto `Datos`). Las pantallas no hacen `fetch` directamente.

---

## Reglas generales

- Todo es **JSON** (`Content-Type: application/json`).
- Después del login, la web envía el token en cada petición:
  `Authorization: Bearer <token>`
- Si el token no es válido o venció → responder **401**. La web cierra la sesión y vuelve al login.
- Si algo falla → responder un código 4xx/5xx con `{ "mensaje": "Texto que verá el administrador" }`.
- Solo cuentas con **rol administrador** pueden usar estas rutas (validarlo en el servidor).
- **CORS**: la API debe permitir el origen donde se publique la web
  (por ejemplo `https://USUARIO.github.io`).
- Las fechas se muestran tal como llegan: enviarlas ya formateadas como `dd/mm/aaaa`
  (y la hora como `10:42 a. m.`), o ajustar el formato en `js/datos.js`.

---

## 1. Inicio de sesión

### `POST /admin/login`

Envía:
```json
{ "correo": "admin@test.com", "clave": "Prueba123" }
```
Responde 200:
```json
{ "nombre": "Andrés Mejía", "correo": "admin@test.com", "token": "eyJhbGciOi..." }
```
Si no coincide o no es administrador → **401** con `{ "mensaje": "Correo o contraseña incorrectos." }`.
La contraseña se compara contra el hash guardado (`password_hash`), nunca en texto plano.

---

## 2. Listas (GET)

La web pide las cuatro listas al cargar cada pantalla. Los nombres de los campos deben ser **exactamente** estos.

### `GET /admin/usuarios` → arreglo de usuarios (sin administradores)
```json
[
  {
    "id": "u_31",
    "nombre": "Laura Pérez",
    "correo": "laura@test.com",
    "telefono": "311 222 3344",
    "rol": "Cliente",               // "Cliente" | "Negocio"
    "registro": "30/10/2026",
    "estado": "Suspendido",         // "Activo" | "Suspendido"
    "pedidos": 4,                   // solo clientes: cantidad de pedidos
    "negocioId": null,              // solo dueños: id de su negocio
    "motivo": "Comentarios ofensivos en el chat con negocios.",  // si está suspendido
    "cuando": "13/11/2026 · por Andrés Mejía"                    // si está suspendido
  }
]
```

### `GET /admin/negocios`
```json
[
  {
    "id": "n_5",
    "nombre": "Artesanías Mompox",
    "tipo": "fijo",                 // "fijo" | "ambulante"
    "descripcion": "Filigrana, mochilas y sombreros hechos a mano",
    "duenoId": "u_23",
    "lugar": "Calle de las Damas # 3-21, Centro",   // dirección (fijo) o "Actualizada hace 25 min" (ambulante)
    "registro": "04/10/2026",
    "estado": "Suspendido",         // "Activo" | "Suspendido"
    "motivo": "Fotos de productos que no corresponden a lo que vende.",
    "cuando": "13/11/2026 · por Andrés Mejía"
  }
]
```

### `GET /admin/reportes` (más recientes primero)
Quejas sobre un **negocio** (servicio o comportamiento).
```json
[
  {
    "id": "REP-004",
    "negocioId": "n_2",
    "usuarioId": "u_30",            // quién reportó
    "motivo": "Información incorrecta",
    "descripcion": "La ubicación que muestra la app no es la real...",
    "fecha": "14/11/2026",
    "hora": "10:42 a. m.",
    "estado": "Pendiente",          // "Pendiente" | "En revisión" | "Resuelto" | "Descartado" | "Enviado a Moderación"
    "origen": "Un cliente desde la app",   // o "Enviado desde Moderación (MOD-002)"
    "nota": "",                     // nota interna del administrador
    "cierre": ""                    // ej. "Resuelto el 15/11/2026 por Andrés Mejía."
  }
]
```

### `GET /admin/moderacion` (más recientes primero)
Un **contenido** puntual: foto, producto o descripción.
```json
[
  {
    "id": "MOD-003",
    "tipo": "Foto de producto",     // "Foto de producto" | "Producto" | "Descripción del negocio" | "Contenido del negocio"
    "negocioId": "n_5",
    "usuarioId": "u_1",
    "titulo": "Sombrero vueltiao",  // si es foto/producto
    "precio": "$ 180.000",          // si es foto/producto
    "fotoUrl": "https://...",       // si es foto (opcional)
    "texto": "",                    // si es una descripción o texto
    "motivo": "La foto no corresponde al producto",
    "fecha": "13/11/2026",
    "estado": "Por revisar",        // "Por revisar" | "Mantenido" | "Quitado" | "Enviado a Reportes"
    "origen": "Enviado desde Reportes (REP-003)",
    "mensaje": "La foto del producto ... no corresponde ...",   // mensaje sugerido para el dueño
    "cierre": ""
  }
]
```

---

## 3. Acciones

Cada acción responde **200** con el elemento actualizado (o `{}`); la web vuelve a pedir las listas.
El servidor guarda **quién** y **cuándo** (el administrador del token y la fecha actual) y arma `cierre` / `cuando`.

| Acción en la web | Petición | Cuerpo |
|---|---|---|
| Suspender usuario | `PATCH /admin/usuarios/{id}` | `{ "estado": "Suspendido", "motivo": "..." }` |
| Reactivar usuario | `PATCH /admin/usuarios/{id}` | `{ "estado": "Activo" }` |
| Suspender negocio (desde Reportes) | `PATCH /admin/negocios/{id}` | `{ "estado": "Suspendido", "motivo": "..." }` |
| Reactivar negocio | `PATCH /admin/negocios/{id}` | `{ "estado": "Activo" }` |
| Resolver / Descartar / En revisión / Reabrir reporte | `PATCH /admin/reportes/{id}` | `{ "estado": "Resuelto" }` (o `"Descartado"`, `"En revisión"`, `"Pendiente"`) |
| Guardar nota interna | `PATCH /admin/reportes/{id}` | `{ "nota": "..." }` |
| Enviar reporte a Moderación | `POST /admin/reportes/{id}/enviar-a-moderacion` | — → responde `{ "id": "MOD-005" }` |
| Mantener / Volver a revisar contenido | `PATCH /admin/moderacion/{id}` | `{ "estado": "Mantenido" }` (o `"Por revisar"`) |
| Quitar contenido | `PATCH /admin/moderacion/{id}` | `{ "estado": "Quitado", "mensaje": "Texto para el dueño" }` |
| Enviar contenido a Reportes | `POST /admin/moderacion/{id}/enviar-a-reportes` | — → responde `{ "id": "REP-005" }` |

### Lo que debe pasar en la app cuando el administrador actúa

- **Usuario suspendido** → no puede iniciar sesión en la app.
- **Negocio suspendido** → no aparece en el Marketplace ni recibe pedidos; el dueño ve «Suspendido» en *Mi cuenta*.
- **Contenido quitado** → deja de verse (foto/producto oculto o descripción vacía) y el dueño recibe el `mensaje`.
- **Enviar a Moderación** → se crea un registro en `moderacion` con `origen = "Enviado desde Reportes (REP-...)"` y el reporte queda `Enviado a Moderación`.
- **Enviar a Reportes** → se crea un registro en `reportes` con `origen = "Enviado desde Moderación (MOD-...)"` y el contenido queda `Enviado a Reportes` (sigue publicado).

---

## 4. Base de datos

La base de datos **ya está creada en Supabase (PostgreSQL)**. Los scripts y la guía están en la
carpeta [`database/`](../database/README.md) del repositorio.

Las vistas `v_admin_usuarios`, `v_admin_negocios`, `v_admin_reportes` y `v_admin_moderacion`
devuelven exactamente el JSON de la sección 2, así que cada `GET` es un `select * from` la vista.
Los botones «Enviar a…» usan las funciones `admin_enviar_reporte_a_moderacion` y
`admin_enviar_contenido_a_reportes`, y el login usa `verificar_login`.
