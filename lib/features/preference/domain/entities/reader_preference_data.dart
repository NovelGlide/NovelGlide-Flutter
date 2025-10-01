import 'package:equatable/equatable.dart';

import '../../../reader/domain/entities/reader_core_type.dart';
import '../../../reader/domain/entities/reader_page_num_type.dart';

/// Represents the settings for a reader, including font size, line height, and other preferences.
class ReaderPreferenceData extends Equatable {
  const ReaderPreferenceData({
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.isAutoSaving = false,
    this.isSmoothScroll = false,
    this.pageNumType = ReaderPageNumType.number,
    this.coreType = ReaderCoreType.html,
  });

  final double fontSize;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;

  final double lineHeight;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;

  final bool isAutoSaving;
  final bool isSmoothScroll;

  final ReaderPageNumType pageNumType;
  final ReaderCoreType coreType;

  @override
  List<Object?> get props => <Object?>[
        fontSize,
        lineHeight,
        isAutoSaving,
        isSmoothScroll,
        pageNumType,
        coreType,
      ];

  /// Creates a copy of the current settings with optional new values.
  ReaderPreferenceData copyWith({
    double? fontSize,
    double? lineHeight,
    bool? isAutoSaving,
    bool? isSmoothScroll,
    ReaderPageNumType? pageNumType,
    ReaderCoreType? coreType,
  }) {
    return ReaderPreferenceData(
      fontSize: (fontSize ?? this.fontSize).clamp(minFontSize, maxFontSize),
      lineHeight:
          (lineHeight ?? this.lineHeight).clamp(minLineHeight, maxLineHeight),
      isAutoSaving: isAutoSaving ?? this.isAutoSaving,
      isSmoothScroll: isSmoothScroll ?? this.isSmoothScroll,
      pageNumType: pageNumType ?? this.pageNumType,
      coreType: coreType ?? this.coreType,
    );
  }
}
