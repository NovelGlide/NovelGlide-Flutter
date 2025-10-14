import 'package:equatable/equatable.dart';

class HtmlDocument extends Equatable {
  const HtmlDocument({
    required this.stylePathList,
    required this.inlineStyles,
    required this.imgSrcList,
    required this.textContent,
  });

  final List<String> stylePathList;
  final List<String> inlineStyles;
  final List<String> imgSrcList;
  final String textContent;

  @override
  List<Object?> get props => <Object?>[
        stylePathList,
        inlineStyles,
        imgSrcList,
        textContent,
      ];
}
