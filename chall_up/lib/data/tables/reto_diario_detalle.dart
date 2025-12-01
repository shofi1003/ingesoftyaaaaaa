import 'package:drift/drift.dart';
import 'reto_diario.dart';

/// Guarda el texto generado para un reto diario y metadatos de origen.
class RetoDiarioDetalles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get retoDiarioId => integer().references(RetoDiarios, #id)();
  TextColumn get descripcion => text().withLength(min: 1, max: 240)();
  BoolColumn get generadoPorInactividad =>
      boolean().withDefault(const Constant(false))();
  TextColumn get origen =>
      text().withLength(min: 1, max: 120).withDefault(const Constant('perfil'))();
  DateTimeColumn get fechaCreacion =>
      dateTime().withDefault(currentDateAndTime)();
}
