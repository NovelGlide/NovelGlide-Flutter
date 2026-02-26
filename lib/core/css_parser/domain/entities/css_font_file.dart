import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'rule_sets/css_font_face.dart';

class CssFontFile extends Equatable {
  const CssFontFile({
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
