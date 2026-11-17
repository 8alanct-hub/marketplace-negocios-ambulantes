import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:marketplace_ambulante/model/api_cliente.dart';
import 'package:marketplace_ambulante/model/auth_repository.dart';
import 'package:marketplace_ambulante/model/auth_repository_api.dart';
import 'package:marketplace_ambulante/model/negocio.dart';
import 'package:marketplace_ambulante/model/negocio_repository_api.dart';
import 'package:marketplace_ambulante/model/pedido.dart';
import 'package:marketplace_ambulante/model/pedido_repository.dart';
import 'package:marketplace_ambulante/model/pedido_repository_api.dart';
import 'package:marketplace_ambulante/model/usuario.dart';

/// Pruebas de los repositorios "Api" sin internet: un servidor falso
/// (MockClient) responde como lo haría la API real.
void main() {
  http.Response respuesta(Object? cuerpo, [int estado = 200]) => http.Response(
        jsonEncode(cuerpo),
        estado,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  test('login guarda el token y lo envía en las siguientes peticiones',
      () async {
    final recibidas = <http.Request>[];
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient((req) async {
        recibidas.add(req);
        if (req.url.path == '/api/app/login') {
          return respuesta({
            'usuario': {
              'id': '2',
              'nombre': 'Carla',
              'apellido': 'Gómez',
              'telefono': '300',
              'correo': 'cliente@test.com',
              'rol': 'usuario',
            },
            'token': 'abc',
          });
        }
        return respuesta({
          'id': '2',
          'nombre': 'Carla',
          'apellido': 'Gómez',
          'telefono': '300',
          'correo': 'cliente@test.com',
          'rol': 'negocio',
        });
      }),
    );
    final repo = AuthRepositoryApi(api);

    final usuario =
        await repo.iniciarSesion(email: 'cliente@test.com', password: 'x');
    expect(usuario.nombreCompleto, 'Carla Gómez');
    expect(usuario.rol, RolUsuario.usuario);
    expect(api.token, 'abc');

    final actualizado =
        await repo.actualizarRol(usuarioId: '2', rol: RolUsuario.negocio);
    expect(actualizado.rol, RolUsuario.negocio);
    expect(recibidas.last.headers['Authorization'], 'Bearer abc');
    expect(jsonDecode(recibidas.last.body), {'rol': 'negocio'});
  });

  test('un error de la API llega con su mensaje', () async {
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient(
        (req) async => respuesta({'mensaje': 'Correo o contraseña incorrectos.'}, 401),
      ),
    );
    expect(
      () => AuthRepositoryApi(api).iniciarSesion(email: 'a@b.co', password: 'x'),
      throwsA(isA<AuthException>().having(
        (e) => e.mensaje,
        'mensaje',
        'Correo o contraseña incorrectos.',
      )),
    );
  });

  test('negocio: convierte el JSON y devuelve null si no existe', () async {
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/negocios/99')) {
          return respuesta({'mensaje': 'Este negocio ya no está disponible.'}, 404);
        }
        return respuesta({
          'id': '1',
          'propietarioId': '3',
          'tipo': 'ambulante',
          'nombre': 'Arepas La Esquina',
          'descripcion': '',
          'telefono': '301',
          'direccion': '',
          'latitud': 10.4213,
          'longitud': -75.5452,
          'ubicacionActualizada': '2026-11-17T15:00:00.000Z',
          'logoUrl': null,
          'bannerUrl': null,
          'estado': 'suspendido',
        });
      }),
    );
    final repo = NegocioRepositoryApi(api);

    final negocio = await repo.obtenerPorId('1');
    expect(negocio!.tipo, TipoNegocio.ambulante);
    expect(negocio.latitud, 10.4213);
    expect(negocio.estado, EstadoNegocio.suspendido);
    expect(negocio.suspendido, isTrue);
    expect(await repo.obtenerPorId('99'), isNull);
  });

  test('pedidos: envía el estado como en la base y lee el detalle', () async {
    late http.Request enviada;
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient((req) async {
        enviada = req;
        return respuesta({
          'id': '4',
          'usuarioId': '2',
          'clienteNombre': 'Carla Gómez',
          'negocioId': '6',
          'negocioNombre': 'Empanadas Ana',
          'modalidadPagoId': '2',
          'estado': 'en_preparacion',
          'detalles': [
            {
              'productoId': '11',
              'nombreProducto': 'Empanada',
              'cantidad': 2,
              'precioUnitario': 3000,
            },
          ],
          'fechaCreacion': '2026-11-17T17:00:00.000Z',
          'fechaActualizacion': '2026-11-17T17:05:00.000Z',
          'motivo': null,
        });
      }),
    );

    final pedido = await PedidoRepositoryApi(api)
        .cambiarEstado('4', EstadoPedido.enPreparacion);
    expect(jsonDecode(enviada.body)['estado'], 'en_preparacion');
    expect(pedido.estado, EstadoPedido.enPreparacion);
    expect(pedido.total, 6000);
    expect(pedido.detalles.single.nombreProducto, 'Empanada');
  });

  test('pedidos: un cambio no válido llega como PedidoException', () async {
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient((req) async => respuesta(
            {'mensaje': 'Este pedido ya cambió de estado. Actualiza la lista.'},
            409,
          )),
    );
    expect(
      () => PedidoRepositoryApi(api).cancelarPorCliente('4'),
      throwsA(isA<PedidoException>()),
    );
  });

  test('sin conexión: mensaje amable', () async {
    final api = ApiCliente(
      'https://api.test/api',
      cliente: MockClient((req) async => throw http.ClientException('sin red')),
    );
    expect(
      () => api.get('/app/modalidades'),
      throwsA(isA<ApiException>().having(
        (e) => e.mensaje,
        'mensaje',
        ApiCliente.errorConexion,
      )),
    );
  });
}
