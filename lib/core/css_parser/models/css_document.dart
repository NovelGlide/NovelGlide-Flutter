import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'css_rule.dart';

class CssDocument extends Equatable {
  const CssDocument({required this.ruleMap});

  final LinkedHashMap<String, CssRule> ruleMap;

  @override
  List<Object?> get props => <Object?>[
        ruleMap,
      ];
}
