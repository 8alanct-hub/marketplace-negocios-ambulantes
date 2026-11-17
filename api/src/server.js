// =========================================================
//  API del Ecosistema para negocios
//  Conecta el panel web (y más adelante la app) con la base de
//  datos en Supabase. Todas las rutas empiezan por /api.
// =========================================================
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { login } = require('./auth');
const rutasAdmin = require('./rutas/admin');
const rutasApp = require('./rutas/app');
const { pool, consultar } = require('./db');

const app = express();
// Render pasa las peticiones por un proxy: así req.protocol es "https".
app.set('trust proxy', 1);

// JSON pequeño para todo, menos la subida de imágenes (tiene su propio límite).
const jsonNormal = express.json({ limit: '100kb' });
app.use((req, res, next) => (req.path === '/api/app/imagenes' ? next() : jsonNormal(req, res, next)));

// ---------- CORS: desde qué páginas se puede usar la API ----------
const permitidos = (process.env.CORS_ORIGIN || '').split(',').map((s) => s.trim()).filter(Boolean);
app.use(cors({
  origin(origen, listo) {
    // Sin origen = herramientas como Postman o curl.
    // localhost con cualquier puerto: la app de Flutter abierta en Chrome (flutter run -d chrome).
    const esLocal = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origen || '');
    if (!origen || esLocal || permitidos.includes(origen)) return listo(null, true);
    listo(new Error('Origen no permitido: ' + origen));
  },
}));

// ---------- Rutas ----------

// Para revisar que la API y la base de datos responden.
app.get('/api/salud', async (req, res) => {
  try {
    await pool.query('select 1');
    res.json({ ok: true, baseDeDatos: 'conectada' });
  } catch (error) {
    // El motivo exacto queda en los Logs (Render → Logs), no se muestra en la web.
    console.error('Sin conexión a la base de datos:', error.message);
    res.status(500).json({ ok: false, baseDeDatos: 'sin conexión' });
  }
});

app.post('/api/admin/login', (req, res, next) => login(req, res).catch(next));
app.use('/api/admin', rutasAdmin);
app.use('/api/app', rutasApp);

// Imágenes públicas (portadas, logos y fotos de productos). No piden sesión
// porque la app las muestra con Image.network.
app.get('/api/imagenes/:id', async (req, res, next) => {
  try {
    if (!/^[0-9a-f-]{36}$/i.test(req.params.id)) return res.status(404).json({ mensaje: 'Imagen no encontrada.' });
    const [imagen] = await consultar('select tipo_mime, datos from public.imagenes where id_imagen = $1', [req.params.id]);
    if (!imagen) return res.status(404).json({ mensaje: 'Imagen no encontrada.' });
    res.set('Content-Type', imagen.tipo_mime);
    res.set('Cache-Control', 'public, max-age=31536000, immutable'); // nunca cambian
    res.send(imagen.datos);
  } catch (error) {
    next(error);
  }
});

app.use((req, res) => res.status(404).json({ mensaje: 'Ruta no encontrada.' }));

// ---------- Errores ----------
app.use((error, req, res, next) => { // eslint-disable-line no-unused-vars
  if (error.estado) return res.status(error.estado).json({ mensaje: error.message });
  // Errores lanzados por las funciones de la base de datos (raise exception)
  if (error.code === 'P0001') return res.status(400).json({ mensaje: error.message });
  // Datos que no cumplen las reglas de la base (correo mal escrito, categoría que no existe...)
  if (error.code === '23514' || error.code === '23503' || error.code === '22P02') {
    return res.status(400).json({ mensaje: 'Revisa los datos e intenta de nuevo.' });
  }
  if (error.type === 'entity.too.large') return res.status(413).json({ mensaje: 'El archivo es muy grande.' });
  if (error.type === 'entity.parse.failed') return res.status(400).json({ mensaje: 'Datos no válidos.' });
  if (String(error.message).startsWith('Origen no permitido')) return res.status(403).json({ mensaje: error.message });
  console.error(error);
  res.status(500).json({ mensaje: 'Ocurrió un error en el servidor. Intenta de nuevo.' });
});

const puerto = process.env.PORT || 3000;
app.listen(puerto, () => console.log(`API lista en http://localhost:${puerto}/api`));
