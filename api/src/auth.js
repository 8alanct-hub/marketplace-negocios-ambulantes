// Inicio de sesión del administrador y protección de las rutas con un token (JWT).
const jwt = require('jsonwebtoken');
const { consultar } = require('./db');

if (!process.env.JWT_SECRET) {
  console.error('Falta la variable JWT_SECRET (ver .env.example).');
  process.exit(1);
}

const DURACION_SESION = '8h';

/** POST /admin/login  { correo, clave } → { nombre, correo, token } */
async function login(req, res) {
  const { correo, clave } = req.body || {};
  if (!correo || !clave) {
    return res.status(400).json({ mensaje: 'Escribe tu correo y tu contraseña.' });
  }

  // La contraseña se compara dentro de la base de datos (bcrypt), nunca aquí.
  const [usuario] = await consultar('select * from public.verificar_login($1, $2)', [correo, clave]);

  // Mismo mensaje para "no existe", "contraseña mala" o "no es admin": no se revela nada.
  if (!usuario || usuario.rol !== 'admin') {
    return res.status(401).json({ mensaje: 'Correo o contraseña incorrectos.' });
  }
  if (usuario.estado !== 'activo') {
    return res.status(403).json({ mensaje: 'Esta cuenta está suspendida.' });
  }

  const token = jwt.sign({ id: usuario.id_usuario, rol: 'admin' }, process.env.JWT_SECRET, { expiresIn: DURACION_SESION });
  res.json({ nombre: `${usuario.nombre} ${usuario.apellido}`, correo: usuario.correo, token });
}

/** Middleware: solo deja pasar si trae un token válido de administrador. */
function soloAdmin(req, res, next) {
  const encabezado = req.get('Authorization') || '';
  const token = encabezado.startsWith('Bearer ') ? encabezado.slice(7) : null;
  if (!token) return res.status(401).json({ mensaje: 'Inicia sesión.' });

  try {
    const datos = jwt.verify(token, process.env.JWT_SECRET);
    if (datos.rol !== 'admin') return res.status(403).json({ mensaje: 'No tienes permiso.' });
    req.adminId = datos.id; // lo usan las rutas para guardar quién hizo cada cambio
    next();
  } catch {
    res.status(401).json({ mensaje: 'La sesión expiró. Inicia sesión de nuevo.' });
  }
}

module.exports = { login, soloAdmin };
