import 'package:flutter/material.dart';

import '../../data/daos/perfil_dao.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';
import '../../services/perfil_service.dart';

class CuestionarioInicialScreen extends StatefulWidget {
  final Usuario usuario;

  const CuestionarioInicialScreen({super.key, required this.usuario});

  @override
  State<CuestionarioInicialScreen> createState() => _CuestionarioInicialScreenState();
}

class _CuestionarioInicialScreenState extends State<CuestionarioInicialScreen> {
  late final PerfilService _perfilService;

  final _hobbiesController = TextEditingController();
  final _habitosController = TextEditingController();
  final _metasController = TextEditingController();
  int _pasoActual = 0;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider.db;
    _perfilService = PerfilService(PerfilDao(db));
  }

  @override
  void dispose() {
    _hobbiesController.dispose();
    _habitosController.dispose();
    _metasController.dispose();
    super.dispose();
  }

  List<EntradaCuestionarioInicial> _construirEntradas() {
    return [
      EntradaCuestionarioInicial(
        textoPregunta: '¿Cuáles son tus hobbies principales?',
        tipoPregunta: 'seleccion_multiple',
        respuesta: _hobbiesController.text.trim(),
        campoPerfil: PerfilCampo.hobby,
      ),
      EntradaCuestionarioInicial(
        textoPregunta: '¿Qué hábito te gustaría reforzar?',
        tipoPregunta: 'texto',
        respuesta: _habitosController.text.trim(),
        campoPerfil: PerfilCampo.habito,
      ),
      EntradaCuestionarioInicial(
        textoPregunta: '¿Qué meta personal quieres alcanzar este mes?',
        tipoPregunta: 'texto',
        respuesta: _metasController.text.trim(),
        campoPerfil: PerfilCampo.meta,
      ),
    ];
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final entradas = _construirEntradas();

    try {
      await _perfilService.guardarCuestionarioInicial(
        usuarioId: widget.usuario.id,
        entradas: entradas,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuestionario guardado. Perfil generado.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  bool _validarPaso(int paso) {
    switch (paso) {
      case 0:
        return _hobbiesController.text.trim().isNotEmpty;
      case 1:
        return _habitosController.text.trim().isNotEmpty;
      case 2:
        return _metasController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = [
      _PasoCuestionario(
        titulo: 'Hobbies',
        descripcion: 'Elige o escribe tus hobbies favoritos para personalizar tus retos diarios.',
        controlador: _hobbiesController,
        icono: Icons.palette,
        helper: 'Ejemplo: pintar, correr, leer ficción',
      ),
      _PasoCuestionario(
        titulo: 'Hábitos',
        descripcion: 'Indica el hábito que quieras reforzar con mini retos.',
        controlador: _habitosController,
        icono: Icons.self_improvement,
        helper: 'Ejemplo: meditar 5 minutos, beber agua',
      ),
      _PasoCuestionario(
        titulo: 'Metas',
        descripcion: 'Cuéntanos tu meta principal del mes para alinear las actividades.',
        controlador: _metasController,
        icono: Icons.flag,
        helper: 'Ejemplo: terminar un libro, crear un portafolio',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuestionario inicial'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stepper(
            currentStep: _pasoActual,
            type: StepperType.horizontal,
            onStepContinue: () {
              if (!_validarPaso(_pasoActual)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa este paso antes de avanzar.')),
                );
                return;
              }
              if (_pasoActual == pasos.length - 1) {
                _guardar();
              } else {
                setState(() => _pasoActual++);
              }
            },
            onStepCancel: _pasoActual == 0
                ? null
                : () => setState(() => _pasoActual = _pasoActual - 1),
            controlsBuilder: (context, details) {
              final esUltimo = _pasoActual == pasos.length - 1;
              return Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : details.onStepContinue,
                    icon: Icon(esUltimo ? Icons.check : Icons.arrow_forward),
                    label: Text(esUltimo ? 'Guardar y generar mi perfil' : 'Siguiente'),
                  ),
                  const SizedBox(width: 12),
                  if (_pasoActual > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Anterior'),
                    ),
                ],
              );
            },
            steps: [
              for (final paso in pasos)
                Step(
                  title: Text(paso.titulo),
                  isActive: pasos.indexOf(paso) <= _pasoActual,
                  state: pasos.indexOf(paso) < _pasoActual
                      ? StepState.complete
                      : StepState.indexed,
                  content: paso,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasoCuestionario extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final TextEditingController controlador;
  final IconData icono;
  final String helper;

  const _PasoCuestionario({
    required this.titulo,
    required this.descripcion,
    required this.controlador,
    required this.icono,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
              child: Icon(icono),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                descripcion,
                style: theme.textTheme.bodyMedium,
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controlador,
          decoration: InputDecoration(
            labelText: titulo,
            helperText: helper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
