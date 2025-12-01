import '../data/daos/perfil_dao.dart';
import '../data/daos/reto_dao.dart';
import '../data/database.dart';

/// Contiene la lógica de negocio para generar retos diarios y por inactividad.
class RetoService {
  final RetoDao retoDao;
  final PerfilDao perfilDao;

  RetoService({required this.retoDao, required this.perfilDao});

  Future<RetoDiarioConDetalle> generarRetoDelDia(int usuarioId) async {
    final perfil = await perfilDao.obtenerPerfilPorUsuario(usuarioId);
    final descripcion = _construirDescripcionDesdePerfil(perfil);
    return retoDao.generarRetoDiarioDesdePerfil(
      usuarioId: usuarioId,
      descripcion: descripcion,
      origen: 'perfil',
    );
  }

  Future<RetoDiarioConDetalle> generarRetoPorInactividad(int usuarioId) {
    return retoDao.generarRetoPorInactividad(usuarioId);
  }

  Future<RetoDiarioConDetalle> obtenerORenovarReto(int usuarioId) async {
    final retoHoy = await retoDao.obtenerRetoDelDia(usuarioId);
    if (retoHoy != null) return retoHoy;

    final requiereInactividad = await retoDao.necesitaRetoPorInactividad(usuarioId);
    if (requiereInactividad) {
      return generarRetoPorInactividad(usuarioId);
    }
    return generarRetoDelDia(usuarioId);
  }

  Future<List<RetoDiarioConDetalle>> obtenerHistorial(int usuarioId) {
    return retoDao.obtenerHistorialRetos(usuarioId);
  }

  String _construirDescripcionDesdePerfil(Perfil? perfil) {
    if (perfil == null) {
      return 'Elige una actividad breve que siempre hayas querido probar y compártela con alguien cercano.';
    }

    final buffer = StringBuffer('Tu reto de hoy: ');
    final hobby = (perfil.hobbies ?? '').split(',').firstWhere(
          (h) => h.trim().isNotEmpty,
          orElse: () => '',
        );
    final habito = (perfil.habitos ?? '').split(',').firstWhere(
          (h) => h.trim().isNotEmpty,
          orElse: () => '',
        );
    final meta = (perfil.metas ?? '').split(',').firstWhere(
          (m) => m.trim().isNotEmpty,
          orElse: () => '',
        );

    if (hobby.isNotEmpty) {
      buffer.write('dedica 20 minutos a "$hobby" ');
    } else {
      buffer.write('prueba un hobby nuevo ');
    }

    if (meta.isNotEmpty) {
      buffer.write('alineado con tu meta de $meta ');
    }

    if (habito.isNotEmpty) {
      buffer.write('y refuerza el hábito de $habito.');
    } else {
      buffer.write('y comparte cómo te hizo sentir.');
    }

    return buffer.toString();
  }
}
