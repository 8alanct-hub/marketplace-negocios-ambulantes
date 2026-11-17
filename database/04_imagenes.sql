-- =====================================================================
--  04 · Imágenes que suben los negocios desde la app
--  (portada, logo y fotos de productos)
--
--  Se guardan dentro de la base de datos para no depender de otro
--  servicio. La API las entrega en  GET /api/imagenes/<id>  y esa
--  dirección es la que queda en negocios.logo_url, banner_url y
--  productos.imagen_url.
--  La app reduce cada foto a 1600 px máx. antes de subirla.
-- =====================================================================

create table public.imagenes (
  id_imagen      uuid        primary key default gen_random_uuid(),
  id_usuario     bigint      not null references public.usuarios (id_usuario),  -- quién la subió
  tipo_mime      text        not null check (tipo_mime in ('image/jpeg', 'image/png', 'image/webp', 'image/gif')),
  datos          bytea       not null check (octet_length(datos) <= 5 * 1024 * 1024),  -- máx. 5 MB
  fecha_creacion timestamptz not null default now()
);
create index imagenes_usuario_idx on public.imagenes (id_usuario);

-- Igual que las demás tablas: solo la API entra.
alter table public.imagenes enable row level security;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    revoke all on public.imagenes from anon, authenticated;
  end if;
end $$;
