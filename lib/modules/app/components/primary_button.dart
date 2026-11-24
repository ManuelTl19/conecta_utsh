import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Style.getPrimaryColor(),
          foregroundColor: Style.getInverseTextColor(),
          disabledBackgroundColor: Style.getPrimaryColor().withValues(
            alpha: .5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Style.getInverseTextColor(),
                ),
              )
            : Text(
                label,
                style: Style.getHeaderOne(
                  color: Style.getInverseTextColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
