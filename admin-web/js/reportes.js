/* Reportes: quejas sobre un NEGOCIO.
   Desde aquí se resuelve, se descarta, se envía a Moderación
   o se suspende el negocio. */

protegerPagina();
pintarMenu('reportes');
document.getElementById('icono-buscar').innerHTML = ICONOS.buscar;

const estado = { filtro: 'revisar', busqueda: '' };
let d = null; // datos cargados

const abierto = (r) => r.estado === 'Pendiente' || r.estado === 'En revisión';
const FILTROS = {
  revisar: { texto: 'Por revisar', pasa: abierto },
  resuelto: { texto: 'Resueltos', pasa: (r) => r.estado === 'Resuelto' },
  descartado: { texto: 'Descartados', pasa: (r) => r.estado === 'Descartado' },
  enviado: { texto: 'Enviados a Moderación', pasa: (r) => r.estado === 'Enviado a Moderación' },
  todos: { texto: 'Todos', pasa: () => true },
};

async function cargar() {
  try {
    d = await Datos.cargarTodo();
  } catch (e) {
    document.getElementById('filas').innerHTML = `<div class="vacio">${esc(e.message || 'No se pudieron cargar los reportes.')}</div>`;
    return;
  }
  pintar();
  pintarMenu('reportes');
}

function pintar() {
  const negocio = (r) => Datos.negocio(d, r.negocioId);
  const quien = (r) => Datos.usuario(d, r.usuarioId);

  // Por número ("3", "REP-003"…) se busca ese reporte aunque esté en otro estado.
  const numero = numeroBuscado(estado.busqueda, 'rep');
  const q = normalizar(estado.busqueda);
  const coincide = (r) => !q || (numero !== null
    ? numeroDeId(r.id) === numero
    : normalizar(`${r.id} ${negocio(r).nombre} ${quien(r).nombre} ${r.motivo}`).includes(q));
  const conBusqueda = d.reportes.filter(coincide);

  pintarFiltros(
    document.getElementById('filtros'),
    Object.entries(FILTROS).map(([id, f]) => ({ id, texto: f.texto, cuantos: conBusqueda.filter(f.pasa).length })),
    estado.filtro,
    (id) => { estado.filtro = id; pintar(); },
  );

  const visibles = numero !== null ? conBusqueda : conBusqueda.filter(FILTROS[estado.filtro].pasa);
  const filas = document.getElementById('filas');
  filas.innerHTML = visibles.map((r) => `
    <button type="button" class="fila" data-id="${esc(r.id)}" aria-label="Ver ${esc(r.id)}: ${esc(negocio(r).nombre)}, ${esc(r.motivo)}, ${esc(r.estado)}">
      <span><span class="fila__principal">${esc(r.id)}</span><span class="fila__secundario">${esc(r.fecha)}</span></span>
      <span class="fila__principal">${esc(negocio(r).nombre)}</span>
      <span>${esc(r.motivo)}</span>
      <span class="suave">${esc(quien(r).nombre)}</span>
      <span>${chip(r.estado)}</span>
      ${ICONOS.flecha}
    </button>`).join('') || '<div class="vacio">No hay reportes que coincidan con la búsqueda o el filtro.</div>';

  filas.querySelectorAll('.fila').forEach((f) => f.addEventListener('click', () => abrirReporte(f.dataset.id)));
}

/** Cuadro central con el detalle del reporte. */
function abrirReporte(id) {
  const r = d.reportes.find((x) => x.id === id);
  const negocio = Datos.negocio(d, r.negocioId);
  const dueno = Datos.usuario(d, negocio.duenoId);
  const quien = Datos.usuario(d, r.usuarioId);
  const negocioSuspendido = negocio.estado === 'Suspendido';

  const modal = abrirModal(`
    <div class="modal__cabecera">
      <div><p>${esc(r.id)} · ${esc(r.fecha)}, ${esc(r.hora)}</p><h2>${esc(r.motivo)}</h2></div>
      ${chip(r.estado)}
      ${botonCerrarModal}
    </div>

    <div class="tarjetas-personas">
      <a class="tarjeta-persona" href="usuarios.html">
        <span class="avatar">${esc(iniciales(quien.nombre))}</span>
        <span><span class="fila__secundario">Reportado por</span><span class="fila__principal">${esc(quien.nombre)}</span><span class="fila__secundario">${esc(quien.correo)}</span></span>
      </a>
      <a class="tarjeta-persona" href="negocios.html">
        <span class="avatar">${ICONOS.tienda}</span>
        <span><span class="fila__secundario">Negocio reportado</span><span class="fila__principal">${esc(negocio.nombre)}</span><span class="fila__secundario">${esc(dueno.nombre)} · ${esc(negocio.estado)}</span></span>
      </a>
    </div>

    <div>
      <h3>Detalle del reporte</h3>
      <p class="cita">${esc(r.descripcion)}</p>
      <p class="fila__secundario" style="margin-top:6px">Origen: ${esc(r.origen)}</p>
    </div>

    <div class="campo">
      <label for="nota">Nota interna <span>(opcional, solo la ven los administradores)</span></label>
      <textarea id="nota" rows="3" placeholder="Ej.: Se habló con el negocio por teléfono y actualizó su ubicación.">${esc(r.nota)}</textarea>
    </div>

    ${abierto(r) ? `
      <div class="modal__acciones">
        <button type="button" class="boton boton--principal" data-accion="resolver">Marcar como resuelto</button>
        ${r.estado === 'Pendiente' ? '<button type="button" class="boton" data-accion="revision">Pasar a «En revisión»</button>' : ''}
        <button type="button" class="boton boton--borde-morado" data-accion="moderacion">Enviar a Moderación</button>
        <button type="button" class="boton" data-accion="descartar">Descartar</button>
      </div>
      ${negocioSuspendido
        ? '<p style="margin:0;font-size:14px;color:var(--error)">Este negocio ya está suspendido. Se reactiva desde Negocios.</p>'
        : `<button type="button" class="enlace-rojo" data-accion="suspender">${ICONOS.pausa}Suspender este negocio…</button>`}`
    : `
      <div class="modal__acciones" style="align-items:center">
        <p style="margin:0;flex:1 1 240px;font-size:14px;color:var(--texto-suave)">${esc(r.cierre)}</p>
        <button type="button" class="boton" data-accion="reabrir" style="flex:0 0 auto">Reabrir reporte</button>
      </div>`}`);

  const acciones = {
    resolver: () => hacer(() => Datos.cambiarEstadoReporte(r.id, 'Resuelto'), `${r.id} marcado como resuelto.`),
    revision: () => hacer(() => Datos.cambiarEstadoReporte(r.id, 'En revisión'), `${r.id} pasó a «En revisión».`),
    descartar: () => hacer(() => Datos.cambiarEstadoReporte(r.id, 'Descartado'), `${r.id} descartado.`),
    reabrir: () => hacer(() => Datos.cambiarEstadoReporte(r.id, 'Pendiente'), `${r.id} volvió a «Pendiente».`),
    moderacion: () => hacer(() => Datos.enviarReporteAModeracion(r.id), (nuevoId) => `${r.id} se envió a Moderación como ${nuevoId}.`),
  };

  modal.querySelectorAll('[data-accion]').forEach((b) => b.addEventListener('click', async () => {
    const nota = modal.querySelector('#nota').value;
    const accion = b.dataset.accion;
    cerrarModal();
    // Guardar la nota si cambió.
    if (nota !== (r.nota || '')) await hacer(() => Datos.guardarNotaReporte(r.id, nota));
    if (accion === 'suspender') {
      suspenderNegocio(r, negocio);
      return;
    }
    await acciones[accion]();
    cargar();
  }));
}

/** Suspender el negocio del reporte (pide motivo). */
function suspenderNegocio(r, negocio) {
  pedirMotivo({
    titulo: `Suspender ${negocio.nombre}`,
    explicacion: 'Dejará de aparecer en el Marketplace y no recibirá pedidos hasta que lo reactives. El dueño verá «Suspendido» en Mi cuenta.',
    etiqueta: 'Motivo de la suspensión',
    texto: `Reporte ${r.id}: ${r.motivo.toLowerCase()}.`,
    boton: 'Suspender negocio',
    alCancelar: async () => { await cargar(); abrirReporte(r.id); },
    alConfirmar: async (motivo) => {
      await hacer(() => Datos.suspenderNegocio(negocio.id, motivo), `${negocio.nombre} quedó suspendido y ya no aparece en el Marketplace.`);
      cargar();
    },
  });
}

document.getElementById('buscar').addEventListener('input', (e) => {
  estado.busqueda = e.target.value;
  if (d) pintar();
});

cargar();
