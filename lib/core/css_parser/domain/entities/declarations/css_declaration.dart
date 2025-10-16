import 'package:equatable/equatable.dart';

class CssDeclaration extends Equatable {
  const CssDeclaration(this.property, this.value);

  final String property;
  final String value;

  @override
  List<Object?> get props => <Object?>[
        property,
        value,
      ];

  @override
  String toString() => '$property: $value;';
}
