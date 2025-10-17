import 'package:equatable/equatable.dart';
import 'package:html/dom.dart';

class HtmlDocument extends Equatable {
  const HtmlDocument({
    required this.stylePathList,
    required this.inlineStyles,
    required this.imgSrcList,
    required this.domTree,
  });

  final List<String> stylePathList;
  final List<String> inlineStyles;
  final List<String> imgSrcList;
  final Document domTree;

  @override
  List<Object?> get props => <Object?>[
        stylePathList,
        inlineStyles,
        imgSrcList,
        domTree,
      ];

  HtmlDocument copyWith({
    List<String>? stylePathList,
    List<String>? inlineStyles,
    List<String>? imgSrcList,
    Document? domTree,
  }) {
    return HtmlDocument(
      stylePathList: stylePathList ?? this.stylePathList,
      inlineStyles: inlineStyles ?? this.inlineStyles,
      imgSrcList: imgSrcList ?? this.imgSrcList,
      domTree: domTree ?? this.domTree,
    );
  }
}
