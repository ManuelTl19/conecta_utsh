import 'package:conecta_utsh/helpers/helpers.dart';
import 'package:conecta_utsh/modules/app/components/overlays/overlays.dart';
import 'package:conecta_utsh/modules/app/components/overlays/dialog_animation.dart';
import 'package:lottie/lottie.dart';

class Dialogs {
  // Function to show a simple dialog
  static Future<void> showSimpleDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? svg,
    IconData? icon,
    required Color color,
    int duration = 1500,
  }) async {
    late BuildContext dialogContext;
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return DialogAnimation(
          content: SimpleDialogContent(
            title: title,
            message: message,
            svg: svg ?? '',
            icon: icon ?? Icons.info_outline_rounded,
            color: color,
          ),
        );
      },
    );

    Future.delayed(Duration(milliseconds: duration), () {
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    });
    await dialog;
  }

  static showLoader(BuildContext context, {String message = 'Cargando...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    message,
                    style: Style.getTextStyle(
                      color: Style.getTextColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to show a dialog with a buttons for actions
  static showComplexDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? svg,
    IconData? icon,
    required Color color,
    required List<Widget> actions,
  }) async {
    showDialog(
      context: context,
      builder: (context) => DialogAnimation(
        content: ComplexDialogContent(
          title: title,
          message: message,
          svg: svg ?? '',
          icon: icon ?? Icons.info_outline_rounded,
          color: color,
          actions: actions,
        ),
      ),
    );
  }

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    IconData icon = Icons.info_outline_rounded,
    String acceptText = 'Aceptar',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DialogAnimation(
        content: ComplexDialogContent(
          title: title,
          message: message,
          svg: '',
          icon: icon,
          color: color,
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Style.getInverseTextColor(),
                  minimumSize: Size.fromHeight(46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: Style.getOnlyBorderRadius(
                      bottomLeft: 12,
                      bottomRight: 12,
                    ),
                  ),
                ),
                child: Text(acceptText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a confirmation dialog for deletion
  static Future<bool?> showConfirmDialogDelete(
    BuildContext context, {
    required String title,
    required String message,
    String? svg,
    IconData? icon,
    required String confirmText,
    required String cancelText,
    Color confirmColor = Colors.green,
    Color cancelColor = Colors.red,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => DialogAnimation(
        content: ComplexDialogContent(
          title: title,
          message: message,
          svg: svg ?? '',
          icon: icon ?? Icons.info_outline_rounded,
          color: cancelColor,
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: cancelColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: Style.getOnlyBorderRadius(
                      bottomLeft: 12,
                      bottomRight: 0,
                    ),
                  ),
                ),
                child: Text(cancelText),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: Style.getOnlyBorderRadius(
                      bottomLeft: 0,
                      bottomRight: 12,
                    ),
                  ),
                ),
                child: Text(confirmText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String svg, // Se espera siempre un Lottie
    IconData? icon,
    required String confirmText,
    required String cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(svg, height: 80.w),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: Style.getHeaderOne(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  style: Style.getHeaderTwo(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Style.getCardColor(),
                          padding: EdgeInsets.all(8.w),
                          elevation: 0,
                          shadowColor: Style.getShadowColor(),
                          shape: RoundedRectangleBorder(
                            borderRadius: Style.getOnlyBorderRadius(
                              bottomLeft: 10,
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                        child: Text(
                          cancelText,
                          style: Style.getHeaderThree(
                            color: Style.getPrimaryColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Style.red,
                          padding: EdgeInsets.all(8.w),
                          elevation: 0,
                          shadowColor: Style.getShadowColor(),
                          shape: RoundedRectangleBorder(
                            borderRadius: Style.getOnlyBorderRadius(
                              bottomRight: 10,
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                        child: Text(
                          confirmText,
                          style: Style.getHeaderThree(
                            color: Style.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  // Function to show exit dialog
  static exitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DialogAnimation(content: ExitDialog()),
    );
  }

  // Function to show log out dialog
  // static showLogOutDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => DialogAnimation(content: const LogOutDialog()),
  //   );
  // }
}
