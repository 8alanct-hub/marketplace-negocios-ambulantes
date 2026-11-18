import 'negocio.dart';
import 'usuario.dart';

/// Contraseña de todas las cuentas de prueba.
const mockPassword = 'Prueba123';

/// Cuentas de prueba mientras no hay backend.
const mockUsuarios = <Usuario>[
  Usuario(
    id: 'u_1',
    nombre: 'Carla',
    apellido: 'Gómez',
    telefono: '3001234567',
    email: 'cliente@test.com',
    rol: RolUsuario.usuario,
  ),
  Usuario(
    id: 'u_2',
    nombre: 'Nora',
    apellido: 'Ruiz',
    telefono: '3109876543',
    email: 'negocio@test.com',
    rol: RolUsuario.negocio,
  ),
];

/// Negocios de prueba (Cartagena). Solo n_1 tiene cuenta para entrar
/// (negocio@test.com); los demás existen para llenar el Marketplace.
const mockNegocios = <Negocio>[
  Negocio(
    id: 'n_1',
    propietarioId: 'u_2',
    tipo: TipoNegocio.fijo,
    nombre: 'Nouveau Beauty Salon',
    descripcion: 'Uñas, manos y pies con atención personalizada',
    telefono: '3109876543',
    direccion: 'Calle del Arsenal # 10-45, Getsemaní',
    latitud: 10.4204,
    longitud: -75.5479,
  ),
  Negocio(
    id: 'n_2',
    propietarioId: 'u_20',
    tipo: TipoNegocio.ambulante,
    nombre: 'Arepas La Esquina',
    descripcion: 'Arepas de huevo y de queso recién hechas',
    telefono: '3014445566',
    latitud: 10.4213,
    longitud: -75.5452,
  ),
  Negocio(
    id: 'n_3',
    propietarioId: 'u_21',
    tipo: TipoNegocio.ambulante,
    nombre: 'Frutas Doña Rosa',
    descripcion: 'Frutas picadas, jugos y salpicón',
    telefono: '3157778899',
    latitud: 10.3997,
    longitud: -75.5536,
  ),
  Negocio(
    id: 'n_4',
    propietarioId: 'u_22',
    tipo: TipoNegocio.fijo,
    nombre: 'Panadería El Trigal',
    descripcion: 'Pan artesanal, pasteles y café',
    telefono: '3201112233',
    direccion: 'Av. Jiménez # 23-10, Manga',
    latitud: 10.4120,
    longitud: -75.5370,
  ),
  Negocio(
    id: 'n_5',
    propietarioId: 'u_23',
    tipo: TipoNegocio.fijo,
    nombre: 'Artesanías Mompox',
    descripcion: 'Filigrana, mochilas y sombreros hechos a mano',
    telefono: '3186665544',
    direccion: 'Calle de las Damas # 3-21, Centro',
    latitud: 10.4243,
    longitud: -75.5511,
  ),
];
