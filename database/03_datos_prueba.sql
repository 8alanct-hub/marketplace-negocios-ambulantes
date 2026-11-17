-- =====================================================================
--  03 · DATOS DE PRUEBA
--  Los mismos de la app y del panel web (Cartagena).
--  Contraseña de TODAS las cuentas: Prueba123
--  No usar en producción: borrar con 04_borrar_datos_prueba.sql
-- =====================================================================

-- ---------------- Usuarios ----------------
insert into public.usuarios (nombre, apellido, correo, password_hash, telefono, rol, fecha_registro) values
  ('Andrés', 'Mejía',    'admin@test.com',      extensions.crypt('Prueba123', extensions.gen_salt('bf')), '300 555 1122', 'admin',   '2026-08-01 09:00-05'),
  ('Carla',  'Gómez',    'cliente@test.com',    extensions.crypt('Prueba123', extensions.gen_salt('bf')), '300 123 4567', 'cliente', '2026-08-02 10:15-05'),
  ('Nora',   'Ruiz',     'negocio@test.com',    extensions.crypt('Prueba123', extensions.gen_salt('bf')), '310 987 6543', 'negocio', '2026-08-05 11:30-05'),
  ('Luis',   'Herrera',  'arepas@test.com',     extensions.crypt('Prueba123', extensions.gen_salt('bf')), '301 444 5566', 'negocio', '2026-08-20 08:00-05'),
  ('Rosa',   'Martínez', 'frutas@test.com',     extensions.crypt('Prueba123', extensions.gen_salt('bf')), '315 777 8899', 'negocio', '2026-09-04 07:45-05'),
  ('Jorge',  'Castro',   'eltrigal@test.com',   extensions.crypt('Prueba123', extensions.gen_salt('bf')), '320 111 2233', 'negocio', '2026-09-19 06:30-05'),
  ('Elena',  'Pacheco',  'artesanias@test.com', extensions.crypt('Prueba123', extensions.gen_salt('bf')), '318 666 5544', 'negocio', '2026-10-04 15:20-05'),
  ('Mateo',  'Ríos',     'mateo@test.com',      extensions.crypt('Prueba123', extensions.gen_salt('bf')), '304 555 6677', 'cliente', '2026-10-21 18:10-05'),
  ('Laura',  'Pérez',    'laura@test.com',      extensions.crypt('Prueba123', extensions.gen_salt('bf')), '311 222 3344', 'cliente', '2026-10-30 12:00-05');

-- Laura está suspendida (lo hizo el administrador).
update public.usuarios
   set estado = 'suspendido',
       motivo_suspension = 'Comentarios ofensivos en el chat con negocios.',
       suspendido_por = (select id_usuario from public.usuarios where correo = 'admin@test.com'),
       fecha_suspension = '2026-11-13 09:30-05'
 where correo = 'laura@test.com';

-- ---------------- Formas de pago y categorías ----------------
insert into public.modalidades_pago (nombre, descripcion) values
  ('Pago en el negocio', 'El cliente paga cuando va al local o al puesto.'),
  ('Contraentrega',      'El cliente paga al recibir; la entrega se acuerda por el chat.');

insert into public.categorias (nombre) values
  ('Belleza y cuidado personal'), ('Comidas'), ('Frutas y bebidas'), ('Panadería y repostería'), ('Artesanías');

-- ---------------- Negocios ----------------
insert into public.negocios (id_usuario, nombre_comercial, tipo, descripcion, telefono, direccion, latitud, longitud, ubicacion_actualizada, fecha_registro)
select u.id_usuario, v.nombre, v.tipo, v.descripcion, u.telefono, v.direccion, v.lat, v.lng, v.ubicacion::timestamptz, u.fecha_registro
from (values
  ('negocio@test.com',    'Nouveau Beauty Salon', 'fijo',      'Uñas, manos y pies con atención personalizada', 'Calle del Arsenal # 10-45, Getsemaní', 10.4204, -75.5479, null),
  ('arepas@test.com',     'Arepas La Esquina',    'ambulante', 'Arepas de huevo y de queso recién hechas',      '',                                    10.4213, -75.5452, '2026-11-17 08:20-05'),
  ('frutas@test.com',     'Frutas Doña Rosa',     'ambulante', 'Frutas picadas, jugos y salpicón',              '',                                    10.3997, -75.5536, '2026-11-17 08:05-05'),
  ('eltrigal@test.com',   'Panadería El Trigal',  'fijo',      'Pan artesanal, pasteles y café',                'Av. Jiménez # 23-10, Manga',           10.4120, -75.5370, null),
  ('artesanias@test.com', 'Artesanías Mompox',    'fijo',      'Filigrana, mochilas y sombreros hechos a mano', 'Calle de las Damas # 3-21, Centro',    10.4243, -75.5511, null)
) as v (correo, nombre, tipo, descripcion, direccion, lat, lng, ubicacion)
join public.usuarios u on u.correo = v.correo;

-- Artesanías Mompox está suspendido.
update public.negocios
   set estado = 'suspendido',
       motivo_suspension = 'Fotos de productos que no corresponden a lo que vende.',
       suspendido_por = (select id_usuario from public.usuarios where correo = 'admin@test.com'),
       fecha_suspension = '2026-11-13 10:00-05'
 where nombre_comercial = 'Artesanías Mompox';

-- Todos aceptan las dos formas de pago, menos los ambulantes (solo contraentrega).
insert into public.negocio_modalidad_pago (id_negocio, id_modalidad)
select n.id_negocio, m.id_modalidad
from public.negocios n cross join public.modalidades_pago m
where not (n.tipo = 'ambulante' and m.nombre = 'Pago en el negocio');

-- ---------------- Productos ----------------
insert into public.productos (id_negocio, id_categoria, nombre, descripcion, precio, stock, disponible)
select n.id_negocio, c.id_categoria, v.nombre, v.descripcion, v.precio, v.stock, v.disponible
from (values
  ('Nouveau Beauty Salon', 'Belleza y cuidado personal', 'Manicure tradicional', 'Limpieza, limado y esmalte', 25000, 20, true),
  ('Nouveau Beauty Salon', 'Belleza y cuidado personal', 'Pedicure spa',         'Exfoliación e hidratación',  40000, 15, true),
  ('Arepas La Esquina',    'Comidas',                    'Arepa de huevo',       'Con carne molida',            5000, 40, true),
  ('Arepas La Esquina',    'Comidas',                    'Arepa de queso',       'Queso costeño',               3500, 0,  true),   -- agotada
  ('Frutas Doña Rosa',     'Frutas y bebidas',           'Salpicón',             'Vaso de 16 oz',               6000, 25, true),
  ('Frutas Doña Rosa',     'Frutas y bebidas',           'Jugo de corozo',       'Natural, sin azúcar añadida', 4000, 30, false),  -- no disponible
  ('Panadería El Trigal',  'Panadería y repostería',     'Pan de bono',          'La unidad',                   1500, 60, true),
  ('Panadería El Trigal',  'Panadería y repostería',     'Torta de queso',       'Porción',                     7000, 12, true),
  ('Artesanías Mompox',    'Artesanías',                 'Sombrero vueltiao',    '19 vueltas',                180000, 5,  true),
  ('Artesanías Mompox',    'Artesanías',                 'Mochila wayuu',        'Tejida a mano',             150000, 3,  true)
) as v (negocio, categoria, nombre, descripcion, precio, stock, disponible)
join public.negocios n on n.nombre_comercial = v.negocio
join public.categorias c on c.nombre = v.categoria;

-- ---------------- Pedidos ----------------
-- Carla: un pedido entregado en el salón y otro pendiente en Arepas; Mateo canceló uno.
with nuevo as (
  insert into public.pedidos (id_usuario, id_negocio, id_modalidad, estado, total, fecha_creacion)
  select (select id_usuario from public.usuarios where correo = 'cliente@test.com'),
         (select id_negocio from public.negocios where nombre_comercial = 'Nouveau Beauty Salon'),
         (select id_modalidad from public.modalidades_pago where nombre = 'Pago en el negocio'),
         'entregado', 25000, '2026-11-10 15:00-05'
  returning id_pedido
)
insert into public.detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
select nuevo.id_pedido, p.id_producto, 1, p.precio
from nuevo join public.productos p on p.nombre = 'Manicure tradicional';

with nuevo as (
  insert into public.pedidos (id_usuario, id_negocio, id_modalidad, estado, total, fecha_creacion)
  select (select id_usuario from public.usuarios where correo = 'cliente@test.com'),
         (select id_negocio from public.negocios where nombre_comercial = 'Arepas La Esquina'),
         (select id_modalidad from public.modalidades_pago where nombre = 'Contraentrega'),
         'pendiente', 10000, '2026-11-17 07:50-05'
  returning id_pedido
)
insert into public.detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
select nuevo.id_pedido, p.id_producto, 2, p.precio
from nuevo join public.productos p on p.nombre = 'Arepa de huevo';

with nuevo as (
  insert into public.pedidos (id_usuario, id_negocio, id_modalidad, estado, total, motivo_cancelacion, fecha_creacion)
  select (select id_usuario from public.usuarios where correo = 'mateo@test.com'),
         (select id_negocio from public.negocios where nombre_comercial = 'Panadería El Trigal'),
         (select id_modalidad from public.modalidades_pago where nombre = 'Pago en el negocio'),
         'cancelado', 7000, 'Cancelado por el cliente', '2026-11-12 09:10-05'
  returning id_pedido
)
insert into public.detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
select nuevo.id_pedido, p.id_producto, 1, p.precio
from nuevo join public.productos p on p.nombre = 'Torta de queso';

-- Reseña del pedido entregado.
insert into public.resenas (id_pedido, id_usuario, id_negocio, calificacion, comentario)
select p.id_pedido, p.id_usuario, p.id_negocio, 5, 'Muy buena atención, puntuales.'
from public.pedidos p where p.estado = 'entregado';

-- ---------------- Chat ----------------
with conv as (
  insert into public.conversaciones (id_usuario, id_negocio)
  select (select id_usuario from public.usuarios where correo = 'cliente@test.com'),
         (select id_negocio from public.negocios where nombre_comercial = 'Arepas La Esquina')
  returning id_conversacion, id_usuario, id_negocio
)
insert into public.mensajes (id_conversacion, id_remitente, mensaje, fecha_envio, leido)
select conv.id_conversacion, v.remitente, v.mensaje, v.fecha::timestamptz, true
from conv, lateral (values
  (conv.id_usuario, 'Hola, ¿dónde están hoy?', '2026-11-17 07:52-05'),
  ((select id_usuario from public.negocios where id_negocio = conv.id_negocio), 'En la esquina del parque Fernández de Madrid. Te llevo las arepas a las 8:30.', '2026-11-17 07:55-05')
) as v (remitente, mensaje, fecha);

-- ---------------- Reportes (quejas sobre el negocio) ----------------
-- Se insertan en orden para que queden REP-001 … REP-004 como en el panel.
insert into public.reportes (id_negocio, id_usuario, motivo, descripcion, estado, nota_interna, fecha_creacion, cerrado_por, fecha_cierre)
select n.id_negocio, u.id_usuario, v.motivo, v.descripcion, v.estado, v.nota, v.fecha::timestamptz,
       case when v.cierre is not null then (select id_usuario from public.usuarios where correo = 'admin@test.com') end,
       v.cierre::timestamptz
from (values
  (1, 'Panadería El Trigal', 'cliente@test.com', 'Trato inadecuado',
      'La persona que atiende me respondió de mala manera cuando pregunté por mi pedido.',
      'resuelto', 'Se habló con el dueño; se disculpó con la clienta.', '2026-11-03 11:05-05', '2026-11-05 10:00-05'),
  (2, 'Frutas Doña Rosa', 'laura@test.com', 'Pedido no entregado',
      'Hice un pedido contraentrega, acordamos la hora por el chat y nunca llegó. Después no volvió a responder.',
      'pendiente', '', '2026-11-10 19:30-05', null),
  (3, 'Artesanías Mompox', 'cliente@test.com', 'Producto engañoso',
      'Las fotos de las mochilas no corresponden a lo que venden en el local; el producto que recibí es de otra calidad.',
      'enviado_moderacion', 'El problema son las fotos de los productos, no el servicio.', '2026-11-12 16:15-05', '2026-11-13 09:00-05'),
  (4, 'Arepas La Esquina', 'mateo@test.com', 'Información incorrecta',
      'La ubicación que muestra la app no es la real. Fui dos veces al punto del mapa y el puesto no estaba; el vendedor no la actualiza.',
      'pendiente', '', '2026-11-14 10:42-05', null)
) as v (orden, negocio, correo, motivo, descripcion, estado, nota, fecha, cierre)
join public.negocios n on n.nombre_comercial = v.negocio
join public.usuarios u on u.correo = v.correo
order by v.orden;

-- ---------------- Moderación (contenidos puntuales) ----------------
-- MOD-001 … MOD-004 en orden.
insert into public.moderacion (tipo, id_negocio, id_producto, id_usuario, contenido_texto, motivo, estado,
                               id_reporte_origen, mensaje_dueno, fecha_creacion, cerrado_por, fecha_cierre)
select v.tipo, n.id_negocio, p.id_producto, u.id_usuario, v.texto, v.motivo, v.estado,
       (select r.id_reporte from public.reportes r where r.motivo = v.motivo_reporte_origen),
       v.mensaje, v.fecha::timestamptz,
       case when v.cierre is not null then (select id_usuario from public.usuarios where correo = 'admin@test.com') end,
       v.cierre::timestamptz
from (values
  (1, 'producto', 'Panadería El Trigal', 'Pan de bono', 'laura@test.com', '',
      'Precio sospechoso', 'mantenido', null, '', '2026-11-06 08:00-05', '2026-11-07 09:00-05'),
  (2, 'descripcion_negocio', 'Arepas La Esquina', null, 'cliente@test.com',
      '«Arepas de huevo y de queso recién hechas. Las del puesto de enfrente dan asco, no les compre.»',
      'Lenguaje ofensivo hacia otro negocio', 'por_revisar', null,
      'Tu descripción tiene lenguaje ofensivo hacia otro negocio. Escribe una nueva descripción sin mencionar a otros vendedores.',
      '2026-11-13 08:30-05', null),
  (3, 'foto_producto', 'Artesanías Mompox', 'Sombrero vueltiao', 'cliente@test.com', '',
      'La foto no corresponde al producto', 'por_revisar', 'Producto engañoso',
      'La foto del producto «Sombrero vueltiao» no corresponde a lo que vendes. Sube una foto real del producto.',
      '2026-11-13 09:00-05', null),
  (4, 'descripcion_negocio', 'Arepas La Esquina', null, 'mateo@test.com',
      '«Las mejores arepas. Los de enfrente venden basura.»',
      'Lenguaje ofensivo hacia otro negocio', 'quitado', null,
      'Tu descripción tenía lenguaje ofensivo hacia otro negocio y fue retirada.',
      '2026-11-02 07:00-05', '2026-11-02 12:00-05')
) as v (orden, tipo, negocio, producto, correo, texto, motivo, estado, motivo_reporte_origen, mensaje, fecha, cierre)
join public.negocios n on n.nombre_comercial = v.negocio
join public.usuarios u on u.correo = v.correo
left join public.productos p on p.nombre = v.producto and p.id_negocio = n.id_negocio
order by v.orden;
