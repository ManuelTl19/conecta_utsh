import 'package:material_ui/material_ui.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _questions = [
    (
      question: '¿Cómo actualizo mis datos personales?',
      answer: 'Abre tu perfil y selecciona la opción para editarlo. Los datos de cuenta que no se puedan editar aparecerán como solo lectura.',
    ),
    (
      question: '¿Cómo solicito una estadía?',
      answer: 'Busca una empresa en el catálogo y usa la opción para solicitar la estadía. También puedes registrar una empresa propia si ya te aceptó.',
    ),
    (
      question: '¿Dónde consulto el avance de mi solicitud?',
      answer: 'Abre “Mis solicitudes” desde el menú lateral. Ahí puedes revisar el estado y los detalles de cada proceso.',
    ),
    (
      question: '¿Cuándo puedo cancelar una solicitud?',
      answer: 'La opción de cancelación está disponible mientras la solicitud se encuentre registrada o en proceso.',
    ),
    (
      question: '¿Cuándo puedo dejar una reseña?',
      answer: 'Puedes calificar la empresa cuando tu estadía haya finalizado. Encontrarás la opción en el detalle de la solicitud.',
    ),
    (
      question: '¿Cómo cambio mi contraseña?',
      answer: 'Entra a Configuraciones y selecciona “Cambiar contraseña”. Necesitarás ingresar tu contraseña actual.',
    ),
    (
      question: '¿Puedo cambiar el correo de mi cuenta?',
      answer: 'Por el momento, Configuraciones solo muestra el correo registrado. La aplicación no tiene habilitada la edición del correo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Centro de ayuda'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Text(
            'Preguntas frecuentes',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < _questions.length; index++) ...[
                  ExpansionTile(
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: colors.primary,
                    ),
                    title: Text(
                      _questions[index].question,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _questions[index].answer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  if (index < _questions.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
