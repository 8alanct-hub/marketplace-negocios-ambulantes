// Conexión a la base de datos (PostgreSQL en Supabase).
// La cadena de conexión viene de la variable DATABASE_URL; nunca se escribe aquí.
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  console.error('Falta la variable DATABASE_URL (ver .env.example).');
  process.exit(1);
}

const esLocal = /localhost|127\.0\.0\.1|host=\/tmp/.test(process.env.DATABASE_URL);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Supabase exige conexión cifrada.
  ssl: esLocal ? false : { rejectUnauthorized: false },
  max: 5,
});

/** Ejecuta una consulta y devuelve las filas. */
async function consultar(sql, parametros = []) {
  const resultado = await pool.query(sql, parametros);
  return resultado.rows;
}

/** Ejecuta varias consultas en una sola transacción (todo o nada). */
async function transaccion(trabajo) {
  const cliente = await pool.connect();
  try {
    await cliente.query('begin');
    const resultado = await trabajo((sql, parametros = []) => cliente.query(sql, parametros).then((r) => r.rows));
    await cliente.query('commit');
    return resultado;
  } catch (error) {
    await cliente.query('rollback');
    throw error;
  } finally {
    cliente.release();
  }
}

module.exports = { pool, consultar, transaccion };
