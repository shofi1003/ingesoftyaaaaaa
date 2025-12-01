import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../services/perfil_service.dart';

class HistorialHobbiesScreen extends StatelessWidget {
  final Usuario usuario;
  final PerfilService perfilService;

  const HistorialHobbiesScreen({
    super.key,
    required this.usuario,
    required this.perfilService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de hobbies')),
      body: FutureBuilder<List<HistorialPerfil>>(
        future: perfilService.obtenerHistorialHobbies(usuario.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final historial = snapshot.data!;
          if (historial.isEmpty) {
            return const Center(
              child: Text('Aún no hay cambios registrados.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = historial[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 350),
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${item.fecha.day}/${item.fecha.month}/${item.fecha.year}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cambio en ${item.campoModificado}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Antes: ${item.valorAnterior ?? '-'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Ahora: ${item.valorNuevo ?? '-'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
