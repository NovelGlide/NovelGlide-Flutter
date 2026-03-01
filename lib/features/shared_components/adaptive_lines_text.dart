import 'package:flutter/material.dart';

class AdaptiveLinesText extends StatelessWidget {
  const AdaptiveLinesText(
    this.text, {
    super.key,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle =
        style ?? Theme.of(context).textTheme.bodyMedium;
    final double fontSize = textStyle?.fontSize ?? 14.0;
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).scale(fontSize);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int maxLines =
            ((constraints.maxHeight / textScaleFactor) * 0.8).floor();
        return Text(
          text,
          maxLines: maxLines,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
