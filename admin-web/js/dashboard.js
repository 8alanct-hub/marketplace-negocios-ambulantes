/* Dashboard: resumen de la plataforma y reportes recientes. */

protegerPagina();
pintarMenu('dashboard');

const fecha = new Date().toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
document.getElementById('fecha').textContent = fecha.charAt(0).toUpperCase() + fecha.slice(1);
document.getElementById('saludo').textContent = `Hola, ${(adminActual()?.nombre || '').split(' ')[0]}`;

let d = null; // datos cargados

async function pintar() {
  try {
    d = await Datos.cargarTodo();
  } catch (e) {
    document.getElementById('resumen').innerHTML = `<div class="panel vacio">${esc(e.message || 'No se pudieron cargar los datos.')}</div>`;
    return;
  }

  // ---- Tarjetas de resumen (cifras calculadas con los datos) ----
  const clientes = d.usuarios.filter((u) => u.rol === 'Cliente').length;
  const duenos = d.usuarios.filter((u) => u.rol === 'Negocio').length;
  const activos = d.negocios.filter((n) => n.estado === 'Activo').length;
  const suspendidos = d.negocios.length - activos;
  const pendientes = d.reportes.filter((r) => r.estado === 'Pendiente').length;
  const enRevision = d.reportes.filter((r) => r.estado === 'En revisión').length;
  const porModerar = d.moderacion.filter((c) => c.estado === 'Por revisar').length;

  const tarjeta = (pagina, titulo, icono, numero, detalle) => `
    <a class="panel tarjeta" href="${pagina}">
      <span class="tarjeta__titulo"><span>${titulo}</span>${icono}</span>
      <span class="tarjeta__numero">${numero}</span>
      <span class="tarjeta__detalle">${detalle}</span>
    </a>`;

  document.getElementById('resumen').innerHTML =
    tarjeta('usuarios.html', 'Usuarios', ICONOS.usuarios, d.usuarios.length, `${clientes} clientes · ${duenos} dueños de negocio`) +
    tarjeta('negocios.html', 'Negocios', ICONOS.tienda, d.negocios.length, `${activos} activos · ${suspendidos} suspendidos`) +
    tarjeta('reportes.html', 'Reportes por revisar', ICONOS.reportes, pendientes + enRevision, `${pendientes} pendientes · ${enRevision} en revisión`) +
    tarjeta('moderacion.html', 'Contenido por moderar', ICONOS.moderacion, porModerar, 'Fotos, productos y descripciones');

  // ---- Reportes recientes (los 3 primeros) ----
  const contenedor = document.getElementById('reportes-recientes');
  contenedor.innerHTML = d.reportes.slice(0, 3).map((r) => `
    <button type="button" class="fila" data-id="${esc(r.id)}" aria-label="Ver ${esc(r.id)}: ${esc(Datos.negocio(d, r.negocioId).nombre)}, ${esc(r.motivo)}">
      <span><span class="fila__principal">${esc(Datos.negocio(d, r.negocioId).nombre)}</span><span class="fila__secundario">por ${esc(Datos.usuario(d, r.usuarioId).nombre)}</span></span>
      <span>${esc(r.motivo)}</span>
      <span class="suave">${esc(r.fecha)}</span>
      <span>${chip(r.estado)}</span>
      ${ICONOS.flecha}
    </button>`).join('') || '<div class="vacio">Aún no hay reportes.</div>';

  contenedor.querySelectorAll('.fila').forEach((fila) =>
    fila.addEventListener('click', () => abrirReporte(fila.dataset.id)));
}

/** Cuadro central con el detalle del reporte. */
function abrirReporte(id) {
  const r = d.reportes.find((x) => x.id === id);
  const negocio = Datos.negocio(d, r.negocioId);
  const dueno = Datos.usuario(d, negocio.duenoId);
  const quien = Datos.usuario(d, r.usuarioId);
  const abierto = r.estado === 'Pendiente' || r.estado === 'En revisión';

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
      <h3>Lo que escribió el cliente</h3>
      <p class="cita">${esc(r.descripcion)}</p>
    </div>
    <div class="modal__acciones">
      ${abierto ? '<button type="button" class="boton boton--principal" data-resolver>Marcar como resuelto</button>' : ''}
      <a class="boton" href="reportes.html">Abrir en Reportes</a>
    </div>`);

  const resolver = modal.querySelector('[data-resolver]');
  if (resolver) {
    resolver.addEventListener('click', async () => {
      cerrarModal();
      await hacer(() => Datos.cambiarEstadoReporte(r.id, 'Resuelto'), `${r.id} marcado como resuelto.`);
      pintar();
      pintarMenu('dashboard');
    });
  }
}

pintar();
