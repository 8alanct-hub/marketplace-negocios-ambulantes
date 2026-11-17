// =========================================================
//  Rutas de la app móvil (Flutter). Todas empiezan por /api/app.
//  Ver API_APP.md para la lista completa y lo que devuelve cada una.
//
//  Los ids viajan como texto ("7") y las fechas en formato ISO.
//  Los estados de pedido viajan como en la base: 'pendiente',
//  'en_preparacion', ... (la app los convierte a su enum).
// =========================================================
const express = require('express');
const jwt = require('jsonwebtoken');
const { consultar, transaccion } = require('../db');

const router = express.Router();
const DURACION_SESION = '30d';

// ---------- Ayudas ----------

function fallo(estado, mensaje) {
  const e = new Error(mensaje);
  e.estado = estado;
  return e;
}

/** Envuelve las rutas async para mandar los errores al manejador de errores. */
const ruta = (fn) => (req, res, next) => fn(req, res).catch(next);

/** "7" → 7. Lanza 400 si no es un id válido. */
function idDe(valor) {
  const n = Number(valor);
  if (!Number.isInteger(n) || n <= 0) throw fallo(400, 'Identificador no válido.');
  return n;
}

const texto = (v) => (v === undefined || v === null ? '' : String(v).trim());
const num = (v) => (v === null || v === undefined ? null : Number(v));
const iso = (f) => (f ? new Date(f).toISOString() : null);

// Rol en la base ↔ rol en la app
const ROL_APP = { cliente: 'usuario', negocio: 'negocio' };
const ROL_BD = { usuario: 'cliente', negocio: 'negocio' };

// ---------- Convertir filas de la base al JSON de la app ----------

function usuarioJson(u) {
  return {
    id: String(u.id_usuario),
    nombre: u.nombre,
    apellido: u.apellido,
    telefono: u.telefono || '',
    correo: u.correo,
    rol: u.rol ? ROL_APP[u.rol] || null : null,
  };
}

function negocioJson(n) {
  return {
    id: String(n.id_negocio),
    propietarioId: String(n.id_usuario),
    tipo: n.tipo,
    nombre: n.nombre_comercial,
    descripcion: n.descripcion,
    telefono: n.telefono,
    direccion: n.direccion,
    latitud: num(n.latitud),
    longitud: num(n.longitud),
    ubicacionActualizada: iso(n.ubicacion_actualizada),
    logoUrl: n.logo_url,
    bannerUrl: n.banner_url,
    estado: n.estado,
    motivoSuspension: n.motivo_suspension,
  };
}

function productoJson(p) {
  return {
    id: String(p.id_producto),
    negocioId: String(p.id_negocio),
    categoriaId: p.id_categoria ? String(p.id_categoria) : '',
    nombre: p.nombre,
    descripcion: p.descripcion,
    precio: Number(p.precio),
    imagenUrl: p.oculto_por_moderacion ? null : p.imagen_url,
    stock: p.stock,
    disponible: p.disponible,
    ocultoPorModeracion: p.oculto_por_moderacion,
  };
}

// ---------- Sesión de la app (token JWT) ----------

function crearToken(idUsuario) {
  return jwt.sign({ id: idUsuario, tipo: 'app' }, process.env.JWT_SECRET, { expiresIn: DURACION_SESION });
}

/**
 * Middleware: exige un token de la app y que la cuenta siga activa.
 * Deja el usuario en req.usuario (fila de la tabla usuarios).
 */
async function conSesion(req, res, next) {
  try {
    const encabezado = req.get('Authorization') || '';
    const token = encabezado.startsWith('Bearer ') ? encabezado.slice(7) : null;
    if (!token) throw fallo(401, 'Inicia sesión.');

    let datos;
    try {
      datos = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      throw fallo(401, 'Tu sesión expiró. Inicia sesión de nuevo.');
    }
    if (datos.tipo !== 'app') throw fallo(401, 'Inicia sesión.');

    const [usuario] = await consultar('select * from public.usuarios where id_usuario = $1', [datos.id]);
    if (!usuario) throw fallo(401, 'No encontramos tu cuenta. Inicia sesión de nuevo.');
    if (usuario.estado !== 'activo') throw fallo(403, 'Tu cuenta está suspendida. Escríbenos si crees que es un error.');
    req.usuario = usuario;
    next();
  } catch (error) {
    next(error);
  }
}

/** Negocio del usuario con sesión (o error si no tiene). */
async function miNegocio(req) {
  const [negocio] = await consultar('select * from public.negocios where id_usuario = $1', [req.usuario.id_usuario]);
  if (!negocio) throw fallo(404, 'Aún no has creado tu negocio.');
  return negocio;
}

/** Revisa que el negocio del dueño no esté suspendido antes de cambiar algo. */
function exigirNegocioActivo(negocio) {
  if (negocio.estado !== 'activo') {
    throw fallo(403, 'Tu negocio está suspendido. Mientras tanto no puedes hacer cambios.');
  }
}

// =========================================================
//  CUENTAS
// =========================================================

// Crear cuenta. No inicia sesión (la app luego llama a /login).
router.post('/registro', ruta(async (req, res) => {
  const { nombre, apellido, telefono, correo, clave } = req.body || {};
  if (!texto(nombre) || !texto(apellido) || !texto(correo) || !clave) {
    throw fallo(400, 'Completa todos los campos.');
  }
  await consultar('select public.registrar_usuario($1, $2, $3, $4, $5)', [nombre, apellido, texto(telefono), correo, String(clave)]);
  res.status(201).json({ ok: true });
}));

// Iniciar sesión → { usuario, token }
router.post('/login', ruta(async (req, res) => {
  const { correo, clave } = req.body || {};
  if (!texto(correo) || !clave) throw fallo(400, 'Escribe tu correo y tu contraseña.');

  const [encontrado] = await consultar('select * from public.verificar_login($1, $2)', [correo, String(clave)]);
  if (!encontrado) throw fallo(401, 'Correo o contraseña incorrectos.');
  if (encontrado.rol === 'admin') throw fallo(403, 'Esta es una cuenta de administrador: entra por el panel web.');
  if (encontrado.estado !== 'activo') throw fallo(403, 'Tu cuenta está suspendida. Escríbenos si crees que es un error.');

  const [usuario] = await consultar('select * from public.usuarios where id_usuario = $1', [encontrado.id_usuario]);
  res.json({ usuario: usuarioJson(usuario), token: crearToken(usuario.id_usuario) });
}));

// A partir de aquí, todo pide sesión.
router.use(conSesion);

router.get('/yo', ruta(async (req, res) => res.json(usuarioJson(req.usuario))));

// Guardar el rol elegido en "¿Eres un?"  { rol: 'usuario' | 'negocio' }
router.patch('/yo/rol', ruta(async (req, res) => {
  const rol = ROL_BD[req.body?.rol];
  if (!rol) throw fallo(400, 'Rol no válido.');
  const [usuario] = await consultar(
    'update public.usuarios set rol = $2 where id_usuario = $1 returning *',
    [req.usuario.id_usuario, rol],
  );
  res.json(usuarioJson(usuario));
}));

// =========================================================
//  CATÁLOGOS
// =========================================================

router.get('/modalidades', ruta(async (req, res) => {
  const filas = await consultar('select * from public.modalidades_pago where activa order by id_modalidad');
  res.json(filas.map((m) => ({ id: String(m.id_modalidad), nombre: m.nombre, descripcion: m.descripcion })));
}));

router.get('/categorias', ruta(async (req, res) => {
  const filas = await consultar('select * from public.categorias where activa order by id_categoria');
  res.json(filas.map((c) => ({ id: String(c.id_categoria), nombre: c.nombre })));
}));

// =========================================================
//  MI NEGOCIO (dueño)
// =========================================================

// Negocio del usuario, o null si todavía no tiene.
router.get('/yo/negocio', ruta(async (req, res) => {
  const [negocio] = await consultar('select * from public.negocios where id_usuario = $1', [req.usuario.id_usuario]);
  res.json(negocio ? negocioJson(negocio) : null);
}));

// Crea el negocio (o cambia su tipo si ya existe).  { tipo: 'fijo' | 'ambulante' }
router.post('/yo/negocio', ruta(async (req, res) => {
  const tipo = req.body?.tipo;
  if (!['fijo', 'ambulante'].includes(tipo)) throw fallo(400, 'Tipo de negocio no válido.');
  const [negocio] = await consultar(
    `insert into public.negocios (id_usuario, tipo) values ($1, $2)
     on conflict (id_usuario) do update set tipo = excluded.tipo
     returning *`,
    [req.usuario.id_usuario, tipo],
  );
  res.json(negocioJson(negocio));
}));

// Guarda los datos del negocio.
router.put('/yo/negocio', ruta(async (req, res) => {
  const actual = await miNegocio(req);
  exigirNegocioActivo(actual);
  const b = req.body || {};
  if (!['fijo', 'ambulante'].includes(b.tipo)) throw fallo(400, 'Tipo de negocio no válido.');

  const lat = b.latitud === null || b.latitud === undefined ? null : Number(b.latitud);
  const lng = b.longitud === null || b.longitud === undefined ? null : Number(b.longitud);
  if ((lat === null) !== (lng === null) || (lat !== null && (!Number.isFinite(lat) || !Number.isFinite(lng)))) {
    throw fallo(400, 'Ubicación no válida.');
  }

  const [negocio] = await consultar(
    `update public.negocios
        set tipo = $2, nombre_comercial = $3, descripcion = $4, telefono = $5, direccion = $6,
            latitud = $7, longitud = $8, ubicacion_actualizada = $9,
            logo_url = $10, banner_url = $11
      where id_negocio = $1
      returning *`,
    [
      actual.id_negocio, b.tipo, texto(b.nombre), texto(b.descripcion), texto(b.telefono),
      b.tipo === 'fijo' ? texto(b.direccion) : '',
      lat, lng, b.ubicacionActualizada ? new Date(b.ubicacionActualizada) : null,
      b.logoUrl || null, b.bannerUrl || null,
    ],
  );
  res.json(negocioJson(negocio));
}));

// Formas de pago del negocio.  { ids: ['1', '2'] }
router.put('/yo/negocio/modalidades', ruta(async (req, res) => {
  const negocio = await miNegocio(req);
  exigirNegocioActivo(negocio);
  const ids = Array.isArray(req.body?.ids) ? req.body.ids.map(idDe) : [];
  if (!ids.length) throw fallo(400, 'Elige al menos una forma de pago.');

  await transaccion(async (q) => {
    await q('delete from public.negocio_modalidad_pago where id_negocio = $1', [negocio.id_negocio]);
    await q(
      `insert into public.negocio_modalidad_pago (id_negocio, id_modalidad)
       select $1, unnest($2::smallint[])`,
      [negocio.id_negocio, ids],
    );
  });
  res.json({ ok: true });
}));

// =========================================================
//  NEGOCIOS (lo que ve el cliente)
// =========================================================

// Marketplace: negocios activos con nombre y ubicación.
router.get('/negocios', ruta(async (req, res) => {
  const filas = await consultar('select * from public.v_negocios_publicados order by nombre_comercial');
  res.json(filas.map(negocioJson));
}));

/** Busca un negocio. Un negocio suspendido solo lo ve su dueño. */
async function negocioVisible(req, idTexto) {
  const [negocio] = await consultar(
    `select n.* from public.negocios n
       join public.usuarios u on u.id_usuario = n.id_usuario
      where n.id_negocio = $1
        and (n.id_usuario = $2 or (n.estado = 'activo' and u.estado = 'activo'))`,
    [idDe(idTexto), req.usuario.id_usuario],
  );
  return negocio || null;
}

router.get('/negocios/:id', ruta(async (req, res) => {
  const negocio = await negocioVisible(req, req.params.id);
  if (!negocio) throw fallo(404, 'Este negocio ya no está disponible.');
  res.json(negocioJson(negocio));
}));

router.get('/negocios/:id/modalidades', ruta(async (req, res) => {
  const negocio = await negocioVisible(req, req.params.id);
  if (!negocio) throw fallo(404, 'Este negocio ya no está disponible.');
  const filas = await consultar('select id_modalidad from public.negocio_modalidad_pago where id_negocio = $1', [negocio.id_negocio]);
  res.json(filas.map((f) => String(f.id_modalidad)));
}));

// Productos de un negocio. El dueño también ve los que el administrador ocultó.
router.get('/negocios/:id/productos', ruta(async (req, res) => {
  const negocio = await negocioVisible(req, req.params.id);
  if (!negocio) throw fallo(404, 'Este negocio ya no está disponible.');
  const esDueno = negocio.id_usuario === req.usuario.id_usuario;
  const filas = await consultar(
    `select * from public.productos
      where id_negocio = $1 and activo and ($2 or not oculto_por_moderacion)
      order by id_producto`,
    [negocio.id_negocio, esDueno],
  );
  res.json(filas.map(productoJson));
}));

// =========================================================
//  PRODUCTOS (dueño)
// =========================================================

function datosProducto(b) {
  const nombre = texto(b.nombre);
  const precio = Number(b.precio);
  const stock = Number(b.stock);
  if (!nombre) throw fallo(400, 'Escribe el nombre del producto.');
  if (!Number.isFinite(precio) || precio < 0) throw fallo(400, 'Precio no válido.');
  if (!Number.isInteger(stock) || stock < 0) throw fallo(400, 'Cantidad disponible no válida.');
  return [
    b.categoriaId ? idDe(b.categoriaId) : null,
    nombre, texto(b.descripcion), precio, b.imagenUrl || null, stock, b.disponible !== false,
  ];
}

router.post('/productos', ruta(async (req, res) => {
  const negocio = await miNegocio(req);
  exigirNegocioActivo(negocio);
  const [producto] = await consultar(
    `insert into public.productos (id_negocio, id_categoria, nombre, descripcion, precio, imagen_url, stock, disponible)
     values ($1, $2, $3, $4, $5, $6, $7, $8) returning *`,
    [negocio.id_negocio, ...datosProducto(req.body || {})],
  );
  res.status(201).json(productoJson(producto));
}));

router.put('/productos/:id', ruta(async (req, res) => {
  const negocio = await miNegocio(req);
  exigirNegocioActivo(negocio);
  const [actual] = await consultar(
    'select * from public.productos where id_producto = $1 and id_negocio = $2 and activo',
    [idDe(req.params.id), negocio.id_negocio],
  );
  if (!actual) throw fallo(404, 'No se encontró el producto.');

  const datos = datosProducto(req.body || {});
  // Si el administrador ocultó el producto y el dueño pone una foto nueva,
  // se vuelve a mostrar (el administrador puede volver a revisarlo).
  const fotoNueva = datos[4] && datos[4] !== actual.imagen_url;
  const [producto] = await consultar(
    `update public.productos
        set id_categoria = $2, nombre = $3, descripcion = $4, precio = $5, imagen_url = $6, stock = $7, disponible = $8,
            oculto_por_moderacion = oculto_por_moderacion and not $9
      where id_producto = $1 returning *`,
    [actual.id_producto, ...datos, Boolean(fotoNueva)],
  );
  res.json(productoJson(producto));
}));

// "Eliminar" = desactivar (se conserva por los pedidos que ya lo tienen).
router.delete('/productos/:id', ruta(async (req, res) => {
  const negocio = await miNegocio(req);
  const filas = await consultar(
    'update public.productos set activo = false where id_producto = $1 and id_negocio = $2 returning id_producto',
    [idDe(req.params.id), negocio.id_negocio],
  );
  if (!filas.length) throw fallo(404, 'No se encontró el producto.');
  res.json({ ok: true });
}));

// =========================================================
//  IMÁGENES (portada, logo y fotos de productos)
// =========================================================

const TIPOS_IMAGEN = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

// { mime: 'image/jpeg', base64: '...' } → { url }
router.post('/imagenes', express.json({ limit: '8mb' }), ruta(async (req, res) => {
  const { mime, base64 } = req.body || {};
  if (!TIPOS_IMAGEN.includes(mime)) throw fallo(400, 'Formato de imagen no permitido.');
  const datos = Buffer.from(String(base64 || ''), 'base64');
  if (!datos.length) throw fallo(400, 'La imagen está vacía.');
  if (datos.length > 5 * 1024 * 1024) throw fallo(400, 'La imagen pesa más de 5 MB.');

  const [fila] = await consultar(
    'insert into public.imagenes (id_usuario, tipo_mime, datos) values ($1, $2, $3) returning id_imagen',
    [req.usuario.id_usuario, mime, datos],
  );
  const base = `${req.protocol}://${req.get('host')}`;
  res.status(201).json({ url: `${base}/api/imagenes/${fila.id_imagen}` });
}));

// =========================================================
//  PEDIDOS
// =========================================================

const SELECT_PEDIDOS = `
  select p.*, u.nombre || ' ' || u.apellido as cliente_nombre, n.nombre_comercial as negocio_nombre,
         coalesce((select json_agg(json_build_object(
                     'productoId', d.id_producto::text, 'nombreProducto', pr.nombre,
                     'cantidad', d.cantidad, 'precioUnitario', d.precio_unitario) order by d.id_detalle)
                   from public.detalle_pedido d join public.productos pr on pr.id_producto = d.id_producto
                   where d.id_pedido = p.id_pedido), '[]') as detalles
    from public.pedidos p
    join public.usuarios u on u.id_usuario = p.id_usuario
    join public.negocios n on n.id_negocio = p.id_negocio`;

function pedidoJson(p) {
  return {
    id: String(p.id_pedido),
    usuarioId: String(p.id_usuario),
    clienteNombre: p.cliente_nombre,
    negocioId: String(p.id_negocio),
    negocioNombre: p.negocio_nombre,
    modalidadPagoId: String(p.id_modalidad),
    estado: p.estado,
    detalles: p.detalles.map((d) => ({ ...d, precioUnitario: Number(d.precioUnitario) })),
    total: Number(p.total),
    fechaCreacion: iso(p.fecha_creacion),
    fechaActualizacion: iso(p.fecha_actualizacion),
    motivo: p.motivo_cancelacion,
  };
}

async function pedidoPorId(id) {
  const [p] = await consultar(`${SELECT_PEDIDOS} where p.id_pedido = $1`, [id]);
  return p;
}

// Pedidos que hizo el usuario (más recientes primero).
router.get('/yo/pedidos', ruta(async (req, res) => {
  const filas = await consultar(`${SELECT_PEDIDOS} where p.id_usuario = $1 order by p.fecha_creacion desc`, [req.usuario.id_usuario]);
  res.json(filas.map(pedidoJson));
}));

// Pedidos que recibió mi negocio (más recientes primero).
router.get('/yo/negocio/pedidos', ruta(async (req, res) => {
  const negocio = await miNegocio(req);
  const filas = await consultar(`${SELECT_PEDIDOS} where p.id_negocio = $1 order by p.fecha_creacion desc`, [negocio.id_negocio]);
  res.json(filas.map(pedidoJson));
}));

// Crear pedido.  { negocioId, modalidadPagoId, detalles: [{ productoId, cantidad }] }
// El precio y el nombre se toman de la base (no se confía en lo que manda la app).
router.post('/pedidos', ruta(async (req, res) => {
  const b = req.body || {};
  const idNegocio = idDe(b.negocioId);
  const idModalidad = idDe(b.modalidadPagoId);
  const detalles = Array.isArray(b.detalles) ? b.detalles : [];
  if (!detalles.length) throw fallo(400, 'Agrega al menos un producto.');

  const idPedido = await transaccion(async (q) => {
    const [negocio] = await q(
      `select n.* from public.negocios n join public.usuarios u on u.id_usuario = n.id_usuario
        where n.id_negocio = $1 and n.estado = 'activo' and u.estado = 'activo'`,
      [idNegocio],
    );
    if (!negocio) throw fallo(400, 'Este negocio ya no está disponible.');
    if (negocio.id_usuario === req.usuario.id_usuario) throw fallo(400, 'No puedes hacerle un pedido a tu propio negocio.');

    const [acepta] = await q(
      'select 1 from public.negocio_modalidad_pago where id_negocio = $1 and id_modalidad = $2',
      [idNegocio, idModalidad],
    );
    if (!acepta) throw fallo(400, 'Este negocio no acepta esa forma de pago.');

    let total = 0;
    const lineas = [];
    for (const d of detalles) {
      const cantidad = Number(d.cantidad);
      if (!Number.isInteger(cantidad) || cantidad <= 0) throw fallo(400, 'Cantidad no válida.');
      const [producto] = await q(
        `select * from public.productos
          where id_producto = $1 and id_negocio = $2 and activo and not oculto_por_moderacion
          for update`,
        [idDe(d.productoId), idNegocio],
      );
      if (!producto || !producto.disponible) throw fallo(400, 'Uno de los productos ya no está disponible. Revisa tu pedido.');
      if (producto.stock < cantidad) {
        throw fallo(400, `Solo quedan ${producto.stock} de "${producto.nombre}".`);
      }
      total += cantidad * Number(producto.precio);
      lineas.push([producto.id_producto, cantidad, producto.precio]);
    }

    const [pedido] = await q(
      `insert into public.pedidos (id_usuario, id_negocio, id_modalidad, total)
       values ($1, $2, $3, $4) returning id_pedido`,
      [req.usuario.id_usuario, idNegocio, idModalidad, total],
    );
    for (const [idProducto, cantidad, precio] of lineas) {
      await q(
        'insert into public.detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) values ($1, $2, $3, $4)',
        [pedido.id_pedido, idProducto, cantidad, precio],
      );
    }
    return pedido.id_pedido;
  });

  res.status(201).json(pedidoJson(await pedidoPorId(idPedido)));
}));

// El cliente cancela su pedido (solo mientras sigue "pendiente").
router.post('/pedidos/:id/cancelar', ruta(async (req, res) => {
  const id = idDe(req.params.id);
  const filas = await consultar(
    `update public.pedidos set estado = 'cancelado', motivo_cancelacion = 'Cancelado por el cliente'
      where id_pedido = $1 and id_usuario = $2 and estado = 'pendiente'
      returning id_pedido`,
    [id, req.usuario.id_usuario],
  );
  if (!filas.length) {
    const actual = await pedidoPorId(id);
    if (!actual || actual.id_usuario !== req.usuario.id_usuario) throw fallo(404, 'Este pedido ya no existe.');
    throw fallo(409, 'El negocio ya respondió tu pedido. Escríbele por el chat si necesitas cambiar algo.');
  }
  res.json(pedidoJson(await pedidoPorId(id)));
}));

// Flujo:  pendiente → aceptado → en_preparacion → listo → entregado
const SIGUIENTE = { pendiente: 'aceptado', aceptado: 'en_preparacion', en_preparacion: 'listo', listo: 'entregado' };
const EN_CURSO = ['aceptado', 'en_preparacion', 'listo'];

// El negocio cambia el estado.  { estado, motivo }  (motivo obligatorio para rechazar/cancelar)
router.patch('/pedidos/:id/estado', ruta(async (req, res) => {
  const id = idDe(req.params.id);
  const negocio = await miNegocio(req);
  exigirNegocioActivo(negocio);
  const nuevo = req.body?.estado;
  const motivo = texto(req.body?.motivo);
  const conMotivo = nuevo === 'rechazado' || nuevo === 'cancelado';
  if (conMotivo && !motivo) throw fallo(400, 'Indica el motivo.');

  await transaccion(async (q) => {
    const [actual] = await q('select * from public.pedidos where id_pedido = $1 and id_negocio = $2 for update', [id, negocio.id_negocio]);
    if (!actual) throw fallo(404, 'Este pedido ya no existe.');

    const valido = nuevo === SIGUIENTE[actual.estado]
      || (nuevo === 'rechazado' && actual.estado === 'pendiente')
      || (nuevo === 'cancelado' && EN_CURSO.includes(actual.estado));
    if (!valido) throw fallo(409, 'Este pedido ya cambió de estado. Actualiza la lista.');

    await q(
      'update public.pedidos set estado = $2, motivo_cancelacion = $3 where id_pedido = $1',
      [id, nuevo, conMotivo ? motivo : actual.motivo_cancelacion],
    );
    // Al aceptar se descuentan las unidades del inventario.
    if (nuevo === 'aceptado') {
      await q(
        `update public.productos pr
            set stock = greatest(pr.stock - d.cantidad, 0)
           from public.detalle_pedido d
          where d.id_pedido = $1 and d.id_producto = pr.id_producto`,
        [id],
      );
    }
  });
  res.json(pedidoJson(await pedidoPorId(id)));
}));

// =========================================================
//  CHAT
// =========================================================

const SELECT_CONVERSACIONES = `
  select c.*, n.nombre_comercial as negocio_nombre,
         (select m.mensaje from public.mensajes m where m.id_conversacion = c.id_conversacion
           order by m.fecha_envio desc, m.id_mensaje desc limit 1) as ultimo_mensaje
    from public.conversaciones c
    join public.negocios n on n.id_negocio = c.id_negocio`;

function conversacionJson(c) {
  return {
    id: String(c.id_conversacion),
    usuarioId: String(c.id_usuario),
    negocioId: String(c.id_negocio),
    negocioNombre: c.negocio_nombre,
    fechaUltimoMensaje: iso(c.fecha_ultimo_mensaje || c.fecha_creacion),
    ultimoMensaje: c.ultimo_mensaje,
  };
}

function mensajeJson(m) {
  return {
    id: String(m.id_mensaje),
    conversacionId: String(m.id_conversacion),
    remitenteId: String(m.id_remitente),
    texto: m.mensaje,
    fechaEnvio: iso(m.fecha_envio),
    leido: m.leido,
  };
}

// Chats del usuario (el más reciente primero).
router.get('/yo/conversaciones', ruta(async (req, res) => {
  const filas = await consultar(
    `${SELECT_CONVERSACIONES} where c.id_usuario = $1
      order by coalesce(c.fecha_ultimo_mensaje, c.fecha_creacion) desc`,
    [req.usuario.id_usuario],
  );
  res.json(filas.map(conversacionJson));
}));

// Abre el chat con un negocio (lo crea si no existe).  { negocioId }
router.post('/conversaciones', ruta(async (req, res) => {
  const negocio = await negocioVisible(req, req.body?.negocioId);
  if (!negocio) throw fallo(404, 'Este negocio ya no está disponible.');
  await consultar(
    `insert into public.conversaciones (id_usuario, id_negocio) values ($1, $2)
     on conflict (id_usuario, id_negocio) do nothing`,
    [req.usuario.id_usuario, negocio.id_negocio],
  );
  const [c] = await consultar(
    `${SELECT_CONVERSACIONES} where c.id_usuario = $1 and c.id_negocio = $2`,
    [req.usuario.id_usuario, negocio.id_negocio],
  );
  res.json(conversacionJson(c));
}));

/** La conversación, si el usuario es el cliente o el dueño del negocio. */
async function conversacionPropia(req) {
  const [c] = await consultar(
    `select c.* from public.conversaciones c join public.negocios n on n.id_negocio = c.id_negocio
      where c.id_conversacion = $1 and (c.id_usuario = $2 or n.id_usuario = $2)`,
    [idDe(req.params.id), req.usuario.id_usuario],
  );
  if (!c) throw fallo(404, 'No se encontró el chat.');
  return c;
}

// Mensajes (del más viejo al más nuevo). ?despues=<id> trae solo los nuevos.
router.get('/conversaciones/:id/mensajes', ruta(async (req, res) => {
  const c = await conversacionPropia(req);
  const despues = req.query.despues ? idDe(req.query.despues) : 0;
  const filas = await consultar(
    `select * from public.mensajes where id_conversacion = $1 and id_mensaje > $2
      order by fecha_envio, id_mensaje`,
    [c.id_conversacion, despues],
  );
  res.json(filas.map(mensajeJson));
}));

router.post('/conversaciones/:id/mensajes', ruta(async (req, res) => {
  const c = await conversacionPropia(req);
  const mensaje = texto(req.body?.texto);
  if (!mensaje) throw fallo(400, 'Escribe un mensaje.');
  if (mensaje.length > 2000) throw fallo(400, 'El mensaje es muy largo.');
  const [m] = await consultar(
    'insert into public.mensajes (id_conversacion, id_remitente, mensaje) values ($1, $2, $3) returning *',
    [c.id_conversacion, req.usuario.id_usuario, mensaje],
  );
  res.status(201).json(mensajeJson(m));
}));

module.exports = router;
