import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.step,
    this.firstTitle,
    this.secondTitle,
    this.thirdTitle,
    this.stepCount,
    super.key,
  });

  final int step;
  final String? firstTitle;
  final String? secondTitle;
  final String? thirdTitle;
  final int? stepCount;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Style.getPrimaryColor();
    final inactiveColor = Style.getSubtleColor();
    final titles = [firstTitle, secondTitle, thirdTitle];
    final totalSteps = stepCount ?? (thirdTitle == null ? 2 : 3);
    final showTitles = titles.any((title) => title?.trim().isNotEmpty ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var index = 0; index < totalSteps; index++) ...[
              _StepMarker(
                number: index + 1,
                completed: step > index,
                active: step == index,
              ),
              if (index < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: step > index ? primaryColor : inactiveColor,
                  ),
                ),
            ],
          ],
        ),
        if (showTitles) ...[
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              totalSteps,
              (index) => Expanded(
                child: _StepDescription(
                  title: titles[index] ?? '',
                  active: step == index,
                  compact: totalSteps > 2,
                ),
              ),
            ),
          ),
        ],
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
  const _StepDescription({
    required this.title,
    required this.active,
    required this.compact,
  });

  final String title;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Style.getHeaderThree(
        color: active ? Style.getTextColor() : Style.getObscureTextColor(),
        fontSize: compact ? 9 : 10,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
