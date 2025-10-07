import 'package:equatable/equatable.dart';

class CssRule extends Equatable {
  const CssRule({
    required this.selector,
  });

  final String selector;
  // TODO(kai): Declaration

  @override
  List<Object?> get props => <Object?>[
        selector,
      ];
}
