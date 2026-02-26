import 'package:equatable/equatable.dart';
import 'package:novel_glide/core/css_parser/domain/entities/rule_sets/css_font_face.dart';

class CssDocument extends Equatable {
  const CssDocument({
    required this.content,
    required this.fontFaces,
  });

  final String content;
  final List<CssFontFace> fontFaces;

  @override
  List<Object?> get props => <Object?>[
        content,
        fontFaces,
      ];
}
