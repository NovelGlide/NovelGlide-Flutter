import 'dart:ui';

import 'package:equatable/equatable.dart';

class CssFontFace extends Equatable {
  const CssFontFace({
    required this.fontFamily,
    required this.fontStyle,
    required this.fontWeight,
    required this.url,
  });

  final String fontFamily;
  final FontStyle fontStyle;
  final FontWeight fontWeight;
  final String url;

  @override
  List<Object?> get props => <Object?>[
        fontFamily,
        fontStyle,
        fontWeight,
        url,
      ];
}
