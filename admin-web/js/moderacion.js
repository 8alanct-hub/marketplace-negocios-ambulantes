/* Moderación: un CONTENIDO puntual (foto, producto, descripción).
   Mantener, quitar (con aviso al dueño) o enviar a Reportes. */

protegerPagina();
pintarMenu('moderacion');
document.getElementById('icono-buscar').innerHTML = ICONOS.buscar;
document.getElementById('icono-mantener').innerHTML = ICONOS.ok;
document.getElementById('icono-quitar').innerHTML = ICONOS.basura;
document.getElementById('icono-enviar').innerHTML = ICONOS.enviar;

const estado = { filtro: 'revisar', busqueda: '' };
let d = null; // datos cargados

const FILTROS = {
  revisar: { texto: 'Por revisar', pasa: (c) => c.estado === 'Por revisar' },
  mantenido: { texto: 'Mantenidos', pasa: (c) => c.estado === 'Mantenido' },
  quitado: { texto: 'Quitados', pasa: (c) => c.estado === 'Quitado' },
  enviado: { texto: 'Enviados a Reportes', pasa: (c) => c.estado === 'Enviado a Reportes' },
  todos: { texto: 'Todos', pasa: () => true },
};

async function cargar() {
  try {
    d = await Datos.cargarTodo();
  } catch (e) {
    document.getElementById('filas').innerHTML = `<div class="vacio">${esc(e.message || 'No se pudo cargar el contenido.')}</div>`;
    return;
  }
  pintar();
  pintarMenu('moderacion');
}

function pintar() {
  const negocio = (c) => Datos.negocio(d, c.negocioId);

  const numero = numeroBuscado(estado.busqueda, 'mod');
  const q = normalizar(estado.busqueda);
  const coincide = (c) => !q || (numero !== null
    ? numeroDeId(c.id) === numero
    : normalizar(`${c.id} ${c.tipo} ${negocio(c).nombre} ${c.motivo}`).includes(q));
  const conBusqueda = d.moderacion.filter(coincide);

  pintarFiltros(
    document.getElementById('filtros'),
    Object.entries(FILTROS).map(([id, f]) => ({ id, texto: f.texto, cuantos: conBusqueda.filter(f.pasa).length })),
    estado.filtro,
    (id) => { estado.filtro = id; pintar(); },
  );

  const visibles = numero !== null ? conBusqueda : conBusqueda.filter(FILTROS[estado.filtro].pasa);
  const filas = document.getElementById('filas');
  filas.innerHTML = visibles.map((c) => `
    <button type="button" class="fila" data-id="${esc(c.id)}" aria-label="Ver ${esc(c.id)}: ${esc(c.tipo)} de ${esc(negocio(c).nombre)}, ${esc(c.estado)}">
      <span><span class="fila__principal">${esc(c.id)}</span><span class="fila__secundario">${esc(c.fecha)}</span></span>
      <span><span class="etiqueta-tipo">${esc(c.tipo)}</span></span>
      <span class="fila__principal">${esc(negocio(c).nombre)}</span>
      <span>${esc(c.motivo)}</span>
      <span>${chip(c.estado)}</span>
      ${ICONOS.flecha}
    </button>`).join('') || '<div class="vacio">No hay contenido que coincida con la búsqueda o el filtro.</div>';

  filas.querySelectorAll('.fila').forEach((f) => f.addEventListener('click', () => abrirCaso(f.dataset.id)));
}

/** Cuadro central con el contenido reportado. */
function abrirCaso(id) {
  const c = d.moderacion.find((x) => x.id === id);
  const negocio = Datos.negocio(d, c.negocioId);
  const quien = Datos.usuario(d, c.usuarioId);
  const porRevisar = c.estado === 'Por revisar';

  // ¿A este negocio ya se le quitó contenido antes? Entonces conviene enviarlo a Reportes.
  const quitadosAntes = d.moderacion.filter((x) => x.negocioId === c.negocioId && x.estado === 'Quitado' && x.id !== c.id);
  const que = c.tipo === 'Foto de producto' ? 'foto' : c.tipo === 'Producto' ? 'producto' : 'contenido';

  const foto = c.fotoUrl
    ? `<img src="${esc(c.fotoUrl)}" alt="Foto reportada: ${esc(c.titulo)}" style="width:120px;height:120px;object-fit:cover;border-radius:var(--radio);flex:none">`
    : `<div class="foto-vacia" role="img" aria-label="Espacio para la foto reportada">${ICONOS.foto}Foto reportada</div>`;
  const contenido = c.titulo
    ? `<div style="display:flex;gap:16px;align-items:center;padding:14px;background:var(--fondo);border-radius:var(--radio)">
         ${foto}
         <div><div class="fila__principal" style="font-size:16px">${esc(c.titulo)}</div><div>${esc(c.precio)}</div></div>
       </div>`
    : `<blockquote class="cita">${esc(c.texto)}</blockquote>`;

  const modal = abrirModal(`
    <div class="modal__cabecera">
      <div><p>${esc(c.id)} · ${esc(c.fecha)}</p><h2>${esc(c.tipo)}</h2></div>
      ${chip(c.estado)}
      ${botonCerrarModal}
    </div>

    <div><h3>Contenido reportado</h3>${contenido}</div>

    <dl class="datos datos--izquierda">
      <dt>Negocio</dt><dd><a href="negocios.html">${esc(negocio.nombre)}</a></dd>
      <dt>Motivo</dt><dd>${esc(c.motivo)}</dd>
      <dt>Reportado por</dt><dd>${esc(quien.nombre)}</dd>
      <dt>Origen</dt><dd>${esc(c.origen)}</dd>
    </dl>

    ${porRevisar && quitadosAntes.length ? `
      <div class="alerta alerta--amarilla" style="flex-direction:row;gap:10px">
        ${ICONOS.alerta}
        <span>Este negocio ya tuvo ${quitadosAntes.length} contenido(s) quitado(s) (${quitadosAntes.map((x) => esc(x.id)).join(', ')}). Si se repite, conviene enviarlo a Reportes para evaluar una suspensión.</span>
      </div>` : ''}

    ${porRevisar ? `
      <div class="campo">
        <label for="mensaje">Mensaje para el dueño <span>(se envía solo si quitas el contenido)</span></label>
        <textarea id="mensaje" rows="3">${esc(c.mensaje)}</textarea>
      </div>
      <div class="modal__acciones">
        <button type="button" class="boton boton--borde-azul" data-accion="reportes">Enviar a Reportes</button>
        <button type="button" class="boton" data-accion="mantener">Mantener</button>
        <button type="button" class="boton boton--peligro" data-accion="quitar">Quitar ${que}</button>
      </div>`
    : `
      <div class="modal__acciones" style="align-items:center">
        <p style="margin:0;flex:1 1 240px;font-size:14px;color:var(--texto-suave)">${esc(c.cierre)}</p>
        <button type="button" class="boton" data-accion="reabrir" style="flex:0 0 auto">Volver a revisar</button>
      </div>`}`);

  // "Quitar" solo se activa si hay mensaje para el dueño.
  const mensaje = modal.querySelector('#mensaje');
  const botonQuitar = modal.querySelector('[data-accion="quitar"]');
  if (mensaje) {
    const revisar = () => { botonQuitar.disabled = !mensaje.value.trim(); };
    mensaje.addEventListener('input', revisar);
    revisar();
  }

  const acciones = {
    mantener: () => hacer(() => Datos.cambiarEstadoContenido(c.id, 'Mantenido'), `${c.id}: el contenido se mantiene publicado.`),
    quitar: (texto) => hacer(() => Datos.cambiarEstadoContenido(c.id, 'Quitado', texto), `${c.id}: contenido quitado y aviso enviado al dueño.`),
    reabrir: () => hacer(() => Datos.cambiarEstadoContenido(c.id, 'Por revisar'), `${c.id} volvió a «Por revisar».`),
    reportes: () => hacer(() => Datos.enviarContenidoAReportes(c.id), (nuevoId) => `${c.id} se envió a Reportes como ${nuevoId}.`),
  };
  modal.querySelectorAll('[data-accion]').forEach((b) => b.addEventListener('click', async () => {
    const texto = mensaje ? mensaje.value.trim() : '';
    cerrarModal();
    await acciones[b.dataset.accion](texto);
    cargar();
  }));
}

document.getElementById('buscar').addEventListener('input', (e) => {
  estado.busqueda = e.target.value;
  if (d) pintar();
});

cargar();
