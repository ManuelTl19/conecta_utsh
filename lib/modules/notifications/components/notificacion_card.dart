import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/notifications/models/notificacion.dart';

class NotificacionCard extends StatelessWidget {
  const NotificacionCard({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final Notificacion notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Style.successDark : colors.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: Style.getCircularBorderRadius(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: Style.getPaddingAll(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconForType(notification.tipo),
                  size: 20,
                  color: iconColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: notification.leida
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontWeight: notification.leida
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      notification.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: notification.leida
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _relativeTime(notification.fechaRegistro),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (!notification.leida)
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) => switch (type.toLowerCase()) {
    'cita' => Icons.calendar_month_outlined,
    'solicitud' => Icons.assignment_outlined,
    _ => Icons.notifications_none_rounded,
  };

  String _relativeTime(DateTime timestamp) {
    final localTimestamp = timestamp.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTimestamp);
    final dayDifference = DateUtils.dateOnly(now)
        .difference(DateUtils.dateOnly(localTimestamp))
        .inDays;
    if (dayDifference == 1) return 'ayer';
    if (difference.isNegative || difference.inMinutes == 0) {
      return 'hace un momento';
    }
    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) return 'hace ${difference.inHours} h';
    if (dayDifference < 7) return 'hace $dayDifference días';
    return DateFormat('dd/MM/yyyy').format(localTimestamp);
  }
}
