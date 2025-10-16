import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../css_parser/domain/entities/rule_sets/css_font_face.dart';

class FontFile extends Equatable {
  const FontFile({
    required this.fontFace,
    required this.bytes,
  });

  final CssFontFace fontFace;
  final Uint8List bytes;

  @override
  List<Object?> get props => <Object?>[
        fontFace,
        bytes,
      ];
}
