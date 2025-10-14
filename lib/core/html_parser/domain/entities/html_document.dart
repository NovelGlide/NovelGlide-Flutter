import 'package:equatable/equatable.dart';
import 'package:html/dom.dart';

class HtmlDocument extends Equatable {
  const HtmlDocument({
    required this.stylePathList,
    required this.inlineStyles,
    required this.imgSrcList,
    required this.textContent,
    required this.domTree,
  });

  final List<String> stylePathList;
  final List<String> inlineStyles;
  final List<String> imgSrcList;
  final String textContent;
  final Document domTree;

  @override
  List<Object?> get props => <Object?>[
        stylePathList,
        inlineStyles,
        imgSrcList,
        textContent,
        domTree,
      ];
}
