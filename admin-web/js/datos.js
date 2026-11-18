/* =========================================================
   MODELO: todo lo que tiene que ver con los datos.
   Las pantallas SOLO usan las funciones de `Datos` (abajo).
   - Modo prueba (CONFIG.API_URL vacío): datos de prueba que se
     guardan en el navegador (localStorage).
   - Modo API: cada función llama a la API real con fetch.
   Para conectar la base de datos solo hay que poner la dirección
   en js/config.js y que la API responda como dice API.md.
   ========================================================= */

const MODO_PRUEBA = !CONFIG.API_URL;

/* ---------------------------------------------------------
   Datos de prueba (solo se usan en modo prueba)
   --------------------------------------------------------- */

const ADMIN_PRUEBA = { nombre: 'Andrés Mejía', correo: 'admin@test.com', clave: 'Prueba123' };

const DATOS_INICIALES = {
  usuarios: [
    { id: 'u_1', nombre: 'Carla Gómez', correo: 'cliente@test.com', telefono: '300 123 4567', rol: 'Cliente', registro: '02/08/2026', estado: 'Activo', pedidos: 9 },
    { id: 'u_2', nombre: 'Nora Ruiz', correo: 'negocio@test.com', telefono: '310 987 6543', rol: 'Negocio', registro: '05/08/2026', estado: 'Activo', negocioId: 'n_1' },
    { id: 'u_20', nombre: 'Luis Herrera', correo: 'arepas@test.com', telefono: '301 444 5566', rol: 'Negocio', registro: '20/08/2026', estado: 'Activo', negocioId: 'n_2' },
    { id: 'u_21', nombre: 'Rosa Martínez', correo: 'frutas@test.com', telefono: '315 777 8899', rol: 'Negocio', registro: '04/09/2026', estado: 'Activo', negocioId: 'n_3' },
    { id: 'u_22', nombre: 'Jorge Castro', correo: 'eltrigal@test.com', telefono: '320 111 2233', rol: 'Negocio', registro: '19/09/2026', estado: 'Activo', negocioId: 'n_4' },
    { id: 'u_23', nombre: 'Elena Pacheco', correo: 'artesanias@test.com', telefono: '318 666 5544', rol: 'Negocio', registro: '04/10/2026', estado: 'Activo', negocioId: 'n_5' },
    { id: 'u_30', nombre: 'Mateo Ríos', correo: 'mateo@test.com', telefono: '304 555 6677', rol: 'Cliente', registro: '21/10/2026', estado: 'Activo', pedidos: 3 },
    { id: 'u_31', nombre: 'Laura Pérez', correo: 'laura@test.com', telefono: '311 222 3344', rol: 'Cliente', registro: '30/10/2026', estado: 'Suspendido', pedidos: 4,
      motivo: 'Comentarios ofensivos en el chat con negocios.', cuando: '13/11/2026 · por Andrés Mejía' },
  ],

  negocios: [
    { id: 'n_1', nombre: 'Nouveau Beauty Salon', tipo: 'fijo', descripcion: 'Uñas, manos y pies con atención personalizada', duenoId: 'u_2', lugar: 'Calle del Arsenal # 10-45, Getsemaní', registro: '05/08/2026', estado: 'Activo' },
    { id: 'n_2', nombre: 'Arepas La Esquina', tipo: 'ambulante', descripcion: 'Arepas de huevo y de queso recién hechas', duenoId: 'u_20', lugar: 'Actualizada hace 25 min', registro: '20/08/2026', estado: 'Activo' },
    { id: 'n_3', nombre: 'Frutas Doña Rosa', tipo: 'ambulante', descripcion: 'Frutas picadas, jugos y salpicón', duenoId: 'u_21', lugar: 'Actualizada hace 40 min', registro: '04/09/2026', estado: 'Activo' },
    { id: 'n_4', nombre: 'Panadería El Trigal', tipo: 'fijo', descripcion: 'Pan artesanal, pasteles y café', duenoId: 'u_22', lugar: 'Av. Jiménez # 23-10, Manga', registro: '19/09/2026', estado: 'Activo' },
    { id: 'n_5', nombre: 'Artesanías Mompox', tipo: 'fijo', descripcion: 'Filigrana, mochilas y sombreros hechos a mano', duenoId: 'u_23', lugar: 'Calle de las Damas # 3-21, Centro', registro: '04/10/2026', estado: 'Suspendido',
      motivo: 'Fotos de productos que no corresponden a lo que vende.', cuando: '13/11/2026 · por Andrés Mejía' },
  ],

  // Quejas sobre un NEGOCIO (servicio o comportamiento).
  reportes: [
    { id: 'REP-004', negocioId: 'n_2', usuarioId: 'u_30', motivo: 'Información incorrecta', fecha: '14/11/2026', hora: '10:42 a. m.', estado: 'Pendiente', origen: 'Un cliente desde la app', nota: '', cierre: '',
      descripcion: 'La ubicación que muestra la app no es la real. Fui dos veces al punto del mapa y el puesto no estaba; el vendedor no la actualiza.' },
    { id: 'REP-003', negocioId: 'n_5', usuarioId: 'u_1', motivo: 'Producto engañoso', fecha: '12/11/2026', hora: '4:15 p. m.', estado: 'Enviado a Moderación', origen: 'Un cliente desde la app',
      nota: 'El problema son las fotos de los productos, no el servicio.', cierre: 'Enviado a Moderación como MOD-003 el 13/11/2026 por Andrés Mejía.',
      descripcion: 'Las fotos de las mochilas no corresponden a lo que venden en el local; el producto que recibí es de otra calidad.' },
    { id: 'REP-002', negocioId: 'n_3', usuarioId: 'u_31', motivo: 'Pedido no entregado', fecha: '10/11/2026', hora: '7:30 p. m.', estado: 'Pendiente', origen: 'Un cliente desde la app', nota: '', cierre: '',
      descripcion: 'Hice un pedido contraentrega, acordamos la hora por el chat y nunca llegó. Después no volvió a responder.' },
    { id: 'REP-001', negocioId: 'n_4', usuarioId: 'u_1', motivo: 'Trato inadecuado', fecha: '03/11/2026', hora: '11:05 a. m.', estado: 'Resuelto', origen: 'Un cliente desde la app',
      nota: 'Se habló con el dueño; se disculpó con la clienta.', cierre: 'Resuelto el 05/11/2026 por Andrés Mejía.',
      descripcion: 'La persona que atiende me respondió de mala manera cuando pregunté por mi pedido.' },
  ],

  // Un CONTENIDO puntual: foto, producto o descripción.
  moderacion: [
    { id: 'MOD-003', tipo: 'Foto de producto', negocioId: 'n_5', usuarioId: 'u_1', titulo: 'Sombrero vueltiao', precio: '$ 180.000', fotoUrl: '', motivo: 'La foto no corresponde al producto', fecha: '13/11/2026', estado: 'Por revisar', origen: 'Enviado desde Reportes (REP-003)', cierre: '',
      mensaje: 'La foto del producto «Sombrero vueltiao» no corresponde a lo que vendes. Sube una foto real del producto.' },
    { id: 'MOD-002', tipo: 'Descripción del negocio', negocioId: 'n_2', usuarioId: 'u_1', texto: '«Arepas de huevo y de queso recién hechas. Las del puesto de enfrente dan asco, no les compre.»', motivo: 'Lenguaje ofensivo hacia otro negocio', fecha: '13/11/2026', estado: 'Por revisar', origen: 'Un cliente desde la app', cierre: '',
      mensaje: 'Tu descripción tiene lenguaje ofensivo hacia otro negocio. Escribe una nueva descripción sin mencionar a otros vendedores.' },
    { id: 'MOD-001', tipo: 'Producto', negocioId: 'n_4', usuarioId: 'u_31', texto: 'Pan de bono — $ 1.500 la unidad', motivo: 'Precio sospechoso', fecha: '06/11/2026', estado: 'Mantenido', origen: 'Un cliente desde la app', mensaje: '',
      cierre: 'Mantenido el 07/11/2026 por Andrés Mejía: el precio es normal para el producto.' },
    { id: 'MOD-004', tipo: 'Descripción del negocio', negocioId: 'n_2', usuarioId: 'u_30', texto: '«Las mejores arepas. Los de enfrente venden basura.»', motivo: 'Lenguaje ofensivo hacia otro negocio', fecha: '02/11/2026', estado: 'Quitado', origen: 'Un cliente desde la app', mensaje: '',
      cierre: 'Quitado el 02/11/2026 por Andrés Mejía. Se avisó al dueño de Arepas La Esquina.' },
  ],
};

/* ---------------------------------------------------------
   Modo prueba: guardar y leer del navegador
   --------------------------------------------------------- */

const CLAVE_DATOS = 'ecosistema-admin-datos';

const Prueba = {
  leer() {
    try {
      const guardado = localStorage.getItem(CLAVE_DATOS);
      if (guardado) return JSON.parse(guardado);
    } catch (e) { /* sin almacenamiento: se usan los iniciales */ }
    return JSON.parse(JSON.stringify(DATOS_INICIALES));
  },
  guardar(datos) {
    try { localStorage.setItem(CLAVE_DATOS, JSON.stringify(datos)); } catch (e) { /* ignorar */ }
  },
  /** Cambia un elemento de una lista y lo guarda. */
  cambiar(lista, id, cambios) {
    const d = this.leer();
    const item = d[lista].find((x) => x.id === id);
    if (!item) throw new Error('No se encontró ' + id);
    Object.assign(item, cambios);
    this.guardar(d);
    return item;
  },
  siguienteId(lista, prefijo) {
    const mayor = lista.reduce((m, x) => Math.max(m, parseInt(x.id.replace(/\D/g, ''), 10) || 0), 0);
    return prefijo + '-' + String(mayor + 1).padStart(3, '0');
  },
};

function fechaHoy() {
  const d = new Date();
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
}
function horaAhora() {
  return new Date().toLocaleTimeString('es-CO', { hour: 'numeric', minute: '2-digit' });
}
/** "Resuelto el 15/11/2026 por Andrés Mejía." (en la API real lo arma el servidor) */
function firma(accion) {
  return `${accion} el ${fechaHoy()} por ${adminActual()?.nombre || 'el administrador'}.`;
}

/* ---------------------------------------------------------
   Modo API: llamadas a la API real
   --------------------------------------------------------- */

async function llamarApi(metodo, ruta, cuerpo) {
  const respuesta = await fetch(CONFIG.API_URL + ruta, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      ...(adminActual()?.token ? { Authorization: 'Bearer ' + adminActual().token } : {}),
    },
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  // 401 con sesión abierta = el token venció → volver al login.
  // (En el login mismo, 401 solo significa "correo o contraseña incorrectos".)
  if (respuesta.status === 401 && adminActual()) { cerrarSesion(); throw new Error('La sesión expiró.'); }
  const json = await respuesta.json().catch(() => ({}));
  if (!respuesta.ok) throw new Error(json.mensaje || 'No se pudo completar la acción. Intenta de nuevo.');
  return json;
}

/* ---------------------------------------------------------
   LO QUE USAN LAS PANTALLAS (todas devuelven promesas)
   --------------------------------------------------------- */

const Datos = {

  // ----- Sesión -----

  /** Devuelve { nombre, correo, token } o lanza un Error con el mensaje para mostrar. */
  async iniciarSesion(correo, clave) {
    if (!MODO_PRUEBA) return llamarApi('POST', '/admin/login', { correo, clave });
    if (correo !== ADMIN_PRUEBA.correo || clave !== ADMIN_PRUEBA.clave) {
      throw new Error('Correo o contraseña incorrectos.');
    }
    return { nombre: ADMIN_PRUEBA.nombre, correo: ADMIN_PRUEBA.correo, token: 'prueba' };
  },

  // ----- Leer -----

  /** { usuarios, negocios, reportes, moderacion } */
  async cargarTodo() {
    if (MODO_PRUEBA) return Prueba.leer();
    const [usuarios, negocios, reportes, moderacion] = await Promise.all([
      llamarApi('GET', '/admin/usuarios'),
      llamarApi('GET', '/admin/negocios'),
      llamarApi('GET', '/admin/reportes'),
      llamarApi('GET', '/admin/moderacion'),
    ]);
    return { usuarios, negocios, reportes, moderacion };
  },

  // ----- Usuarios -----

  async suspenderUsuario(id, motivo) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/usuarios/${id}`, { estado: 'Suspendido', motivo });
    return Prueba.cambiar('usuarios', id, { estado: 'Suspendido', motivo, cuando: `${fechaHoy()} · por ${adminActual().nombre}` });
  },

  async reactivarUsuario(id) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/usuarios/${id}`, { estado: 'Activo' });
    return Prueba.cambiar('usuarios', id, { estado: 'Activo', motivo: '', cuando: '' });
  },

  // ----- Negocios -----

  async suspenderNegocio(id, motivo) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/negocios/${id}`, { estado: 'Suspendido', motivo });
    return Prueba.cambiar('negocios', id, { estado: 'Suspendido', motivo, cuando: `${fechaHoy()} · por ${adminActual().nombre}` });
  },

  async reactivarNegocio(id) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/negocios/${id}`, { estado: 'Activo' });
    return Prueba.cambiar('negocios', id, { estado: 'Activo', motivo: '', cuando: '' });
  },

  // ----- Reportes -----

  /** estado: 'Pendiente' | 'En revisión' | 'Resuelto' | 'Descartado' */
  async cambiarEstadoReporte(id, estado) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/reportes/${id}`, { estado });
    const cierre = estado === 'Resuelto' || estado === 'Descartado' ? firma(estado) : '';
    return Prueba.cambiar('reportes', id, { estado, cierre });
  },

  async guardarNotaReporte(id, nota) {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/reportes/${id}`, { nota });
    return Prueba.cambiar('reportes', id, { nota });
  },

  /** Crea un caso en Moderación y devuelve su id (ej. 'MOD-005'). */
  async enviarReporteAModeracion(id) {
    if (!MODO_PRUEBA) return (await llamarApi('POST', `/admin/reportes/${id}/enviar-a-moderacion`)).id;
    const d = Prueba.leer();
    const r = d.reportes.find((x) => x.id === id);
    const nuevoId = Prueba.siguienteId(d.moderacion, 'MOD');
    d.moderacion.unshift({
      id: nuevoId, tipo: 'Contenido del negocio', negocioId: r.negocioId, usuarioId: r.usuarioId,
      texto: r.descripcion, motivo: r.motivo, fecha: fechaHoy(), estado: 'Por revisar',
      origen: `Enviado desde Reportes (${r.id})`, cierre: '', mensaje: '',
    });
    Object.assign(r, { estado: 'Enviado a Moderación', cierre: firma(`Enviado a Moderación como ${nuevoId}`) });
    Prueba.guardar(d);
    return nuevoId;
  },

  // ----- Moderación -----

  /** estado: 'Por revisar' | 'Mantenido' | 'Quitado' (Quitado lleva el mensaje para el dueño) */
  async cambiarEstadoContenido(id, estado, mensaje = '') {
    if (!MODO_PRUEBA) return llamarApi('PATCH', `/admin/moderacion/${id}`, { estado, mensaje });
    const cambios = { estado, cierre: '' };
    if (estado === 'Mantenido') cambios.cierre = firma('Mantenido');
    if (estado === 'Quitado') { cambios.mensaje = mensaje; cambios.cierre = firma('Quitado') + ' Se avisó al dueño.'; }
    return Prueba.cambiar('moderacion', id, cambios);
  },

  /** Crea un reporte en Reportes y devuelve su id (ej. 'REP-005'). */
  async enviarContenidoAReportes(id) {
    if (!MODO_PRUEBA) return (await llamarApi('POST', `/admin/moderacion/${id}/enviar-a-reportes`)).id;
    const d = Prueba.leer();
    const c = d.moderacion.find((x) => x.id === id);
    const nuevoId = Prueba.siguienteId(d.reportes, 'REP');
    d.reportes.unshift({
      id: nuevoId, negocioId: c.negocioId, usuarioId: c.usuarioId, motivo: c.motivo,
      fecha: fechaHoy(), hora: horaAhora(), estado: 'Pendiente',
      origen: `Enviado desde Moderación (${c.id})`, nota: '', cierre: '',
      descripcion: `${c.tipo}: ${c.titulo || c.texto}`,
    });
    Object.assign(c, { estado: 'Enviado a Reportes', cierre: firma(`Enviado a Reportes como ${nuevoId}`) + ' El contenido sigue publicado hasta que se decida allí.' });
    Prueba.guardar(d);
    return nuevoId;
  },

  // ----- Ayudas -----

  usuario(datos, id) { return datos.usuarios.find((u) => u.id === id) || { nombre: '—', correo: '', telefono: '' }; },
  negocio(datos, id) { return datos.negocios.find((n) => n.id === id) || { nombre: '—', estado: '', duenoId: null }; },

  /** Solo modo prueba: vuelve a los datos originales. */
  reiniciarPrueba() {
    try { localStorage.removeItem(CLAVE_DATOS); } catch (e) { /* ignorar */ }
  },
};
