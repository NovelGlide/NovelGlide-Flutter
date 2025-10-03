import 'package:equatable/equatable.dart';

class AppLocale extends Equatable {
  const AppLocale(this.languageCode, [this.scriptCode, this.countryCode]);

  factory AppLocale.fromString(String value) {
    final List<String> parts = value.split('_');
    return AppLocale(
      parts[0],
      parts.length > 1 ? parts[1] : null,
      parts.length > 2 ? parts[2] : null,
    );
  }

  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  @override
  List<Object?> get props => <Object?>[languageCode, scriptCode, countryCode];

  @override
  String toString() => <String?>[languageCode, scriptCode, countryCode]
      .whereType<String>()
      .join('-');
}
