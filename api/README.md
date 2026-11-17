# API del Ecosistema para negocios

API en **Node.js + Express** que conecta el panel web de administración (`../admin-web`) con la base de datos PostgreSQL en **Supabase** (`../database`). Más adelante también la usará la app de Flutter.

```
admin-web  ──fetch + token──▶  API (este proyecto)  ──pg──▶  Supabase (PostgreSQL)
```

La web **nunca** se conecta directo a la base de datos: la contraseña de la base solo vive en las variables de entorno de la API.

## Estructura

| Archivo | Qué hace |
|---|---|
| `src/server.js` | Arranca Express, CORS, rutas y manejo de errores |
| `src/db.js` | Conexión a la base (`DATABASE_URL`) y ayudas `consultar` / `transaccion` |
| `src/auth.js` | `POST /api/admin/login` y el middleware `soloAdmin` (token JWT de 8 h) |
| `src/rutas/admin.js` | Rutas del panel (ver `../admin-web/API.md`) |
| `.env.example` | Variables que necesita la API (copiar a `.env`) |

## Rutas

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/salud` | Revisa que la API y la base respondan |
| POST | `/api/admin/login` | `{ correo, clave }` → `{ nombre, correo, token }` |
| GET | `/api/admin/usuarios` · `negocios` · `reportes` · `moderacion` | Listas del panel |
| PATCH | `/api/admin/usuarios/:id` · `negocios/:id` | Suspender / reactivar |
| PATCH | `/api/admin/reportes/:id` | Cambiar estado o nota interna |
| POST | `/api/admin/reportes/:id/enviar-a-moderacion` | Crea un caso MOD-00X |
| PATCH | `/api/admin/moderacion/:id` | Mantener / quitar / volver a revisar |
| POST | `/api/admin/moderacion/:id/enviar-a-reportes` | Crea un reporte REP-00X |

Todas las rutas `/api/admin/*` (menos el login) piden el encabezado `Authorization: Bearer <token>`.

## Probarla en tu computador

Necesitas **Node.js 18 o más nuevo** (`node -v`).

1. En una terminal, dentro de esta carpeta `api`:
   ```
   npm install
   ```
2. Copia `.env.example` y renómbralo a `.env`. Llena:
   - `DATABASE_URL`: en Supabase → proyecto **marketplace_ambulante** → botón **Connect** → pestaña **Connection string** → **Session pooler**. Copia la URI y cambia `[YOUR-PASSWORD]` por la contraseña de la base de datos.
   - `JWT_SECRET`: una frase larga inventada (por ejemplo 40 letras y números al azar).
   - `CORS_ORIGIN`: déjalo como está.
3. Arranca:
   ```
   npm run dev
   ```
4. Abre `http://localhost:3000/api/salud`. Debe decir `{"ok":true,"baseDeDatos":"conectada"}`.
5. En `admin-web/js/config.js` pon `API_URL: 'http://localhost:3000/api'` y abre la web con Live Server (puerto 5500). Entra con `admin@test.com` / `Prueba123`.

> El archivo `.env` **no se sube a GitHub** (está en `.gitignore`). Si alguna vez lo subes por error, cambia la contraseña de la base en Supabase.

## Publicarla en internet (Render, gratis)

1. Entra a <https://render.com> con tu cuenta de GitHub.
2. **New → Web Service** → elige el repositorio `marketplace-negocios-ambulantes`.
3. Configura:
   - **Root Directory:** `api`
   - **Runtime:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance type:** Free
4. En **Environment Variables** agrega las mismas tres de tu `.env`: `DATABASE_URL`, `JWT_SECRET`, `CORS_ORIGIN` (no hace falta `PORT`, Render lo pone solo).
5. **Create Web Service**. Cuando termine, Render te da una dirección como `https://ecosistema-api.onrender.com`. Revisa `https://…onrender.com/api/salud`.
6. En `admin-web/js/config.js` cambia:
   ```js
   API_URL: 'https://ecosistema-api.onrender.com/api',
   ```
   y haz commit + push. GitHub Pages se actualiza en un par de minutos.

> En el plan gratis, Render "duerme" la API si nadie la usa por 15 minutos; la primera petición después tarda unos 30–50 segundos. Es normal.

## Seguridad

- La contraseña se compara dentro de la base (bcrypt); la API nunca la ve guardada.
- Solo usuarios con rol `admin` y estado `activo` pueden entrar al panel.
- Los administradores no se pueden suspender desde el panel.
- CORS solo deja usar la API desde las páginas listadas en `CORS_ORIGIN`.
- Las tablas tienen RLS activado sin políticas: nadie entra con las claves públicas de Supabase, solo la API.
