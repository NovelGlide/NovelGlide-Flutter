import 'package:equatable/equatable.dart';

class HtmlDocument extends Equatable {
  const HtmlDocument({
    required this.stylePathList,
    required this.inlineStyles,
  });

  final List<String> stylePathList;
  final List<String> inlineStyles;

  @override
  List<Object?> get props => <Object?>[
        stylePathList,
        inlineStyles,
      ];
}
