// Rutas del panel de administración (ver admin-web/API.md).
// Las listas salen de las vistas v_admin_*, que ya devuelven el JSON
// exacto que espera la web.
const express = require('express');
const { consultar, transaccion } = require('../db');
const { soloAdmin } = require('../auth');

const router = express.Router();
router.use(soloAdmin);

// ---------- Ayudas ----------

/** "REP-004" → 4, "7" → 7. Devuelve null si no es un número válido. */
function numeroDe(id) {
  const n = parseInt(String(id).replace(/\D/g, ''), 10);
  return Number.isInteger(n) && n > 0 ? n : null;
}

/** Error con código HTTP y mensaje para mostrar en la web. */
function fallo(estado, mensaje) {
  const e = new Error(mensaje);
  e.estado = estado;
  return e;
}

/** Envuelve las rutas async para mandar los errores al manejador de errores. */
const ruta = (fn) => (req, res, next) => fn(req, res).catch(next);

// Textos de la web → valores guardados en la base de datos
const ESTADO_REPORTE = { 'Pendiente': 'pendiente', 'En revisión': 'en_revision', 'Resuelto': 'resuelto', 'Descartado': 'descartado' };
const ESTADO_CONTENIDO = { 'Por revisar': 'por_revisar', 'Mantenido': 'mantenido', 'Quitado': 'quitado' };

// ---------- Listas (GET) ----------

router.get('/usuarios', ruta(async (req, res) => res.json(await consultar('select * from public.v_admin_usuarios'))));
router.get('/negocios', ruta(async (req, res) => res.json(await consultar('select * from public.v_admin_negocios'))));
router.get('/reportes', ruta(async (req, res) => res.json(await consultar('select * from public.v_admin_reportes'))));
router.get('/moderacion', ruta(async (req, res) => res.json(await consultar('select * from public.v_admin_moderacion'))));

// ---------- Suspender / reactivar usuarios y negocios ----------

/**
 * Crea la ruta PATCH para usuarios o negocios.
 * Cuerpo: { estado: 'Suspendido', motivo } o { estado: 'Activo' }
 */
function rutaSuspension(tabla, columnaId, vista, condicionExtra = '') {
  return ruta(async (req, res) => {
    const id = numeroDe(req.params.id);
    const { estado, motivo } = req.body || {};
    if (!id) throw fallo(400, 'Identificador no válido.');

    let filas;
    if (estado === 'Suspendido') {
      if (!motivo || !String(motivo).trim()) throw fallo(400, 'Escribe el motivo de la suspensión.');
      filas = await consultar(
        `update public.${tabla}
            set estado = 'suspendido', motivo_suspension = $2, suspendido_por = $3, fecha_suspension = now()
          where ${columnaId} = $1 ${condicionExtra}
          returning ${columnaId}`,
        [id, String(motivo).trim(), req.adminId],
      );
    } else if (estado === 'Activo') {
      filas = await consultar(
        `update public.${tabla}
            set estado = 'activo', motivo_suspension = null, suspendido_por = null, fecha_suspension = null
          where ${columnaId} = $1 ${condicionExtra}
          returning ${columnaId}`,
        [id],
      );
    } else {
      throw fallo(400, 'Estado no válido.');
    }
    if (!filas.length) throw fallo(404, 'No se encontró.');

    const [actualizado] = await consultar(`select * from public.${vista} where "id" = $1`, [String(id)]);
    res.json(actualizado || {});
  });
}

// Los administradores no se pueden suspender desde el panel.
router.patch('/usuarios/:id', rutaSuspension('usuarios', 'id_usuario', 'v_admin_usuarios', "and rol in ('cliente', 'negocio')"));
router.patch('/negocios/:id', rutaSuspension('negocios', 'id_negocio', 'v_admin_negocios'));

// ---------- Reportes ----------

// Cuerpo: { estado } o { nota }
router.patch('/reportes/:id', ruta(async (req, res) => {
  const id = numeroDe(req.params.id);
  if (!id) throw fallo(400, 'Identificador no válido.');
  const { estado, nota } = req.body || {};

  if (nota !== undefined) {
    const filas = await consultar('update public.reportes set nota_interna = $2 where id_reporte = $1 returning id_reporte', [id, String(nota)]);
    if (!filas.length) throw fallo(404, 'No se encontró el reporte.');
  }

  if (estado !== undefined) {
    const valor = ESTADO_REPORTE[estado];
    if (!valor) throw fallo(400, 'Estado no válido.');
    const cierra = valor === 'resuelto' || valor === 'descartado';
    const filas = await consultar(
      `update public.reportes
          set estado = $2,
              cerrado_por = case when $3 then $4::bigint end,
              fecha_cierre = case when $3 then now() end
        where id_reporte = $1
        returning id_reporte`,
      [id, valor, cierra, req.adminId],
    );
    if (!filas.length) throw fallo(404, 'No se encontró el reporte.');
  }

  const [actualizado] = await consultar('select * from public.v_admin_reportes where "id" = $1', ['REP-' + String(id).padStart(3, '0')]);
  res.json(actualizado || {});
}));

// Crea un caso en Moderación a partir del reporte → { id: 'MOD-005' }
router.post('/reportes/:id/enviar-a-moderacion', ruta(async (req, res) => {
  const id = numeroDe(req.params.id);
  if (!id) throw fallo(400, 'Identificador no válido.');
  const [fila] = await consultar('select public.admin_enviar_reporte_a_moderacion($1, $2) as id', [id, req.adminId]);
  res.json({ id: fila.id });
}));

// ---------- Moderación ----------

// Cuerpo: { estado: 'Mantenido' | 'Por revisar' } o { estado: 'Quitado', mensaje }
router.patch('/moderacion/:id', ruta(async (req, res) => {
  const id = numeroDe(req.params.id);
  if (!id) throw fallo(400, 'Identificador no válido.');
  const { estado, mensaje } = req.body || {};
  const valor = ESTADO_CONTENIDO[estado];
  if (!valor) throw fallo(400, 'Estado no válido.');
  if (valor === 'quitado' && !String(mensaje || '').trim()) throw fallo(400, 'Escribe el mensaje para el dueño.');

  await transaccion(async (q) => {
    const [caso] = await q('select * from public.moderacion where id_moderacion = $1 for update', [id]);
    if (!caso) throw fallo(404, 'No se encontró el caso.');

    if (valor === 'quitado') {
      await q(
        `update public.moderacion
            set estado = 'quitado', mensaje_dueno = $2, cerrado_por = $3, fecha_cierre = now()
          where id_moderacion = $1`,
        [id, String(mensaje).trim(), req.adminId],
      );
      // Quitar el contenido de la app:
      if (caso.id_producto) {
        await q('update public.productos set oculto_por_moderacion = true where id_producto = $1', [caso.id_producto]);
      } else if (caso.tipo === 'descripcion_negocio') {
        await q("update public.negocios set descripcion = '' where id_negocio = $1", [caso.id_negocio]);
      }
    } else if (valor === 'mantenido') {
      await q(
        `update public.moderacion set estado = 'mantenido', cerrado_por = $2, fecha_cierre = now() where id_moderacion = $1`,
        [id, req.adminId],
      );
    } else {
      // Volver a revisar: si se había ocultado un producto, se vuelve a mostrar.
      if (caso.estado === 'quitado' && caso.id_producto) {
        await q('update public.productos set oculto_por_moderacion = false where id_producto = $1', [caso.id_producto]);
      }
      await q(
        `update public.moderacion set estado = 'por_revisar', cerrado_por = null, fecha_cierre = null where id_moderacion = $1`,
        [id],
      );
    }
  });

  const [actualizado] = await consultar('select * from public.v_admin_moderacion where "id" = $1', ['MOD-' + String(id).padStart(3, '0')]);
  res.json(actualizado || {});
}));

// Crea un reporte a partir del caso → { id: 'REP-005' }
router.post('/moderacion/:id/enviar-a-reportes', ruta(async (req, res) => {
  const id = numeroDe(req.params.id);
  if (!id) throw fallo(400, 'Identificador no válido.');
  const [fila] = await consultar('select public.admin_enviar_contenido_a_reportes($1, $2) as id', [id, req.adminId]);
  res.json({ id: fila.id });
}));

module.exports = router;
