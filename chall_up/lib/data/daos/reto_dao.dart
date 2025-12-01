import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/historial_perfil.dart';
import '../tables/notificacion.dart';
import '../tables/perfil.dart';
import '../tables/reto_diario.dart';
import '../tables/reto_diario_detalle.dart';
import '../tables/reto_predefinido.dart';

part 'reto_dao.g.dart';

class RetoDiarioConDetalle {
  final RetoDiario reto;
  final RetoDiarioDetalle detalle;
  final RetoPredefinido? retoPredefinido;

  const RetoDiarioConDetalle({
    required this.reto,
    required this.detalle,
    this.retoPredefinido,
  });
}

@DriftAccessor(
  tables: [
    Perfils,
    HistorialPerfils,
    RetoDiarios,
    RetoPredefinidos,
    RetoDiarioDetalles,
    Notificacions,
  ],
)
class RetoDao extends DatabaseAccessor<AppDatabase> with _$RetoDaoMixin {
  RetoDao(AppDatabase db) : super(db);

  Future<DateTime?> _fechaUltimoCambioHobby(int usuarioId) async {
    final ultimoCambio = await (select(historialPerfils)
          ..where((tbl) =>
              tbl.usuarioId.equals(usuarioId) &
              tbl.campoModificado.equals('hobbies'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.fecha)])
          ..limit(1))
        .getSingleOrNull();

    if (ultimoCambio != null) {
      return ultimoCambio.fecha;
    }

    final perfil = await (select(perfils)
          ..where((tbl) => tbl.usuarioId.equals(usuarioId)))
        .getSingleOrNull();
    return perfil?.fechaActualizacion;
  }

  Future<RetoDiarioConDetalle?> obtenerRetoDelDia(int usuarioId) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final retoConDetalle = await (select(retoDiarios).join([
      innerJoin(
        retoDiarioDetalles,
        retoDiarioDetalles.retoDiarioId.equalsExp(retoDiarios.id),
      ),
      leftOuterJoin(
        retoPredefinidos,
        retoPredefinidos.id.equalsExp(retoDiarios.retoPredefinidoId),
      ),
    ])
          ..where(retoDiarios.usuarioId.equals(usuarioId))
          ..where(retoDiarioDetalles.fechaCreacion.isBiggerOrEqualValue(inicioDia))
          ..where(retoDiarioDetalles.fechaCreacion.isSmallerThanValue(finDia))
          ..orderBy([
            OrderingTerm(expression: retoDiarioDetalles.fechaCreacion, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (retoConDetalle == null) return null;

    return RetoDiarioConDetalle(
      reto: retoConDetalle.readTable(retoDiarios),
      detalle: retoConDetalle.readTable(retoDiarioDetalles),
      retoPredefinido: retoConDetalle.readTableOrNull(retoPredefinidos),
    );
  }

  Future<RetoDiarioConDetalle> guardarRetoGenerado({
    required int usuarioId,
    required String descripcion,
    bool esPorInactividad = false,
    String origen = 'perfil',
    int? retoPredefinidoId,
  }) async {
    return await transaction(() async {
      final retoId = await into(retoDiarios).insert(
        RetoDiariosCompanion(
          usuarioId: Value(usuarioId),
          retoPredefinidoId: Value(retoPredefinidoId ??
              await _obtenerRetoPredefinidoGenerico(origen)),
          fecha: Value(DateTime.now()),
        ),
      );

      final detalleId = await into(retoDiarioDetalles).insert(
        RetoDiarioDetallesCompanion(
          retoDiarioId: Value(retoId),
          descripcion: Value(descripcion),
          generadoPorInactividad: Value(esPorInactividad),
          origen: Value(origen),
        ),
      );

      final joinRow = await (select(retoDiarios).join([
        innerJoin(
          retoDiarioDetalles,
          retoDiarioDetalles.id.equalsValue(detalleId),
        ),
        leftOuterJoin(
          retoPredefinidos,
          retoPredefinidos.id.equalsExp(retoDiarios.retoPredefinidoId),
        )
      ])).getSingle();

      return RetoDiarioConDetalle(
        reto: joinRow.readTable(retoDiarios),
        detalle: joinRow.readTable(retoDiarioDetalles),
        retoPredefinido: joinRow.readTableOrNull(retoPredefinidos),
      );
    });
  }

  Future<int> _obtenerRetoPredefinidoGenerico(String categoria) async {
    final existente = await (select(retoPredefinidos)
          ..where((tbl) => tbl.categoria.equals(categoria)))
        .getSingleOrNull();

    if (existente != null) return existente.id;

    return into(retoPredefinidos).insert(
      RetoPredefinidosCompanion(
        categoria: Value(categoria),
        descripcion: Value(
            'Actividad breve generada automáticamente en base a tu $categoria'),
      ),
    );
  }

  Future<bool> necesitaRetoPorInactividad(int usuarioId) async {
    final fechaUltimoCambio = await _fechaUltimoCambioHobby(usuarioId);
    if (fechaUltimoCambio == null) return false;
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaUltimoCambio).inDays;
    return diferencia >= 7;
  }

  Future<RetoDiarioConDetalle> generarRetoPorInactividad(
    int usuarioId,
  ) async {
    final descripcion =
        'Han pasado varios días sin actualizar tus hobbies. ' 'Prueba esta actividad rápida: organiza 15 minutos para retomar tu hobby favorito y compartir un avance.';

    final reto = await guardarRetoGenerado(
      usuarioId: usuarioId,
      descripcion: descripcion,
      esPorInactividad: true,
      origen: 'inactividad',
    );

    await into(notificacions).insert(
      NotificacionsCompanion(
        usuarioId: Value(usuarioId),
        tipo: const Value('reto_inactividad'),
        mensaje: Value('Te asignamos un reto por inactividad: ${reto.detalle.descripcion}'),
      ),
    );

    return reto;
  }

  Future<RetoDiarioConDetalle> generarRetoDiarioDesdePerfil({
    required int usuarioId,
    required String descripcion,
    String origen = 'perfil',
  }) {
    return guardarRetoGenerado(
      usuarioId: usuarioId,
      descripcion: descripcion,
      esPorInactividad: false,
      origen: origen,
    );
  }

  Future<List<RetoDiarioConDetalle>> obtenerHistorialRetos(int usuarioId) async {
    final query = await (select(retoDiarios).join([
      innerJoin(
        retoDiarioDetalles,
        retoDiarioDetalles.retoDiarioId.equalsExp(retoDiarios.id),
      ),
      leftOuterJoin(
        retoPredefinidos,
        retoPredefinidos.id.equalsExp(retoDiarios.retoPredefinidoId),
      ),
    ])
          ..where(retoDiarios.usuarioId.equals(usuarioId))
          ..orderBy([
            OrderingTerm(
              expression: retoDiarioDetalles.fechaCreacion,
              mode: OrderingMode.desc,
            )
          ])).
        get();

    return query
        .map(
          (row) => RetoDiarioConDetalle(
            reto: row.readTable(retoDiarios),
            detalle: row.readTable(retoDiarioDetalles),
            retoPredefinido: row.readTableOrNull(retoPredefinidos),
          ),
        )
        .toList();
  }
}
