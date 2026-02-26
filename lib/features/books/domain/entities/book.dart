import 'package:equatable/equatable.dart';

class Book extends Equatable {
  const Book({
    required this.identifier,
    required this.title,
    required this.modifiedDate,
    required this.coverIdentifier,
    required this.ltr,
  });

  final String identifier;
  final String title;
  final DateTime modifiedDate;
  final String coverIdentifier;
  final bool ltr;

  @override
  List<Object?> get props => <Object?>[
        identifier,
        title,
        modifiedDate,
        coverIdentifier,
        ltr,
      ];
}
