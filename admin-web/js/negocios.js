/* Negocios: lista A–Z, buscador, filtros, sus reportes y reactivar.
   (Suspender se hace desde Reportes, no desde aquí.) */

protegerPagina();
pintarMenu('negocios');
document.getElementById('icono-buscar').innerHTML = ICONOS.buscar;

const estado = { filtro: 'todos', busqueda: '', seleccionado: null };
let d = null; // datos cargados

const FILTROS = {
  todos: { texto: 'Todos', pasa: () => true },
  activo: { texto: 'Activos', pasa: (n) => n.estado === 'Activo' },
  suspendido: { texto: 'Suspendidos', pasa: (n) => n.estado === 'Suspendido' },
  fijo: { texto: 'Fijos', pasa: (n) => n.tipo === 'fijo' },
  ambulante: { texto: 'Ambulantes', pasa: (n) => n.tipo === 'ambulante' },
};

const tipoTexto = (n) => (n.tipo === 'fijo' ? 'Negocio fijo' : 'Negocio ambulante');
const iconoTipo = (n) => (n.tipo === 'fijo' ? ICONOS.tienda : ICONOS.carrito);

async function cargar() {
  try {
    d = await Datos.cargarTodo();
  } catch (e) {
    document.getElementById('filas').innerHTML = `<div class="vacio">${esc(e.message || 'No se pudieron cargar los negocios.')}</div>`;
    return;
  }
  pintar();
}

function pintar() {
  const dueno = (n) => Datos.usuario(d, n.duenoId);
  const q = normalizar(estado.busqueda);
  const conBusqueda = d.negocios.filter((n) =>
    !q || normalizar(`${n.nombre} ${n.descripcion} ${dueno(n).nombre} ${dueno(n).correo}`).includes(q));

  pintarFiltros(
    document.getElementById('filtros'),
    Object.entries(FILTROS).map(([id, f]) => ({ id, texto: f.texto, cuantos: conBusqueda.filter(f.pasa).length })),
    estado.filtro,
    (id) => { estado.filtro = id; pintar(); },
  );

  const visibles = conBusqueda.filter(FILTROS[estado.filtro].pasa).sort(porNombre);
  if (!visibles.some((n) => n.id === estado.seleccionado)) {
    estado.seleccionado = (visibles[0] || {}).id;
  }

  const filas = document.getElementById('filas');
  filas.innerHTML = visibles.map((n) => `
    <button type="button" class="fila" data-id="${esc(n.id)}" ${n.id === estado.seleccionado ? 'aria-current="true"' : ''}
            aria-label="Ver ${esc(n.nombre)}, ${tipoTexto(n)}, ${esc(n.estado)}">
      <span class="fila__persona">
        <span class="avatar" style="width:40px;height:40px">${iconoTipo(n)}</span>
        <span><span class="fila__principal">${esc(n.nombre)}</span><span class="fila__secundario">${tipoTexto(n)}</span></span>
      </span>
      <span>${esc(dueno(n).nombre)}</span>
      <span class="suave">${esc(n.registro)}</span>
      <span>${chip(n.estado)}</span>
      ${ICONOS.flecha}
    </button>`).join('') || '<div class="vacio">No hay negocios que coincidan con la búsqueda o el filtro.</div>';

  filas.querySelectorAll('.fila').forEach((f) => f.addEventListener('click', () => {
    estado.seleccionado = f.dataset.id;
    pintar();
  }));

  pintarDetalle();
}

function pintarDetalle() {
  const detalle = document.getElementById('detalle');
  const n = d.negocios.find((x) => x.id === estado.seleccionado);
  if (!n) { detalle.innerHTML = '<p class="suave">No hay negocios.</p>'; return; }

  const dueno = Datos.usuario(d, n.duenoId);
  const reportes = d.reportes.filter((r) => r.negocioId === n.id);
  const suspendido = n.estado === 'Suspendido';
  const filasDatos = [
    ['Propietario', dueno.nombre],
    ['Correo', dueno.correo],
    ['Teléfono', dueno.telefono],
    [n.tipo === 'fijo' ? 'Dirección' : 'Ubicación', n.lugar],
    ['Registro', n.registro],
  ];

  detalle.innerHTML = `
    <div class="portada">Portada del negocio</div>
    <div style="display:flex;align-items:flex-end;gap:14px">
      <span class="logo-negocio">${iconoTipo(n)}</span>
      <span style="margin-left:auto">${chip(n.estado)}</span>
    </div>
    <div>
      <h2 style="margin:0;font-size:19px">${esc(n.nombre)}</h2>
      <p style="margin:2px 0 0;font-size:14px;color:var(--texto-suave)">${tipoTexto(n)} · ${esc(n.descripcion)}</p>
    </div>
    <dl class="datos">${filasDatos.map(([k, v]) => `<dt>${k}</dt><dd>${esc(v)}</dd>`).join('')}</dl>
    ${suspendido ? `
      <div class="alerta alerta--roja">
        <strong>No aparece en el Marketplace</strong>
        <span>Motivo: ${esc(n.motivo)}</span>
        <span>${esc(n.cuando)}</span>
        <span>El dueño ve «Suspendido» en Mi cuenta dentro de la app.</span>
      </div>
      <button type="button" class="boton boton--principal" id="reactivar">${ICONOS.check}Reactivar negocio</button>`
    : `<p class="alerta alerta--gris" style="margin:0">Para suspender un negocio, abre uno de sus reportes en Reportes y usa «Suspender este negocio».</p>`}
    ${reportes.length
      ? `<button type="button" class="boton" id="ver-reportes">${ICONOS.reportes}Ver sus reportes (${reportes.length})</button>`
      : '<p style="margin:0;text-align:center;font-size:13px;color:var(--texto-suave)">Este negocio no tiene reportes.</p>'}`;

  const reactivar = document.getElementById('reactivar');
  if (reactivar) {
    reactivar.addEventListener('click', async () => {
      await hacer(() => Datos.reactivarNegocio(n.id), `${n.nombre} vuelve a aparecer en el Marketplace.`);
      cargar();
    });
  }

  const verReportes = document.getElementById('ver-reportes');
  if (verReportes) verReportes.addEventListener('click', () => abrirReportesDe(n, reportes));
}

/** Cuadro con SOLO los reportes de este negocio. */
function abrirReportesDe(n, reportes) {
  abrirModal(`
    <div class="modal__cabecera">
      <div><p>Reportes del negocio</p><h2>${esc(n.nombre)}</h2></div>
      ${botonCerrarModal}
    </div>
    ${reportes.map((r) => `
      <article class="caso">
        <div style="display:flex;align-items:center;gap:8px">
          <span class="fila__secundario" style="font-weight:600">${esc(r.id)} · ${esc(r.fecha)}</span>
          <span style="margin-left:auto">${chip(r.estado)}</span>
        </div>
        <h3>${esc(r.motivo)}</h3>
        <span class="fila__secundario">Reportado por ${esc(Datos.usuario(d, r.usuarioId).nombre)}</span>
        <p class="cita" style="font-size:14px">${esc(r.descripcion)}</p>
      </article>`).join('')}
    <a class="boton boton--principal" href="reportes.html">Gestionar en Reportes</a>`);
}

document.getElementById('buscar').addEventListener('input', (e) => {
  estado.busqueda = e.target.value;
  if (d) pintar();
});

cargar();
