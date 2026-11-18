/* Inicio de sesión del administrador. */

// Si ya inició sesión, va directo al Dashboard.
if (haySesion()) location.replace('dashboard.html');

const ojoAbierto = svg('<path d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z"/><circle cx="12" cy="12" r="3"/>');
const ojoCerrado = svg('<path d="M3 3l18 18"/><path d="M10.6 5.1A10 10 0 0 1 12 5c6 0 9.5 7 9.5 7a17 17 0 0 1-3.1 4"/><path d="M6.6 6.6A17 17 0 0 0 2.5 12S6 19 12 19a9.7 9.7 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>');

document.getElementById('logo').innerHTML = svg('<path d="M3 9l1.5-5h15L21 9"/><path d="M3 9h18v2a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0z"/><path d="M5 13v7h14v-7"/><path d="M10 20v-4h4v4"/>', 30);

const formulario = document.getElementById('formulario');
const correo = document.getElementById('correo');
const clave = document.getElementById('clave');
const verClave = document.getElementById('ver-clave');
const error = document.getElementById('error');

// Ojo para mostrar u ocultar la contraseña.
verClave.innerHTML = ojoAbierto;
verClave.addEventListener('click', () => {
  const mostrar = clave.type === 'password';
  clave.type = mostrar ? 'text' : 'password';
  verClave.innerHTML = mostrar ? ojoCerrado : ojoAbierto;
  verClave.setAttribute('aria-label', mostrar ? 'Ocultar contraseña' : 'Mostrar contraseña');
  verClave.setAttribute('aria-pressed', String(mostrar));
});

function mostrarError(texto) {
  error.innerHTML = `${ICONOS.alerta}<span>${esc(texto)}</span>`;
  error.hidden = false;
}

const botonEntrar = formulario.querySelector('button[type="submit"]');

formulario.addEventListener('submit', async (e) => {
  e.preventDefault();
  error.hidden = true;

  const email = correo.value.trim().toLowerCase();
  if (!email || !clave.value) {
    mostrarError('Escribe tu correo y tu contraseña.');
    return;
  }
  botonEntrar.disabled = true;
  botonEntrar.textContent = 'Entrando…';
  try {
    // Modo prueba: compara con la cuenta de prueba. Modo API: lo valida el servidor.
    const admin = await Datos.iniciarSesion(email, clave.value);
    guardarSesion(admin);
    location.href = 'dashboard.html';
  } catch (err) {
    mostrarError(err.message || 'No se pudo iniciar sesión.');
    botonEntrar.disabled = false;
    botonEntrar.textContent = 'Iniciar sesión';
  }
});
