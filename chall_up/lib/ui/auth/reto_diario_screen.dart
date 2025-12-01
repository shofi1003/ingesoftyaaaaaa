import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../services/reto_service.dart';

class RetoDiarioScreen extends StatelessWidget {
  final Usuario usuario;
  final RetoService retoService;

  const RetoDiarioScreen({
    super.key,
    required this.usuario,
    required this.retoService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reto diario')),
      body: FutureBuilder<RetoDiarioConDetalle>(
        future: retoService.obtenerORenovarReto(usuario.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reto = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Icon(
                    reto.detalle.generadoPorInactividad ? Icons.alarm : Icons.bolt,
                  ),
                  label: Text(
                    reto.detalle.generadoPorInactividad
                        ? 'Generado por inactividad'
                        : 'Personalizado con tu perfil',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  reto.detalle.descripcion,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Fecha: ${reto.detalle.fechaCreacion.toLocal()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final nuevoReto = await retoService.generarRetoDelDia(usuario.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nuevo reto: ${nuevoReto.detalle.descripcion}')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerar con perfil'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
