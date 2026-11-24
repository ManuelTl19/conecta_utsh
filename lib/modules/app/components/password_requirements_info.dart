import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';
import 'package:material_ui/material_ui.dart';

class PasswordRequirementsInfo extends StatelessWidget {
  const PasswordRequirementsInfo({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Requisitos de contraseña',
    onPressed: () => Dialogs.showInfoDialog(
      context,
      title: 'Requisitos de contraseña',
      message:
          '• Mínimo 8 caracteres\n'
          '• Al menos una mayúscula\n'
          '• Al menos un número\n'
          '• Al menos un carácter especial',
      color: Style.getInfoColor(),
    ),
    icon: Icon(
      Icons.info_outline_rounded,
      color: Style.getIconColor(),
      size: 20,
    ),
  );
}
