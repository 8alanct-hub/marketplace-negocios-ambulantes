/* Usuarios: lista A–Z, buscador, filtros y suspender / reactivar cuenta. */

protegerPagina();
pintarMenu('usuarios');
document.getElementById('icono-buscar').innerHTML = ICONOS.buscar;

const estado = { filtro: 'todos', busqueda: '', seleccionado: null };
let d = null; // datos cargados

const FILTROS = {
  todos: { texto: 'Todos', pasa: () => true },
  cliente: { texto: 'Clientes', pasa: (u) => u.rol === 'Cliente' },
  negocio: { texto: 'Negocios', pasa: (u) => u.rol === 'Negocio' },
  suspendido: { texto: 'Suspendidos', pasa: (u) => u.estado === 'Suspendido' },
};

function coincide(u) {
  const q = normalizar(estado.busqueda);
  if (!q) return true;
  const sinEspacios = (t) => normalizar(t).replace(/\s/g, '');
  return normalizar(`${u.nombre} ${u.correo}`).includes(q) || sinEspacios(u.telefono).includes(q.replace(/\s/g, ''));
}

/** Vuelve a pedir los datos y pinta la pantalla. */
async function cargar() {
  try {
    d = await Datos.cargarTodo();
  } catch (e) {
    document.getElementById('filas').innerHTML = `<div class="vacio">${esc(e.message || 'No se pudieron cargar los usuarios.')}</div>`;
    return;
  }
  pintar();
}

function pintar() {
  const conBusqueda = d.usuarios.filter(coincide);

  pintarFiltros(
    document.getElementById('filtros'),
    Object.entries(FILTROS).map(([id, f]) => ({ id, texto: f.texto, cuantos: conBusqueda.filter(f.pasa).length })),
    estado.filtro,
    (id) => { estado.filtro = id; pintar(); },
  );

  const visibles = conBusqueda.filter(FILTROS[estado.filtro].pasa).sort(porNombre);
  if (!d.usuarios.some((u) => u.id === estado.seleccionado)) {
    estado.seleccionado = (visibles[0] || d.usuarios[0] || {}).id;
  }

  const filas = document.getElementById('filas');
  filas.innerHTML = visibles.map((u) => `
    <button type="button" class="fila" data-id="${esc(u.id)}" ${u.id === estado.seleccionado ? 'aria-current="true"' : ''}
            aria-label="Ver ${esc(u.nombre)}, ${esc(u.rol)}, ${esc(u.estado)}">
      <span class="fila__persona">
        <span class="avatar">${esc(iniciales(u.nombre))}</span>
        <span><span class="fila__principal">${esc(u.nombre)}</span><span class="fila__secundario">${esc(u.correo)}</span></span>
      </span>
      <span>${esc(u.rol)}</span>
      <span class="suave">${esc(u.registro)}</span>
      <span>${chip(u.estado)}</span>
      ${ICONOS.flecha}
    </button>`).join('') || '<div class="vacio">No hay usuarios que coincidan con la búsqueda o el filtro.</div>';

  filas.querySelectorAll('.fila').forEach((f) => f.addEventListener('click', () => {
    estado.seleccionado = f.dataset.id;
    pintar();
  }));

  pintarDetalle();
}

function pintarDetalle() {
  const detalle = document.getElementById('detalle');
  const u = d.usuarios.find((x) => x.id === estado.seleccionado);
  if (!u) { detalle.innerHTML = '<p class="suave">No hay usuarios.</p>'; return; }

  const negocio = u.negocioId ? Datos.negocio(d, u.negocioId) : null;
  const suspendido = u.estado === 'Suspendido';
  const filasDatos = [
    ['Correo', u.correo],
    ['Teléfono', u.telefono],
    ['Registro', u.registro],
    u.rol === 'Cliente' ? ['Pedidos realizados', u.pedidos ?? 0] : ['Negocio', negocio ? negocio.nombre : '—'],
    ['Reportes enviados', d.reportes.filter((r) => r.usuarioId === u.id).length],
  ];

  detalle.innerHTML = `
    <div class="detalle__cabecera">
      <span class="avatar avatar--grande">${esc(iniciales(u.nombre))}</span>
      <div style="flex:1;min-width:0"><h2>${esc(u.nombre)}</h2><p>${esc(u.rol)}</p></div>
      ${chip(u.estado)}
    </div>
    <dl class="datos">${filasDatos.map(([k, v]) => `<dt>${k}</dt><dd>${esc(v)}</dd>`).join('')}</dl>
    ${suspendido ? `
      <div class="alerta alerta--roja">
        <strong>Cuenta suspendida</strong>
        <span>Motivo: ${esc(u.motivo)}</span>
        <span>${esc(u.cuando)}</span>
        <span>Mientras esté suspendida no puede iniciar sesión en la app.</span>
      </div>
      <button type="button" class="boton boton--principal" id="accion">${ICONOS.check}Reactivar cuenta</button>`
    : `<button type="button" class="boton boton--borde-rojo" id="accion">${ICONOS.pausa}Suspender cuenta</button>`}`;

  document.getElementById('accion').addEventListener('click', async () => {
    if (suspendido) {
      await hacer(() => Datos.reactivarUsuario(u.id), `La cuenta de ${u.nombre} está activa otra vez.`);
      cargar();
      return;
    }
    pedirMotivo({
      titulo: `Suspender a ${u.nombre}`,
      explicacion: 'No podrá iniciar sesión en la app hasta que reactives su cuenta. El motivo queda guardado en su historial.',
      etiqueta: 'Motivo de la suspensión',
      placeholder: 'Ej.: comentarios ofensivos en el chat con negocios.',
      boton: 'Suspender cuenta',
      alConfirmar: async (motivo) => {
        await hacer(() => Datos.suspenderUsuario(u.id, motivo), `Cuenta de ${u.nombre} suspendida.`);
        cargar();
      },
    });
  });
}

document.getElementById('buscar').addEventListener('input', (e) => {
  estado.busqueda = e.target.value;
  if (d) pintar();
});

cargar();
