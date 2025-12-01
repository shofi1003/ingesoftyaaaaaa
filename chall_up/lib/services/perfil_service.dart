import '../data/daos/perfil_dao.dart';
import '../data/database.dart';

/// Coordina la lógica de perfil a partir de los cuestionarios y cambios de hobbies.
class PerfilService {
  final PerfilDao perfilDao;

  PerfilService(this.perfilDao);

  Future<void> guardarCuestionarioInicial({
    required int usuarioId,
    required List<EntradaCuestionarioInicial> entradas,
  }) {
    return perfilDao.guardarCuestionarioInicial(usuarioId, entradas);
  }

  Future<Perfil> generarPerfilDesdeRespuestas({
    required int usuarioId,
    required List<EntradaCuestionarioInicial> entradas,
  }) {
    return perfilDao.generarPerfilDesdeRespuestas(usuarioId, entradas);
  }

  Future<Perfil?> obtenerPerfil(int usuarioId) {
    return perfilDao.obtenerPerfilPorUsuario(usuarioId);
  }

  Future<void> registrarCambioHobby({
    required int usuarioId,
    required String nuevoHobby,
  }) {
    return perfilDao.registrarCambioHobby(usuarioId: usuarioId, valorNuevo: nuevoHobby);
  }

  Future<List<HistorialPerfil>> obtenerHistorialHobbies(int usuarioId) {
    return perfilDao.obtenerHistorialHobbies(usuarioId);
  }
}
