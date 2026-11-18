/* =========================================================
   Funciones que usan todas las pantallas:
   sesión, menú lateral, íconos, cuadro central y avisos.
   ========================================================= */

const CLAVE_SESION = 'ecosistema-admin-sesion';

// ---------- Íconos (SVG de línea) ----------
const svg = (contenido, tam = 20) =>
  `<svg width="${tam}" height="${tam}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${contenido}</svg>`;

const ICONOS = {
  dashboard: svg('<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>'),
  usuarios: svg('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8"/><path d="M18 14.3c2.1.7 3.5 2.8 3.5 5.7"/>'),
  tienda: svg('<path d="M3 9l1.5-5h15L21 9"/><path d="M3 9h18v2a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0z"/><path d="M5 13v7h14v-7"/>'),
  carrito: svg('<path d="M4 5h11l-1 8H5z"/><path d="M15 7h3l2 4"/><path d="M3 5h1"/><circle cx="7" cy="18" r="2"/><circle cx="15" cy="18" r="2"/><path d="M9 18h4"/><path d="M5 13v3"/>'),
  reportes: svg('<path d="M5 21V4"/><path d="M5 4h12l-2.5 4.5L17 13H5"/>'),
  moderacion: svg('<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>'),
  salir: svg('<path d="M15 4h4v16h-4"/><path d="M10 8l-4 4 4 4"/><path d="M6 12h10"/>', 18),
  flecha: svg('<path d="M9 6l6 6-6 6"/>', 18),
  cerrar: svg('<path d="M6 6l12 12"/><path d="M18 6L6 18"/>', 18),
  buscar: svg('<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', 18),
  check: svg('<circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/>', 18),
  pausa: svg('<circle cx="12" cy="12" r="9"/><path d="M10 9v6"/><path d="M14 9v6"/>', 18),
  foto: svg('<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-8 9"/>', 26),
  alerta: svg('<path d="M12 3l9 16H3z"/><path d="M12 10v4"/><path d="M12 17h.01"/>', 18),
  ok: svg('<path d="M5 12.5l4.5 4.5L19 7.5"/>', 18),
  basura: svg('<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/>', 18),
  enviar: svg('<path d="M5 12h14"/><path d="M13 6l6 6-6 6"/>', 18),
};

// ---------- Utilidades ----------

/** Escapa texto para meterlo en HTML sin riesgo. */
function esc(texto) {
  return String(texto ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

/** "Panadería" → "panaderia" (para buscar sin tildes ni mayúsculas). */
function normalizar(texto) {
  return String(texto ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
}

/** Si la búsqueda es un número ("3", "003", "rep 3", "#3"), devuelve 3. */
function numeroBuscado(busqueda, prefijo) {
  const m = normalizar(busqueda).match(new RegExp('^(?:' + prefijo + ')?[\\s#-]*0*(\\d+)$'));
  return m ? parseInt(m[1], 10) : null;
}
const numeroDeId = (id) => parseInt(id.replace(/\D/g, ''), 10);

function iniciales(nombre) {
  return String(nombre).split(' ').filter(Boolean).map((p) => p[0]).slice(0, 2).join('').toUpperCase();
}

/** Etiqueta de color para un estado: "En revisión" → chip--en-revision */
function chip(estado) {
  return `<span class="chip chip--${normalizar(estado).replace(/\s+/g, '-')}">${esc(estado)}</span>`;
}

const porNombre = (a, b) => a.nombre.localeCompare(b.nombre, 'es', { sensitivity: 'base' });

// ---------- Sesión ----------

/** El administrador que inició sesión: { nombre, correo, token } o null. */
function adminActual() {
  try { return JSON.parse(sessionStorage.getItem(CLAVE_SESION)); } catch (e) { return null; }
}
function haySesion() {
  return !!adminActual();
}
function guardarSesion(admin) {
  try { sessionStorage.setItem(CLAVE_SESION, JSON.stringify(admin)); } catch (e) { /* ignorar */ }
}
function cerrarSesion() {
  try { sessionStorage.removeItem(CLAVE_SESION); } catch (e) { /* ignorar */ }
  location.href = 'index.html';
}
/** Las pantallas internas llaman a esto primero: sin sesión → al login. */
function protegerPagina() {
  if (!haySesion()) location.replace('index.html');
}

// ---------- Menú lateral ----------

async function pintarMenu(activo) {
  let datos = { reportes: [], moderacion: [] };
  try { datos = await Datos.cargarTodo(); } catch (e) { /* el menú se pinta sin contadores */ }
  const admin = adminActual() || { nombre: '', correo: '' };
  const reportesPorRevisar = datos.reportes.filter((r) => r.estado === 'Pendiente' || r.estado === 'En revisión').length;
  const contenidoPorRevisar = datos.moderacion.filter((c) => c.estado === 'Por revisar').length;

  const enlace = (pagina, id, texto, icono, contador) => `
    <a class="menu__enlace" href="${pagina}" ${activo === id ? 'aria-current="page"' : ''}>
      ${icono}<span class="menu__texto">${texto}</span>
      ${contador ? `<span class="menu__contador" aria-label="${contador} por revisar">${contador}</span>` : ''}
    </a>`;

  document.getElementById('menu').innerHTML = `
    <div class="marca">
      <div class="marca__logo">${ICONOS.tienda}</div>
      <div><div class="marca__nombre">Ecosistema</div><div class="marca__sub">Administración</div></div>
    </div>
    <div class="menu__enlaces">
      ${enlace('dashboard.html', 'dashboard', 'Dashboard', ICONOS.dashboard)}
      ${enlace('usuarios.html', 'usuarios', 'Usuarios', ICONOS.usuarios)}
      ${enlace('negocios.html', 'negocios', 'Negocios', ICONOS.tienda)}
      ${enlace('reportes.html', 'reportes', 'Reportes', ICONOS.reportes, reportesPorRevisar)}
      ${enlace('moderacion.html', 'moderacion', 'Moderación', ICONOS.moderacion, contenidoPorRevisar)}
    </div>
    <div class="menu__pie">
      <div class="persona">
        <span class="avatar">${esc(iniciales(admin.nombre || 'A'))}</span>
        <div><div class="persona__nombre">${esc(admin.nombre)}</div><div class="persona__correo">${esc(admin.correo)}</div></div>
      </div>
      <button type="button" class="boton" id="cerrar-sesion">${ICONOS.salir}Cerrar sesión</button>
    </div>`;
  document.getElementById('cerrar-sesion').addEventListener('click', cerrarSesion);
}

// ---------- Cuadro central (modal) ----------

let alCerrarModal = null;

/** Abre el cuadro con el HTML dado. Devuelve el elemento .modal. */
function abrirModal(html, { chico = false, alCerrar = null } = {}) {
  const capa = document.getElementById('capa-modal');
  capa.innerHTML = `<div class="modal ${chico ? 'modal--chico' : ''}" role="dialog" aria-modal="true">${html}</div>`;
  capa.hidden = false;
  alCerrarModal = alCerrar;
  const modal = capa.querySelector('.modal');
  const titulo = modal.querySelector('h2');
  if (titulo) { titulo.id = 'titulo-modal'; modal.setAttribute('aria-labelledby', 'titulo-modal'); }
  modal.querySelectorAll('[data-cerrar]').forEach((b) => b.addEventListener('click', cerrarModal));
  (modal.querySelector('textarea, button') || modal).focus();
  return modal;
}

function cerrarModal() {
  const capa = document.getElementById('capa-modal');
  if (capa.hidden) return;
  capa.hidden = true;
  capa.innerHTML = '';
  const fn = alCerrarModal;
  alCerrarModal = null;
  if (fn) fn();
}

// Cerrar con clic en el fondo oscuro o con la tecla Escape.
document.addEventListener('click', (e) => {
  if (e.target.id === 'capa-modal') cerrarModal();
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') cerrarModal();
});

/** Botón X para la esquina del cuadro. */
const botonCerrarModal = `<button type="button" class="boton boton--icono" data-cerrar aria-label="Cerrar">${ICONOS.cerrar}</button>`;

/**
 * Cuadro que pide un motivo antes de confirmar (suspender, quitar…).
 * El botón de confirmar no se activa si el texto está vacío.
 */
function pedirMotivo({ titulo, explicacion, etiqueta, texto = '', placeholder = '', boton, alConfirmar, alCancelar }) {
  const modal = abrirModal(`
    <h2>${esc(titulo)}</h2>
    <p style="margin:0;color:var(--texto-suave);font-size:14px;line-height:1.5">${esc(explicacion)}</p>
    <div class="campo">
      <label for="motivo">${esc(etiqueta)}</label>
      <textarea id="motivo" rows="3" placeholder="${esc(placeholder)}">${esc(texto)}</textarea>
    </div>
    <div class="modal__acciones modal__acciones--derecha">
      <button type="button" class="boton" data-cancelar>Cancelar</button>
      <button type="button" class="boton boton--peligro" data-confirmar>${esc(boton)}</button>
    </div>`, { chico: true });

  const campo = modal.querySelector('#motivo');
  const confirmar = modal.querySelector('[data-confirmar]');
  const revisar = () => { confirmar.disabled = !campo.value.trim(); };
  campo.addEventListener('input', revisar);
  revisar();

  modal.querySelector('[data-cancelar]').addEventListener('click', () => {
    cerrarModal();
    if (alCancelar) alCancelar();
  });
  confirmar.addEventListener('click', () => {
    const motivo = campo.value.trim();
    if (!motivo) return;
    cerrarModal();
    alConfirmar(motivo);
  });
}

// ---------- Aviso (toast) ----------

let temporizadorAviso = null;

function mostrarAviso(texto) {
  const aviso = document.getElementById('aviso');
  aviso.innerHTML = `<span>${esc(texto)}</span><button type="button" aria-label="Cerrar aviso">${ICONOS.cerrar}</button>`;
  aviso.hidden = false;
  aviso.querySelector('button').addEventListener('click', () => { aviso.hidden = true; });
  clearTimeout(temporizadorAviso);
  temporizadorAviso = setTimeout(() => { aviso.hidden = true; }, 5000);
}

// ---------- Filtros en forma de botones ----------

/**
 * Pinta los botones de filtro.
 * opciones: [{ id, texto, cuantos }], activo: id seleccionado.
 */
function pintarFiltros(contenedor, opciones, activo, alElegir) {
  contenedor.innerHTML = opciones.map((o) =>
    `<button type="button" class="filtro" data-id="${o.id}" aria-pressed="${o.id === activo}">${esc(o.texto)} · ${o.cuantos}</button>`
  ).join('');
  contenedor.querySelectorAll('.filtro').forEach((b) => b.addEventListener('click', () => alElegir(b.dataset.id)));
}

/**
 * Ejecuta una acción de datos y muestra el aviso; si falla (por ejemplo,
 * no hay conexión con la API) muestra el error en vez de romperse.
 */
async function hacer(accion, avisoExito) {
  try {
    const resultado = await accion();
    if (avisoExito) mostrarAviso(typeof avisoExito === 'function' ? avisoExito(resultado) : avisoExito);
    return resultado;
  } catch (e) {
    mostrarAviso(e.message || 'No se pudo completar la acción.');
    return null;
  }
}
