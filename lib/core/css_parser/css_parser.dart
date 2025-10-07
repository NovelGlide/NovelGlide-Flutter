import 'dart:collection';

import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';

import 'models/css_document.dart';
import 'models/css_rule.dart';

class CssParser {
  CssDocument parseDocument(String rawData) {
    final StyleSheet styleSheet = parse(rawData);
    final LinkedHashMap<String, CssRule> ruleMap =
        LinkedHashMap<String, CssRule>();

    for (TreeNode node in styleSheet.topLevels) {
      if (node is RuleSet) {
        final String? selector = node.selectorGroup?.selectors
            .map((Selector s) => s.span?.text ?? '')
            .join(',');

        if (selector?.isNotEmpty == true) {
          ruleMap[selector!] = CssRule(
            selector: selector,
          );
        }
      }
    }

    return CssDocument(
      ruleMap: ruleMap,
    );
  }
}
