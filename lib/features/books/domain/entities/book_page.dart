import 'package:equatable/equatable.dart';

class BookPage extends Equatable {
  const BookPage({
    required this.identifier,
  });

  final String identifier;

  @override
  List<Object?> get props => <Object?>[
        identifier,
      ];
}
