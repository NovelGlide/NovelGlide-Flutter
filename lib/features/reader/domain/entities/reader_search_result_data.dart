import 'package:equatable/equatable.dart';

class ReaderSearchResultData extends Equatable {
  const ReaderSearchResultData({
    required this.destination,
    required this.excerpt,
    this.targetIndex,
  });

  final String destination;
  final String excerpt;
  final int? targetIndex;

  @override
  List<Object?> get props => <Object?>[
        destination,
        excerpt,
        targetIndex,
      ];
}
