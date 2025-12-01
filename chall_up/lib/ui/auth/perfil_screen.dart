import 'package:flutter/material.dart';

import '../../data/daos/perfil_dao.dart';
import '../../data/daos/reto_dao.dart';
import '../../data/daos/usuario_dao.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';
import '../../services/perfil_service.dart';
import '../../services/reto_service.dart';
import 'cuestionario_inicial_screen.dart';
import 'historial_hobbies_screen.dart';
import 'reto_diario_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  final UsuarioDao usuarioDao;

  const PerfilScreen({
    super.key,
    required this.usuario,
    required this.usuarioDao,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final PerfilService _perfilService;
  late final RetoService _retoService;
  Perfil? _perfil;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider.db;
    _perfilService = PerfilService(PerfilDao(db));
    _retoService = RetoService(
      retoDao: RetoDao(db),
      perfilDao: PerfilDao(db),
    );
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final perfil = await _perfilService.obtenerPerfil(widget.usuario.id);
    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _cargando = false;
    });
  }

  Future<void> _actualizarHobby() async {
    final controller = TextEditingController(text: _perfil?.hobbies ?? '');
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Actualizar hobbies'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Hobbies',
              hintText: 'Ejemplo: pintura digital, yoga, ciclismo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (nuevo != null && nuevo.isNotEmpty) {
      await _perfilService.registrarCambioHobby(
        usuarioId: widget.usuario.id,
        nuevoHobby: nuevo,
      );
      await _cargarPerfil();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hobbies actualizados y registrados en historial.')),
      );
    }
  }

  Widget _buildPerfilCard(ThemeData theme) {
    final perfil = _perfil;
    if (perfil == null) {
      return _EmptyPerfilCard(onStart: () async {
        final resultado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CuestionarioInicialScreen(usuario: widget.usuario),
          ),
        );
        if (resultado == true) {
          _cargarPerfil();
        }
      });
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi perfil', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _PerfilTile(icon: Icons.palette, title: 'Hobby principal', value: perfil.hobbies ?? 'Pendiente'),
            _PerfilTile(icon: Icons.self_improvement, title: 'Hábitos', value: perfil.habitos ?? 'Pendiente'),
            _PerfilTile(icon: Icons.flag, title: 'Metas', value: perfil.metas ?? 'Pendiente'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _actualizarHobby,
                  icon: const Icon(Icons.edit),
                  label: const Text('Actualizar hobbies'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistorialHobbiesScreen(
                          usuario: widget.usuario,
                          perfilService: _perfilService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Ver historial'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRetoCard() {
    return FutureBuilder<RetoDiarioConDetalle>(
      future: _retoService.obtenerORenovarReto(widget.usuario.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          );
        }
        final reto = snapshot.data!;
        return Card(
          color: reto.detalle.generadoPorInactividad
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      reto.detalle.generadoPorInactividad
                          ? Icons.alarm
                          : Icons.bolt,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reto.detalle.generadoPorInactividad
                          ? 'Reto por inactividad'
                          : 'Reto del día',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reto.detalle.descripcion,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RetoDiarioScreen(
                          usuario: widget.usuario,
                          retoService: _retoService,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ver más'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarPerfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPerfilCard(theme),
                    const SizedBox(height: 16),
                    _buildRetoCard(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PerfilTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PerfilTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _EmptyPerfilCard extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyPerfilCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.person_add_alt_1, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Aún no has generado tu perfil',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa el cuestionario inicial para recibir retos alineados a tus hobbies.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onStart,
              child: const Text('Crear mi perfil'),
            )
          ],
        ),
      ),
    );
  }
}
