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
const { pool } = require('./db');

const app = express();
app.use(express.json({ limit: '100kb' }));

// ---------- CORS: desde qué páginas se puede usar la API ----------
const permitidos = (process.env.CORS_ORIGIN || '').split(',').map((s) => s.trim()).filter(Boolean);
app.use(cors({
  origin(origen, listo) {
    // Sin origen = herramientas como Postman o curl.
    if (!origen || permitidos.includes(origen)) return listo(null, true);
    listo(new Error('Origen no permitido: ' + origen));
  },
}));

// ---------- Rutas ----------

// Para revisar que la API y la base de datos responden.
app.get('/api/salud', async (req, res) => {
  try {
    await pool.query('select 1');
    res.json({ ok: true, baseDeDatos: 'conectada' });
  } catch {
    res.status(500).json({ ok: false, baseDeDatos: 'sin conexión' });
  }
});

app.post('/api/admin/login', (req, res, next) => login(req, res).catch(next));
app.use('/api/admin', rutasAdmin);

app.use((req, res) => res.status(404).json({ mensaje: 'Ruta no encontrada.' }));

// ---------- Errores ----------
app.use((error, req, res, next) => { // eslint-disable-line no-unused-vars
  if (error.estado) return res.status(error.estado).json({ mensaje: error.message });
  // Errores lanzados por las funciones de la base de datos (raise exception)
  if (error.code === 'P0001') return res.status(400).json({ mensaje: error.message });
  if (String(error.message).startsWith('Origen no permitido')) return res.status(403).json({ mensaje: error.message });
  console.error(error);
  res.status(500).json({ mensaje: 'Ocurrió un error en el servidor. Intenta de nuevo.' });
});

const puerto = process.env.PORT || 3000;
app.listen(puerto, () => console.log(`API lista en http://localhost:${puerto}/api`));
