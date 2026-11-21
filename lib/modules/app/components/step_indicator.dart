import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.step,
    required this.firstTitle,
    required this.secondTitle,
    super.key,
  });

  final int step;
  final String firstTitle;
  final String secondTitle;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Style.getPrimaryColor();
    final inactiveColor = Style.getSubtleColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepMarker(number: 1, completed: step > 0, active: step == 0),
            Container(
              width: 120,
              height: 2,
              color: step > 0 ? primaryColor : inactiveColor,
            ),
            _StepMarker(number: 2, completed: false, active: step == 1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              child: _StepDescription(title: firstTitle, active: step == 0),
            ),
            SizedBox(
              width: 150,
              child: _StepDescription(title: secondTitle, active: step == 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({
    required this.number,
    required this.completed,
    required this.active,
  });

  final int number;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Style.getPrimaryColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active || completed ? primaryColor : Style.getCardColor(),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active || completed ? primaryColor : Style.getSubtleColor(),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: completed
          ? Icon(
              Icons.check_rounded,
              color: Style.getInverseTextColor(),
              size: 19,
            )
          : Text(
              '$number',
              style: Style.getHeaderThree(
                color: active
                    ? Style.getInverseTextColor()
                    : Style.getObscureTextColor(),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _StepDescription extends StatelessWidget {
  const _StepDescription({required this.title, required this.active});

  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Style.getHeaderThree(
        color: active ? Style.getTextColor() : Style.getObscureTextColor(),
        fontSize: 10,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
