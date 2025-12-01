import 'package:chall_up/data/daos/perfil_dao.dart';
import 'package:chall_up/data/daos/reto_dao.dart';
import 'package:chall_up/data/database.dart';
import 'package:chall_up/services/perfil_service.dart';
import 'package:chall_up/services/reto_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PerfilService perfilService;
  late RetoService retoService;

  setUp(() {
    db = AppDatabase.forTest(NativeDatabase.memory());
    final perfilDao = PerfilDao(db);
    final retoDao = RetoDao(db);
    perfilService = PerfilService(perfilDao);
    retoService = RetoService(retoDao: retoDao, perfilDao: perfilDao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Usuario> _crearUsuario() {
    return db.into(db.usuarios).insertReturning(
          UsuariosCompanion(
            nombre: const Value('Tester'),
            correo: const Value('tester@example.com'),
            password: const Value('123456'),
          ),
        );
  }

  test('Genera perfil desde cuestionario inicial', () async {
    final usuario = await _crearUsuario();
    final entradas = [
      const EntradaCuestionarioInicial(
        textoPregunta: 'Hobby',
        tipoPregunta: 'texto',
        respuesta: 'fotografía',
        campoPerfil: PerfilCampo.hobby,
      ),
      const EntradaCuestionarioInicial(
        textoPregunta: 'Hábito',
        tipoPregunta: 'texto',
        respuesta: 'caminar',
        campoPerfil: PerfilCampo.habito,
      ),
    ];

    final perfil = await perfilService.generarPerfilDesdeRespuestas(
      usuarioId: usuario.id,
      entradas: entradas,
    );

    expect(perfil.hobbies, contains('fotografía'));
    expect(perfil.habitos, contains('caminar'));
  });

  test('Registrar cambio de hobby crea historial', () async {
    final usuario = await _crearUsuario();
    await perfilService.registrarCambioHobby(usuarioId: usuario.id, nuevoHobby: 'pintura');
    final historial = await perfilService.obtenerHistorialHobbies(usuario.id);
    expect(historial, isNotEmpty);
    expect(historial.first.valorNuevo, 'pintura');
  });

  test('Genera reto diario alineado al perfil', () async {
    final usuario = await _crearUsuario();
    await perfilService.registrarCambioHobby(usuarioId: usuario.id, nuevoHobby: 'senderismo');
    final reto = await retoService.obtenerORenovarReto(usuario.id);
    expect(reto.detalle.descripcion.toLowerCase(), contains('reto'));
    expect(reto.detalle.generadoPorInactividad, isFalse);
  });

  test('Genera reto por inactividad cuando aplica', () async {
    final usuario = await _crearUsuario();
    await perfilService.registrarCambioHobby(usuarioId: usuario.id, nuevoHobby: 'yoga');

    // Simular historial antiguo
    await db.into(db.historialPerfils).insert(
          HistorialPerfilsCompanion(
            usuarioId: Value(usuario.id),
            campoModificado: const Value('hobbies'),
            valorNuevo: const Value('yoga'),
            fecha: Value(DateTime.now().subtract(const Duration(days: 8))),
          ),
        );

    final reto = await retoService.obtenerORenovarReto(usuario.id);
    expect(reto.detalle.generadoPorInactividad, isTrue);
  });
}
