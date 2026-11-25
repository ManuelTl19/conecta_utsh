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
    section: 'Preferencias',
    id: 'theme',
    label: 'Tema',
    icon: Icons.dark_mode_outlined,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Preferencias',
    id: 'push_notifications',
    label: 'Notificaciones push',
    icon: Icons.notifications_none_rounded,
    type: SettingsOptionType.toggle,
  ),
  SettingsOptionModel(
    section: 'Ayuda y soporte',
    id: 'help',
    label: 'Centro de ayuda y preguntas frecuentes',
    icon: Icons.help_outline_rounded,
  ),
  SettingsOptionModel(
    section: 'Ayuda y soporte',
    id: 'about',
    label: 'Acerca de la app',
    icon: Icons.info_outline_rounded,
    subtitle: 'Versión 0.1.0',
  ),
];
