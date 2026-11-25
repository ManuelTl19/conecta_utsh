import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final NotificacionesController controller;
    try {
      controller = Provider.of<NotificacionesController>(
        context,
        listen: false,
      );
    } on ProviderNotFoundException {
      return _buildButton(context, 0, onPressed);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) =>
          _buildButton(context, controller.unreadCount, () {
            controller.refreshCount();
            onPressed();
          }),
    );
  }

  Widget _buildButton(
    BuildContext context,
    int count,
    VoidCallback buttonAction,
  ) {
    final colors = Theme.of(context).colorScheme;
    final label = count == 0
        ? 'Notificaciones, ninguna sin leer'
        : '$count notificaciones sin leer';

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notificaciones',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              onPressed: buttonAction,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Style.getPrimaryColor(),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Style.getInverseTextColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
