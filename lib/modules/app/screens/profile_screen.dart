import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.user, super.key});

  final LoginUserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final details = [
      (
        label: 'Correo electrónico',
        value: user.email,
        icon: Icons.email_outlined,
      ),
      (
        label: 'Teléfono',
        value: '+52 771 000 0000',
        icon: Icons.phone_outlined,
      ),
      (
        label: 'Ubicación',
        value: user.location ?? 'Pachuca de Soto, Hidalgo',
        icon: Icons.location_on_outlined,
      ),
      (
        label: 'Sobre mí',
        value: 'Estudiante con interés en crecer profesionalmente.',
        icon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(name: user.name, size: 104),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'UX Designer',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (final detail in details) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(detail.icon, color: colors.primary),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.value,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              // TODO: conectar con el flujo de edición de perfil.
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
        ],
      ),
    );
  }
}
