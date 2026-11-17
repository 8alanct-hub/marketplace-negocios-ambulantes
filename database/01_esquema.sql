-- =====================================================================
--  Ecosistema para negocios y emprendimientos independientes
--  01 · ESQUEMA (tablas, reglas e índices) — PostgreSQL / Supabase
-- ---------------------------------------------------------------------
--  Reglas del proyecto que se reflejan aquí:
--  · La app NO procesa pagos: solo "Pago en el negocio" o "Contraentrega".
--  · No hay domicilios propios: el pedido no guarda datos de entrega.
--  · El tipo (fijo / ambulante) es del NEGOCIO, no del producto.
--  · Solo los negocios ACTIVOS aparecen en el Marketplace.
--  · Reportes = quejas sobre un negocio. Moderación = un contenido puntual.
--  Los textos de estado se guardan en minúscula y sin tildes
--  (ej. 'en_revision'); las vistas de 02_vistas.sql los muestran bonitos.
-- =====================================================================

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;  -- para cifrar contraseñas

-- Pone la fecha de actualización automáticamente en cada UPDATE.
create or replace function public.tocar_fecha_actualizacion()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.fecha_actualizacion := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
--  USUARIOS (clientes, dueños de negocio y administradores)
-- ---------------------------------------------------------------------
create table public.usuarios (
  id_usuario          bigint generated always as identity primary key,
  nombre              text        not null check (length(trim(nombre)) > 0),
  apellido            text        not null check (length(trim(apellido)) > 0),
  correo              text        not null check (correo ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  password_hash       text        not null,                 -- nunca la contraseña en texto plano
  telefono            text        not null default '',
  rol                 text        check (rol in ('cliente', 'negocio', 'admin')),  -- null = aún no elige en "¿Eres un?"
  estado              text        not null default 'activo' check (estado in ('activo', 'suspendido')),
  motivo_suspension   text,
  suspendido_por      bigint      references public.usuarios (id_usuario),
  fecha_suspension    timestamptz,
  fecha_registro      timestamptz not null default now(),
  fecha_actualizacion timestamptz not null default now(),
  constraint usuarios_suspension_con_motivo
    check (estado = 'activo' or motivo_suspension is not null)
);
create unique index usuarios_correo_unico on public.usuarios (lower(correo));
create index usuarios_suspendido_por_idx on public.usuarios (suspendido_por);

-- ---------------------------------------------------------------------
--  NEGOCIOS (uno por dueño)
-- ---------------------------------------------------------------------
create table public.negocios (
  id_negocio            bigint generated always as identity primary key,
  id_usuario            bigint      not null unique references public.usuarios (id_usuario),
  nombre_comercial      text        not null default '',
  tipo                  text        not null check (tipo in ('fijo', 'ambulante')),
  descripcion           text        not null default '',
  telefono              text        not null default '',
  direccion             text        not null default '',     -- solo negocios fijos
  latitud               numeric(9, 6) check (latitud between -90 and 90),
  longitud              numeric(9, 6) check (longitud between -180 and 180),
  ubicacion_actualizada timestamptz,                          -- útil para ambulantes
  logo_url              text,
  banner_url            text,
  color_principal       text,                                 -- antes en negocio_configuracion
  color_secundario      text,
  estado                text        not null default 'activo' check (estado in ('activo', 'suspendido')),
  motivo_suspension     text,
  suspendido_por        bigint      references public.usuarios (id_usuario),
  fecha_suspension      timestamptz,
  fecha_registro        timestamptz not null default now(),
  fecha_actualizacion   timestamptz not null default now(),
  constraint negocios_suspension_con_motivo
    check (estado = 'activo' or motivo_suspension is not null),
  constraint negocios_ubicacion_completa
    check ((latitud is null) = (longitud is null))
);
create index negocios_estado_idx on public.negocios (estado);
create index negocios_ubicacion_idx on public.negocios (latitud, longitud);
create index negocios_suspendido_por_idx on public.negocios (suspendido_por);

-- ---------------------------------------------------------------------
--  FORMAS DE PAGO (catálogo) y las que acepta cada negocio
-- ---------------------------------------------------------------------
create table public.modalidades_pago (
  id_modalidad smallint generated always as identity primary key,
  nombre       text    not null unique,
  descripcion  text    not null default '',
  activa       boolean not null default true
);

create table public.negocio_modalidad_pago (
  id_negocio   bigint   not null references public.negocios (id_negocio) on delete cascade,
  id_modalidad smallint not null references public.modalidades_pago (id_modalidad),
  primary key (id_negocio, id_modalidad)
);
create index negocio_modalidad_pago_modalidad_idx on public.negocio_modalidad_pago (id_modalidad);

-- ---------------------------------------------------------------------
--  CATEGORÍAS y PRODUCTOS
-- ---------------------------------------------------------------------
create table public.categorias (
  id_categoria bigint generated always as identity primary key,
  nombre       text    not null unique,
  descripcion  text    not null default '',
  activa       boolean not null default true
);

create table public.productos (
  id_producto         bigint generated always as identity primary key,
  id_negocio          bigint        not null references public.negocios (id_negocio) on delete cascade,
  id_categoria        bigint        references public.categorias (id_categoria),
  nombre              text          not null check (length(trim(nombre)) > 0),
  descripcion         text          not null default '',
  precio              numeric(12, 2) not null check (precio >= 0),   -- DECIMAL: no se pierden centavos
  imagen_url          text,
  stock               integer       not null default 0 check (stock >= 0),
  disponible          boolean       not null default true,
  activo              boolean       not null default true,          -- false = "borrado" (se conserva por los pedidos)
  oculto_por_moderacion boolean     not null default false,         -- true = el administrador quitó su foto/contenido
  fecha_creacion      timestamptz   not null default now(),
  fecha_actualizacion timestamptz   not null default now()
);
create index productos_negocio_idx on public.productos (id_negocio);
create index productos_categoria_idx on public.productos (id_categoria);

-- ---------------------------------------------------------------------
--  PEDIDOS y su detalle
-- ---------------------------------------------------------------------
create table public.pedidos (
  id_pedido           bigint generated always as identity primary key,
  id_usuario          bigint        not null references public.usuarios (id_usuario),
  id_negocio          bigint        not null references public.negocios (id_negocio),
  id_modalidad        smallint      not null references public.modalidades_pago (id_modalidad),
  estado              text          not null default 'pendiente'
                      check (estado in ('pendiente', 'aceptado', 'en_preparacion', 'listo', 'entregado', 'rechazado', 'cancelado')),
  total               numeric(12, 2) not null default 0 check (total >= 0),
  motivo_cancelacion  text,
  fecha_creacion      timestamptz   not null default now(),
  fecha_actualizacion timestamptz   not null default now(),
  constraint pedidos_cancelacion_con_motivo
    check (estado not in ('rechazado', 'cancelado') or motivo_cancelacion is not null)
);
create index pedidos_usuario_idx on public.pedidos (id_usuario, fecha_creacion desc);
create index pedidos_negocio_idx on public.pedidos (id_negocio, estado);
create index pedidos_modalidad_idx on public.pedidos (id_modalidad);

create table public.detalle_pedido (
  id_detalle      bigint generated always as identity primary key,
  id_pedido       bigint        not null references public.pedidos (id_pedido) on delete cascade,
  id_producto     bigint        not null references public.productos (id_producto),
  cantidad        integer       not null check (cantidad > 0),
  precio_unitario numeric(12, 2) not null check (precio_unitario >= 0),  -- precio al momento de pedir
  subtotal        numeric(12, 2) generated always as (cantidad * precio_unitario) stored
);
create index detalle_pedido_pedido_idx on public.detalle_pedido (id_pedido);
create index detalle_pedido_producto_idx on public.detalle_pedido (id_producto);

-- ---------------------------------------------------------------------
--  RESEÑAS (una por pedido entregado)
-- ---------------------------------------------------------------------
create table public.resenas (
  id_resena      bigint generated always as identity primary key,
  id_pedido      bigint      not null unique references public.pedidos (id_pedido),
  id_usuario     bigint      not null references public.usuarios (id_usuario),
  id_negocio     bigint      not null references public.negocios (id_negocio),
  calificacion   smallint    not null check (calificacion between 1 and 5),
  comentario     text        not null default '',
  estado         text        not null default 'visible' check (estado in ('visible', 'oculta')),
  fecha_creacion timestamptz not null default now()
);
create index resenas_usuario_idx on public.resenas (id_usuario);
create index resenas_negocio_idx on public.resenas (id_negocio);

-- ---------------------------------------------------------------------
--  CHAT (una conversación por pareja cliente–negocio)
-- ---------------------------------------------------------------------
create table public.conversaciones (
  id_conversacion      bigint generated always as identity primary key,
  id_usuario           bigint      not null references public.usuarios (id_usuario),
  id_negocio           bigint      not null references public.negocios (id_negocio),
  fecha_creacion       timestamptz not null default now(),
  fecha_ultimo_mensaje timestamptz,
  unique (id_usuario, id_negocio)
);
create index conversaciones_negocio_idx on public.conversaciones (id_negocio, fecha_ultimo_mensaje desc);

create table public.mensajes (
  id_mensaje      bigint generated always as identity primary key,
  id_conversacion bigint      not null references public.conversaciones (id_conversacion) on delete cascade,
  id_remitente    bigint      not null references public.usuarios (id_usuario),
  mensaje         text        not null check (length(trim(mensaje)) > 0),
  fecha_envio     timestamptz not null default now(),
  leido           boolean     not null default false
);
create index mensajes_conversacion_idx on public.mensajes (id_conversacion, fecha_envio);
create index mensajes_remitente_idx on public.mensajes (id_remitente);

-- Al llegar un mensaje se actualiza la fecha del último mensaje (para ordenar los chats).
create or replace function public.actualizar_ultimo_mensaje()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.conversaciones
     set fecha_ultimo_mensaje = new.fecha_envio
   where id_conversacion = new.id_conversacion;
  return new;
end;
$$;

create trigger mensajes_actualizan_conversacion
after insert on public.mensajes
for each row execute function public.actualizar_ultimo_mensaje();

-- ---------------------------------------------------------------------
--  REPORTES: quejas sobre un NEGOCIO (servicio o comportamiento)
-- ---------------------------------------------------------------------
create table public.reportes (
  id_reporte           bigint generated always as identity primary key,   -- se muestra como REP-001
  id_negocio           bigint      not null references public.negocios (id_negocio),
  id_usuario           bigint      not null references public.usuarios (id_usuario),  -- quién reporta
  motivo               text        not null check (length(trim(motivo)) > 0),
  descripcion          text        not null default '',
  estado               text        not null default 'pendiente'
                       check (estado in ('pendiente', 'en_revision', 'resuelto', 'descartado', 'enviado_moderacion')),
  id_moderacion_origen bigint,                                             -- si vino de Moderación
  nota_interna         text        not null default '',
  cerrado_por          bigint      references public.usuarios (id_usuario),
  fecha_cierre         timestamptz,
  fecha_creacion       timestamptz not null default now(),
  fecha_actualizacion  timestamptz not null default now()
);
create index reportes_estado_idx on public.reportes (estado, fecha_creacion desc);
create index reportes_negocio_idx on public.reportes (id_negocio);
create index reportes_usuario_idx on public.reportes (id_usuario);
create index reportes_cerrado_por_idx on public.reportes (cerrado_por);
create index reportes_moderacion_origen_idx on public.reportes (id_moderacion_origen);

-- ---------------------------------------------------------------------
--  MODERACIÓN: un CONTENIDO puntual (foto, producto o descripción)
-- ---------------------------------------------------------------------
create table public.moderacion (
  id_moderacion       bigint generated always as identity primary key,    -- se muestra como MOD-001
  tipo                text        not null
                      check (tipo in ('foto_producto', 'producto', 'descripcion_negocio', 'contenido_negocio')),
  id_negocio          bigint      not null references public.negocios (id_negocio),
  id_producto         bigint      references public.productos (id_producto),   -- si es foto o producto
  id_usuario          bigint      not null references public.usuarios (id_usuario),  -- quién reporta
  contenido_texto     text        not null default '',   -- copia del texto reportado (por si el dueño lo cambia)
  motivo              text        not null check (length(trim(motivo)) > 0),
  estado              text        not null default 'por_revisar'
                      check (estado in ('por_revisar', 'mantenido', 'quitado', 'enviado_reportes')),
  id_reporte_origen   bigint      references public.reportes (id_reporte),    -- si vino de Reportes
  mensaje_dueno       text        not null default '',
  cerrado_por         bigint      references public.usuarios (id_usuario),
  fecha_cierre        timestamptz,
  fecha_creacion      timestamptz not null default now(),
  fecha_actualizacion timestamptz not null default now(),
  constraint moderacion_producto_si_aplica
    check (tipo not in ('foto_producto', 'producto') or id_producto is not null),
  constraint moderacion_quitado_con_mensaje
    check (estado <> 'quitado' or length(trim(mensaje_dueno)) > 0)
);
create index moderacion_estado_idx on public.moderacion (estado, fecha_creacion desc);
create index moderacion_negocio_idx on public.moderacion (id_negocio);
create index moderacion_producto_idx on public.moderacion (id_producto);
create index moderacion_usuario_idx on public.moderacion (id_usuario);
create index moderacion_reporte_origen_idx on public.moderacion (id_reporte_origen);
create index moderacion_cerrado_por_idx on public.moderacion (cerrado_por);

-- Referencia cruzada (se agrega al final porque las dos tablas se apuntan entre sí).
alter table public.reportes
  add constraint reportes_moderacion_origen_fkey
  foreign key (id_moderacion_origen) references public.moderacion (id_moderacion);

-- ---------------------------------------------------------------------
--  Fechas de actualización automáticas
-- ---------------------------------------------------------------------
create trigger usuarios_fecha_actualizacion   before update on public.usuarios   for each row execute function public.tocar_fecha_actualizacion();
create trigger negocios_fecha_actualizacion   before update on public.negocios   for each row execute function public.tocar_fecha_actualizacion();
create trigger productos_fecha_actualizacion  before update on public.productos  for each row execute function public.tocar_fecha_actualizacion();
create trigger pedidos_fecha_actualizacion    before update on public.pedidos    for each row execute function public.tocar_fecha_actualizacion();
create trigger reportes_fecha_actualizacion   before update on public.reportes   for each row execute function public.tocar_fecha_actualizacion();
create trigger moderacion_fecha_actualizacion before update on public.moderacion for each row execute function public.tocar_fecha_actualizacion();

-- ---------------------------------------------------------------------
--  SEGURIDAD (Supabase)
--  Las tablas NO se leen directo desde la app ni la web: todo pasa por la
--  API del compañero, que se conecta como dueño de la base de datos.
--  Por eso se activa RLS sin políticas: con la llave pública (anon) no se
--  puede leer ni escribir nada.
-- ---------------------------------------------------------------------
alter table public.usuarios               enable row level security;
alter table public.negocios               enable row level security;
alter table public.modalidades_pago       enable row level security;
alter table public.negocio_modalidad_pago enable row level security;
alter table public.categorias             enable row level security;
alter table public.productos              enable row level security;
alter table public.pedidos                enable row level security;
alter table public.detalle_pedido         enable row level security;
alter table public.resenas                enable row level security;
alter table public.conversaciones         enable row level security;
alter table public.mensajes               enable row level security;
alter table public.reportes               enable row level security;
alter table public.moderacion             enable row level security;

revoke execute on function public.tocar_fecha_actualizacion() from public;
revoke execute on function public.actualizar_ultimo_mensaje() from public;
