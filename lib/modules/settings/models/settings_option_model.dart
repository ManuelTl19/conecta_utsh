import 'package:material_ui/material_ui.dart';

enum SettingsOptionType { navigation, toggle, destructive }

class SettingsOptionModel {
  const SettingsOptionModel({
    required this.section,
    required this.id,
    required this.label,
    required this.icon,
    this.type = SettingsOptionType.navigation,
    this.subtitle,
  });

  final String section;
  final String id;
  final String label;
  final IconData icon;
  final SettingsOptionType type;
  final String? subtitle;
}

const settingsOptions = [
  SettingsOptionModel(
    section: 'Cuenta',
    id: 'profile',
    label: 'Perfil',
    icon: Icons.person_outline_rounded,
  ),
  SettingsOptionModel(
    section: 'Cuenta',
    id: 'personal_info',
    label: 'Información personal',
    icon: Icons.badge_outlined,
  ),
  SettingsOptionModel(
    section: 'Cuenta',
    id: 'password',
    label: 'Cambiar contraseña',
    icon: Icons.lock_outline_rounded,
  ),
  SettingsOptionModel(
    section: 'Cuenta',
    id: 'email',
    label: 'Correo electrónico',
    icon: Icons.email_outlined,
  ),
  SettingsOptionModel(
    section: 'Cuenta',
    id: 'privacy',
    label: 'Privacidad y seguridad',
    icon: Icons.security_outlined,
  ),
  SettingsOptionModel(
    section: 'Apariencia',
    id: 'theme',
    label: 'Tema',
    icon: Icons.dark_mode_outlined,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Apariencia',
    id: 'language',
    label: 'Idioma',
    icon: Icons.language_rounded,
    subtitle: 'Español',
  ),
  SettingsOptionModel(
    section: 'Apariencia',
    id: 'text_size',
    label: 'Tamaño de texto',
    icon: Icons.text_fields_rounded,
    subtitle: 'Estándar',
  ),
  SettingsOptionModel(
    section: 'Notificaciones',
    id: 'push_notifications',
    label: 'Notificaciones push',
    icon: Icons.notifications_none_rounded,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Notificaciones',
    id: 'email_notifications',
    label: 'Notificaciones por correo',
    icon: Icons.mark_email_unread_outlined,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Notificaciones',
    id: 'job_alerts',
    label: 'Alertas de nuevas vacantes',
    icon: Icons.work_outline_rounded,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Notificaciones',
    id: 'sound_vibration',
    label: 'Sonido y vibración',
    icon: Icons.vibration_rounded,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Preferencias de búsqueda',
    id: 'preferred_location',
    label: 'Ubicación preferida',
    icon: Icons.location_on_outlined,
  ),
  SettingsOptionModel(
    section: 'Preferencias de búsqueda',
    id: 'salary_range',
    label: 'Rango salarial',
    icon: Icons.payments_outlined,
  ),
  SettingsOptionModel(
    section: 'Preferencias de búsqueda',
    id: 'employment_type',
    label: 'Tipo de empleo',
    icon: Icons.work_history_outlined,
  ),
  SettingsOptionModel(
    section: 'Soporte y legal',
    id: 'help',
    label: 'Centro de ayuda',
    icon: Icons.help_outline_rounded,
  ),
  SettingsOptionModel(
    section: 'Soporte y legal',
    id: 'support',
    label: 'Contactar soporte',
    icon: Icons.support_agent_rounded,
  ),
  SettingsOptionModel(
    section: 'Soporte y legal',
    id: 'terms',
    label: 'Términos y condiciones',
    icon: Icons.description_outlined,
  ),
  SettingsOptionModel(
    section: 'Soporte y legal',
    id: 'privacy_policy',
    label: 'Política de privacidad',
    icon: Icons.verified_user_outlined,
  ),
  SettingsOptionModel(
    section: 'Soporte y legal',
    id: 'about',
    label: 'Acerca de la app',
    icon: Icons.info_outline_rounded,
    subtitle: 'Versión 0.1.0',
  ),
];
