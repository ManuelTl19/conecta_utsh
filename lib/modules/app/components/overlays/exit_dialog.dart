import 'package:conecta_utsh/helpers/helpers.dart';

class ExitDialog extends StatelessWidget {
  const ExitDialog({super.key});

  String _text(BuildContext context, String key, String fallback) {
    final translation = MultiLanguages.of(context)?.translate(key);
    return translation == null || translation == key ? fallback : translation;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: Style.getPaddingSymmetric(vertical: 20.h, horizontal: 20.w),
          child: Column(
            children: [
              Text(
                _text(context, 'close_app', '¿Deseas salir de la aplicación?'),
                style: Style.getHeaderTwo(
                  color: Style.getPrimaryColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              Icon(
                Icons.exit_to_app_rounded,
                color: Style.getPrimaryColor(),
                size: 30.w,
              ),
              SizedBox(height: 10.h),
              Text(
                _text(
                  context,
                  'close_app_description',
                  'La aplicación se cerrará.',
                ),
                textAlign: TextAlign.center,
                style: Style.getHeaderThree(
                  color: Style.getTextColor(),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Style.getCardColor(),
                  padding: EdgeInsets.all(8.w),
                  elevation: 0,
                  shadowColor: Style.getShadowColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: Style.getOnlyBorderRadius(bottomLeft: 10),
                  ),
                  alignment: Alignment.center,
                ),
                child: Text(
                  _text(context, 'cancel', 'Cancelar'),
                  style: Style.getHeaderThree(
                    color: Style.getPrimaryColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    SystemNavigator.pop();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Style.red,
                  padding: EdgeInsets.all(8.w),
                  elevation: 0,
                  shadowColor: Style.getShadowColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: Style.getOnlyBorderRadius(bottomRight: 10),
                  ),
                  alignment: Alignment.center,
                ),
                child: Text(
                  _text(context, 'exit', 'Salir'),
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
    );
  }
}
