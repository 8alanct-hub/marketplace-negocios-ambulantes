-- =====================================================================
--  02 · VISTAS Y FUNCIONES
-- ---------------------------------------------------------------------
--  · Vistas v_admin_*: devuelven los datos EXACTAMENTE con los nombres y
--    textos que espera el panel web (ver admin-web/API.md). La API solo
--    hace:  SELECT * FROM v_admin_usuarios;   y lo devuelve como JSON.
--  · Funciones: login, registro y los "enviar a" entre Reportes y
--    Moderación (que tocan dos tablas a la vez).
-- =====================================================================

-- ---------------------------------------------------------------------
--  Ayudas de formato (zona horaria de Colombia)
-- ---------------------------------------------------------------------
create or replace function public.fmt_fecha(t timestamptz)
returns text language sql immutable set search_path = ''
as $$ select to_char(t at time zone 'America/Bogota', 'DD/MM/YYYY') $$;

create or replace function public.fmt_hora(t timestamptz)
returns text language sql immutable set search_path = ''
as $$ select lower(replace(replace(to_char(t at time zone 'America/Bogota', 'FMHH12:MI AM'), 'AM', 'a. m.'), 'PM', 'p. m.')) $$;

-- 180000 → "$ 180.000"
create or replace function public.fmt_precio(p numeric)
returns text language sql immutable set search_path = ''
as $$ select '$ ' || replace(to_char(round(p), 'FM999,999,999,990'), ',', '.') $$;

-- "13/11/2026 · por Andrés Mejía"  (o "13/11/2026 por Andrés Mejía")
create or replace function public.fmt_firma(fecha timestamptz, id_admin bigint, separador text default ' · por ')
returns text language sql stable set search_path = ''
as $$
  select public.fmt_fecha(fecha) || coalesce(separador || (
           select u.nombre || ' ' || u.apellido from public.usuarios u where u.id_usuario = id_admin), '')
$$;

-- ---------------------------------------------------------------------
--  VISTAS PARA EL PANEL DE ADMINISTRACIÓN
-- ---------------------------------------------------------------------

-- GET /admin/usuarios  (clientes y dueños; los administradores no salen)
create or replace view public.v_admin_usuarios
with (security_invoker = true) as
select
  u.id_usuario::text                                         as "id",
  u.nombre || ' ' || u.apellido                              as "nombre",
  u.correo                                                   as "correo",
  u.telefono                                                 as "telefono",
  case u.rol when 'cliente' then 'Cliente' else 'Negocio' end as "rol",
  public.fmt_fecha(u.fecha_registro)                         as "registro",
  initcap(u.estado)                                          as "estado",
  (select count(*) from public.pedidos p where p.id_usuario = u.id_usuario)::int as "pedidos",
  (select n.id_negocio::text from public.negocios n where n.id_usuario = u.id_usuario) as "negocioId",
  u.motivo_suspension                                        as "motivo",
  case when u.estado = 'suspendido'
       then public.fmt_firma(u.fecha_suspension, u.suspendido_por) end as "cuando"
from public.usuarios u
where u.rol in ('cliente', 'negocio')
order by u.nombre, u.apellido;

-- GET /admin/negocios
create or replace view public.v_admin_negocios
with (security_invoker = true) as
select
  n.id_negocio::text                                         as "id",
  n.nombre_comercial                                         as "nombre",
  n.tipo                                                     as "tipo",
  n.descripcion                                              as "descripcion",
  n.id_usuario::text                                         as "duenoId",
  case
    when n.tipo = 'fijo' then n.direccion
    when n.ubicacion_actualizada is null then 'Sin ubicación'
    else 'Actualizada el ' || public.fmt_fecha(n.ubicacion_actualizada) || ', ' || public.fmt_hora(n.ubicacion_actualizada)
  end                                                        as "lugar",
  public.fmt_fecha(n.fecha_registro)                         as "registro",
  initcap(n.estado)                                          as "estado",
  n.motivo_suspension                                        as "motivo",
  case when n.estado = 'suspendido'
       then public.fmt_firma(n.fecha_suspension, n.suspendido_por) end as "cuando"
from public.negocios n
order by n.nombre_comercial;

-- GET /admin/reportes  (más recientes primero)
create or replace view public.v_admin_reportes
with (security_invoker = true) as
select
  'REP-' || lpad(r.id_reporte::text, 3, '0')                 as "id",
  r.id_negocio::text                                         as "negocioId",
  r.id_usuario::text                                         as "usuarioId",
  r.motivo                                                   as "motivo",
  r.descripcion                                              as "descripcion",
  public.fmt_fecha(r.fecha_creacion)                         as "fecha",
  public.fmt_hora(r.fecha_creacion)                          as "hora",
  case r.estado
    when 'pendiente'          then 'Pendiente'
    when 'en_revision'        then 'En revisión'
    when 'resuelto'           then 'Resuelto'
    when 'descartado'         then 'Descartado'
    when 'enviado_moderacion' then 'Enviado a Moderación'
  end                                                        as "estado",
  case when r.id_moderacion_origen is null then 'Un cliente desde la app'
       else 'Enviado desde Moderación (MOD-' || lpad(r.id_moderacion_origen::text, 3, '0') || ')' end as "origen",
  r.nota_interna                                             as "nota",
  case r.estado
    when 'resuelto'   then 'Resuelto el ' || public.fmt_firma(r.fecha_cierre, r.cerrado_por, ' por ') || '.'
    when 'descartado' then 'Descartado el ' || public.fmt_firma(r.fecha_cierre, r.cerrado_por, ' por ') || '.'
    when 'enviado_moderacion' then 'Enviado a Moderación como ' || coalesce(
           (select 'MOD-' || lpad(m.id_moderacion::text, 3, '0') from public.moderacion m
             where m.id_reporte_origen = r.id_reporte order by m.id_moderacion desc limit 1), '—')
           || ' el ' || public.fmt_firma(r.fecha_cierre, r.cerrado_por, ' por ') || '.'
    else ''
  end                                                        as "cierre"
from public.reportes r
order by r.fecha_creacion desc;

-- GET /admin/moderacion  (más recientes primero)
create or replace view public.v_admin_moderacion
with (security_invoker = true) as
select
  'MOD-' || lpad(m.id_moderacion::text, 3, '0')              as "id",
  case m.tipo
    when 'foto_producto'       then 'Foto de producto'
    when 'producto'            then 'Producto'
    when 'descripcion_negocio' then 'Descripción del negocio'
    when 'contenido_negocio'   then 'Contenido del negocio'
  end                                                        as "tipo",
  m.id_negocio::text                                         as "negocioId",
  m.id_usuario::text                                         as "usuarioId",
  case when m.tipo = 'foto_producto' then p.nombre end       as "titulo",
  case when m.tipo = 'foto_producto' then public.fmt_precio(p.precio) end as "precio",
  case when m.tipo = 'foto_producto' then p.imagen_url end   as "fotoUrl",
  case when m.tipo = 'foto_producto' then ''
       when m.tipo = 'producto' and m.contenido_texto = '' then p.nombre || ' — ' || public.fmt_precio(p.precio)
       else m.contenido_texto end                            as "texto",
  m.motivo                                                   as "motivo",
  public.fmt_fecha(m.fecha_creacion)                         as "fecha",
  case m.estado
    when 'por_revisar'      then 'Por revisar'
    when 'mantenido'        then 'Mantenido'
    when 'quitado'          then 'Quitado'
    when 'enviado_reportes' then 'Enviado a Reportes'
  end                                                        as "estado",
  case when m.id_reporte_origen is null then 'Un cliente desde la app'
       else 'Enviado desde Reportes (REP-' || lpad(m.id_reporte_origen::text, 3, '0') || ')' end as "origen",
  m.mensaje_dueno                                            as "mensaje",
  case m.estado
    when 'mantenido' then 'Mantenido el ' || public.fmt_firma(m.fecha_cierre, m.cerrado_por, ' por ') || '.'
    when 'quitado'   then 'Quitado el ' || public.fmt_firma(m.fecha_cierre, m.cerrado_por, ' por ') || '. Se avisó al dueño.'
    when 'enviado_reportes' then 'Enviado a Reportes como ' || coalesce(
           (select 'REP-' || lpad(r.id_reporte::text, 3, '0') from public.reportes r
             where r.id_moderacion_origen = m.id_moderacion order by r.id_reporte desc limit 1), '—')
           || ' el ' || public.fmt_firma(m.fecha_cierre, m.cerrado_por, ' por ') || '. El contenido sigue publicado hasta que se decida allí.'
    else ''
  end                                                        as "cierre"
from public.moderacion m
left join public.productos p on p.id_producto = m.id_producto
order by m.fecha_creacion desc;

-- ---------------------------------------------------------------------
--  Para la APP: negocios que salen en el Marketplace
-- ---------------------------------------------------------------------
create or replace view public.v_negocios_publicados
with (security_invoker = true) as
select n.*
from public.negocios n
join public.usuarios u on u.id_usuario = n.id_usuario
where n.estado = 'activo'
  and u.estado = 'activo'
  and n.nombre_comercial <> ''
  and n.latitud is not null;

-- ---------------------------------------------------------------------
--  FUNCIONES
-- ---------------------------------------------------------------------

-- Registro: guarda la contraseña cifrada (bcrypt). Devuelve el id nuevo.
create or replace function public.registrar_usuario(
  p_nombre text, p_apellido text, p_telefono text, p_correo text, p_clave text)
returns bigint
language plpgsql
set search_path = ''
as $$
declare
  nuevo_id bigint;
begin
  if length(p_clave) < 8 then
    raise exception 'La contraseña debe tener al menos 8 caracteres.';
  end if;
  insert into public.usuarios (nombre, apellido, telefono, correo, password_hash)
  values (trim(p_nombre), trim(p_apellido), trim(p_telefono), lower(trim(p_correo)),
          extensions.crypt(p_clave, extensions.gen_salt('bf')))
  returning id_usuario into nuevo_id;
  return nuevo_id;
exception
  when unique_violation then
    raise exception 'Este correo ya tiene una cuenta.';
end;
$$;

-- Inicio de sesión: devuelve el usuario si correo y contraseña coinciden
-- (y no está suspendido). Si no coincide, no devuelve filas.
-- Para el panel web, la API además revisa que rol = 'admin'.
create or replace function public.verificar_login(p_correo text, p_clave text)
returns table (id_usuario bigint, nombre text, apellido text, correo text, rol text, estado text)
language sql
stable
set search_path = ''
as $$
  select u.id_usuario, u.nombre, u.apellido, u.correo, u.rol, u.estado
  from public.usuarios u
  where lower(u.correo) = lower(trim(p_correo))
    and u.password_hash = extensions.crypt(p_clave, u.password_hash)
$$;

-- Reportes → Moderación: crea el caso de moderación y cierra el reporte.
-- Devuelve el número del caso nuevo (ej. 'MOD-005').
create or replace function public.admin_enviar_reporte_a_moderacion(p_id_reporte bigint, p_id_admin bigint)
returns text
language plpgsql
set search_path = ''
as $$
declare
  r public.reportes;
  nuevo_id bigint;
begin
  select * into r from public.reportes where id_reporte = p_id_reporte for update;
  if not found then raise exception 'No existe el reporte %.', p_id_reporte; end if;
  if r.estado not in ('pendiente', 'en_revision') then
    raise exception 'El reporte ya está cerrado.';
  end if;

  insert into public.moderacion (tipo, id_negocio, id_usuario, contenido_texto, motivo, id_reporte_origen)
  values ('contenido_negocio', r.id_negocio, r.id_usuario, r.descripcion, r.motivo, r.id_reporte)
  returning id_moderacion into nuevo_id;

  update public.reportes
     set estado = 'enviado_moderacion', cerrado_por = p_id_admin, fecha_cierre = now()
   where id_reporte = p_id_reporte;

  return 'MOD-' || lpad(nuevo_id::text, 3, '0');
end;
$$;

-- Moderación → Reportes: crea un reporte nuevo y cierra el caso.
-- El contenido sigue publicado. Devuelve el número del reporte (ej. 'REP-005').
create or replace function public.admin_enviar_contenido_a_reportes(p_id_moderacion bigint, p_id_admin bigint)
returns text
language plpgsql
set search_path = ''
as $$
declare
  m public.moderacion;
  nuevo_id bigint;
begin
  select * into m from public.moderacion where id_moderacion = p_id_moderacion for update;
  if not found then raise exception 'No existe el caso %.', p_id_moderacion; end if;
  if m.estado <> 'por_revisar' then
    raise exception 'El caso ya fue revisado.';
  end if;

  insert into public.reportes (id_negocio, id_usuario, motivo, descripcion, id_moderacion_origen)
  values (m.id_negocio, m.id_usuario, m.motivo,
          coalesce(nullif(m.contenido_texto, ''), 'Contenido reportado en Moderación (MOD-' || lpad(m.id_moderacion::text, 3, '0') || ').'),
          m.id_moderacion)
  returning id_reporte into nuevo_id;

  update public.moderacion
     set estado = 'enviado_reportes', cerrado_por = p_id_admin, fecha_cierre = now()
   where id_moderacion = p_id_moderacion;

  return 'REP-' || lpad(nuevo_id::text, 3, '0');
end;
$$;

-- ---------------------------------------------------------------------
--  SEGURIDAD: nada de esto se puede usar con la llave pública de Supabase.
--  Solo la API (conectada como dueña de la base de datos) lo usa.
-- ---------------------------------------------------------------------
do $$
declare
  rol_publico text;
begin
  foreach rol_publico in array array['anon', 'authenticated'] loop
    if exists (select 1 from pg_roles where rolname = rol_publico) then
      execute format('revoke all on all tables in schema public from %I', rol_publico);
      execute format('revoke execute on all functions in schema public from %I', rol_publico);
    end if;
  end loop;
end;
$$;

revoke execute on function
  public.fmt_fecha(timestamptz), public.fmt_hora(timestamptz), public.fmt_precio(numeric),
  public.fmt_firma(timestamptz, bigint, text),
  public.registrar_usuario(text, text, text, text, text),
  public.verificar_login(text, text),
  public.admin_enviar_reporte_a_moderacion(bigint, bigint),
  public.admin_enviar_contenido_a_reportes(bigint, bigint)
from public;
