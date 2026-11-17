# Base de datos · Ecosistema para negocios

**PostgreSQL en Supabase** — proyecto `ecosistema-negocios` (región São Paulo, plan gratis).

- URL del proyecto: `https://commhwaijcyyfwleyopt.supabase.co`
- Panel: https://supabase.com/dashboard/project/commhwaijcyyfwleyopt

Ya está creada y con datos de prueba. Estos archivos sirven para **volver a crearla**
(en otro proyecto, o en un PostgreSQL local) y para ver cómo está hecha.

## Archivos (se ejecutan en orden)

| Archivo | Qué hace |
|---|---|
| `01_esquema.sql` | Tablas, reglas (CHECK), índices, triggers y seguridad (RLS). |
| `02_vistas_y_funciones.sql` | Vistas para el panel web y funciones (login, registro, enviar entre Reportes y Moderación). |
| `03_datos_prueba.sql` | Los mismos datos de prueba de la app y del panel. Contraseña de todas las cuentas: `Prueba123`. |

En Supabase: **SQL Editor → New query**, pegar cada archivo y **Run**, en orden.

## Tablas

| Tabla | Para qué |
|---|---|
| `usuarios` | Clientes, dueños de negocio y administradores (`rol`). Contraseña cifrada con bcrypt. `estado`: activo / suspendido (con motivo, quién y cuándo). |
| `negocios` | Uno por dueño. `tipo`: fijo / ambulante. Ubicación, logo, portada, colores. `estado`: activo / suspendido. |
| `modalidades_pago`, `negocio_modalidad_pago` | "Pago en el negocio" y "Contraentrega" (la app no procesa pagos). |
| `categorias`, `productos` | Precio en `numeric(12,2)`, stock, disponible. `activo = false` en vez de borrar (por los pedidos). |
| `pedidos`, `detalle_pedido` | Estados: pendiente, aceptado, en_preparacion, listo, entregado, rechazado, cancelado. Rechazar/cancelar exige motivo. El detalle guarda el precio del momento. |
| `resenas` | Una por pedido, calificación 1 a 5. |
| `conversaciones`, `mensajes` | Chat cliente–negocio (una conversación por pareja). |
| `reportes` | Quejas sobre un **negocio**. |
| `moderacion` | Un **contenido** puntual (foto, producto, descripción). |

Cambio respecto al diagrama original: `negocio_configuracion` se unió a `negocios`
(tenía logo, portada y descripción repetidos); solo se conservaron los colores.

## Vistas

| Vista | Uso |
|---|---|
| `v_admin_usuarios`, `v_admin_negocios`, `v_admin_reportes`, `v_admin_moderacion` | Devuelven los datos **con los mismos nombres y textos que espera el panel web** (`admin-web/API.md`). La API solo hace `select * from v_admin_reportes` y lo devuelve como JSON. |
| `v_negocios_publicados` | Para la app: solo negocios activos, de dueños activos, con nombre y ubicación (Marketplace). |

## Funciones

```sql
-- Registro (cifra la contraseña). Devuelve el id nuevo.
select registrar_usuario('Ana', 'Paz', '300 000 0000', 'ana@correo.com', 'Clave1234');

-- Login: devuelve el usuario si coincide (0 filas si no). Para el panel, revisar rol = 'admin'.
select * from verificar_login('admin@test.com', 'Prueba123');

-- Botones "Enviar a…" del panel (tocan dos tablas a la vez):
select admin_enviar_reporte_a_moderacion(4, 1);   -- reporte 4, admin 1 → devuelve 'MOD-005'
select admin_enviar_contenido_a_reportes(2, 1);   -- caso 2, admin 1  → devuelve 'REP-005'
```

## Seguridad (importante)

- Todas las tablas tienen **RLS activado sin políticas**, y las vistas y funciones no se pueden
  usar con la llave pública (`anon`). Es decir: **nadie puede leer ni escribir desde fuera con la
  llave pública**. Supabase lo muestra como aviso informativo ("RLS Enabled No Policy"); es a propósito.
- La **API** se conecta con la **cadena de conexión** de PostgreSQL (Supabase → *Connect*) o con la
  llave `service_role`. Esas credenciales van **solo en el servidor de la API**, nunca en la app,
  en la web ni en GitHub.

## Notas para la API

- Los `id` que devuelven las vistas son texto: usuarios y negocios `"3"`, reportes `"REP-004"`,
  moderación `"MOD-002"`. Para las rutas `PATCH /admin/reportes/REP-004` la API toma el número (`4`).
- Estados guardados en la base de datos (minúscula, sin tildes) → texto del panel:
  - reportes: `pendiente`→Pendiente, `en_revision`→En revisión, `resuelto`, `descartado`, `enviado_moderacion`→Enviado a Moderación
  - moderación: `por_revisar`→Por revisar, `mantenido`, `quitado`, `enviado_reportes`→Enviado a Reportes
- Al cerrar un reporte o caso, guardar también `cerrado_por` (id del admin) y `fecha_cierre = now()`;
  la vista arma el texto "Resuelto el … por …".
- Al suspender: `estado = 'suspendido'`, `motivo_suspension`, `suspendido_por`, `fecha_suspension = now()`.
  Al reactivar: `estado = 'activo'` y esos tres en `null`.
- Fechas y horas se muestran en hora de Colombia (`America/Bogota`).
