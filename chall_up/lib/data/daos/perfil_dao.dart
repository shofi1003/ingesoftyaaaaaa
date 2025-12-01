import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cuestionario.dart';
import '../tables/historial_perfil.dart';
import '../tables/perfil.dart';
import '../tables/pregunta.dart';
import '../tables/respuesta.dart';
import '../tables/usuario.dart';

part 'perfil_dao.g.dart';

enum PerfilCampo { hobby, habito, meta }

class EntradaCuestionarioInicial {
  final String textoPregunta;
  final String tipoPregunta;
  final String? respuesta;
  final PerfilCampo? campoPerfil;

  const EntradaCuestionarioInicial({
    required this.textoPregunta,
    required this.tipoPregunta,
    this.respuesta,
    this.campoPerfil,
  });
}

@DriftAccessor(
  tables: [
    Usuarios,
    Perfils,
    HistorialPerfils,
    Cuestionarios,
    Preguntas,
    Respuestas,
  ],
)
class PerfilDao extends DatabaseAccessor<AppDatabase> with _$PerfilDaoMixin {
  PerfilDao(AppDatabase db) : super(db);

  /// Persiste el cuestionario inicial y calcula el perfil del usuario.
  Future<void> guardarCuestionarioInicial(
    int usuarioId,
    List<EntradaCuestionarioInicial> entradas,
  ) async {
    await transaction(() async {
      final cuestionarioId = await into(cuestionarios).insert(
        CuestionariosCompanion(usuarioId: Value(usuarioId)),
      );

      for (final entrada in entradas) {
        final preguntaId = await into(preguntas).insert(
          PreguntasCompanion(
            cuestionarioId: Value(cuestionarioId),
            texto: Value(entrada.textoPregunta),
            tipo: Value(entrada.tipoPregunta),
          ),
        );

        await into(respuestas).insert(
          RespuestasCompanion(
            preguntaId: Value(preguntaId),
            usuarioId: Value(usuarioId),
            respuestaTexto: Value(entrada.respuesta),
          ),
        );
      }
    });

    await generarPerfilDesdeRespuestas(usuarioId, entradas);
  }

  Future<Perfil?> obtenerPerfilPorUsuario(int usuarioId) {
    return (select(perfils)..where((tbl) => tbl.usuarioId.equals(usuarioId)))
        .getSingleOrNull();
  }

  /// Reconstruye el perfil tomando las respuestas más recientes del cuestionario.
  Future<Perfil> generarPerfilDesdeRespuestas(
    int usuarioId,
    List<EntradaCuestionarioInicial> entradas,
  ) async {
    await _actualizarPerfilDesdeEntradas(usuarioId, entradas);
    final perfil = await obtenerPerfilPorUsuario(usuarioId);
    if (perfil == null) {
      throw StateError('No se pudo generar el perfil para el usuario $usuarioId');
    }
    return perfil;
  }

  Future<void> registrarCambioHobby({
    required int usuarioId,
    required String valorNuevo,
    String? valorAnterior,
  }) async {
    final perfilActual = await obtenerPerfilPorUsuario(usuarioId);

    await transaction(() async {
      await into(historialPerfils).insert(
        HistorialPerfilsCompanion(
          usuarioId: Value(usuarioId),
          campoModificado: const Value('hobbies'),
          valorAnterior: Value(valorAnterior ?? perfilActual?.hobbies),
          valorNuevo: Value(valorNuevo),
        ),
      );

      if (perfilActual == null) {
        await into(perfils).insert(
          PerfilsCompanion(
            usuarioId: Value(usuarioId),
            hobbies: Value(valorNuevo),
            fechaActualizacion: Value(DateTime.now()),
          ),
        );
      } else {
        await (update(perfils)..where((tbl) => tbl.id.equals(perfilActual.id)))
            .write(
          PerfilsCompanion(
            hobbies: Value(valorNuevo),
            fechaActualizacion: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<List<HistorialPerfil>> obtenerHistorialHobbies(int usuarioId) {
    final query = (select(historialPerfils)
          ..where((tbl) => tbl.usuarioId.equals(usuarioId)))
        ..orderBy([
          (tbl) => OrderingTerm(
                expression: tbl.fecha,
                mode: OrderingMode.desc,
              ),
        ]);

    return query.get();
  }

  Future<void> _actualizarPerfilDesdeEntradas(
    int usuarioId,
    List<EntradaCuestionarioInicial> entradas,
  ) async {
    final hobbies = entradas
        .where((entrada) => entrada.campoPerfil == PerfilCampo.hobby)
        .map((entrada) => entrada.respuesta)
        .whereType<String>()
        .where((respuesta) => respuesta.isNotEmpty)
        .join(', ');

    final habitos = entradas
        .where((entrada) => entrada.campoPerfil == PerfilCampo.habito)
        .map((entrada) => entrada.respuesta)
        .whereType<String>()
        .where((respuesta) => respuesta.isNotEmpty)
        .join(', ');

    final metas = entradas
        .where((entrada) => entrada.campoPerfil == PerfilCampo.meta)
        .map((entrada) => entrada.respuesta)
        .whereType<String>()
        .where((respuesta) => respuesta.isNotEmpty)
        .join(', ');

    final perfilActual = await obtenerPerfilPorUsuario(usuarioId);

    if (perfilActual == null) {
      await into(perfils).insert(
        PerfilsCompanion(
          usuarioId: Value(usuarioId),
          hobbies: Value(hobbies.isNotEmpty ? hobbies : null),
          habitos: Value(habitos.isNotEmpty ? habitos : null),
          metas: Value(metas.isNotEmpty ? metas : null),
          fechaActualizacion: Value(DateTime.now()),
        ),
      );
      return;
    }

    await (update(perfils)..where((tbl) => tbl.id.equals(perfilActual.id)))
        .write(
      PerfilsCompanion(
        hobbies: Value(hobbies.isNotEmpty ? hobbies : perfilActual.hobbies),
        habitos: Value(habitos.isNotEmpty ? habitos : perfilActual.habitos),
        metas: Value(metas.isNotEmpty ? metas : perfilActual.metas),
        fechaActualizacion: Value(DateTime.now()),
      ),
    );
  }
}
