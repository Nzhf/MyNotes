import 'package:flutter/material.dart';
import '../models/ai_state.dart';

/// A custom TextEditingController that underlines grammar issues
class GrammarAwareTextEditingController extends TextEditingController {
  List<GrammarIssueData> _issues = [];

  /// Updates the list of grammar issues and redraws the text
  void updateIssues(List<GrammarIssueData> issues) {
    _issues = issues;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // If no issues, return normal text
    if (_issues.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final List<TextSpan> children = [];
    final String currentText = text;
    int currentOffset = 0;

    // Filter valid issues (within bounds of current text)
    final validIssues = _issues.where((issue) {
      return issue.offset + issue.length <= currentText.length;
    }).toList();

    // Sort issues by offset to ensure correct order processing
    validIssues.sort((a, b) => a.offset.compareTo(b.offset));

    for (final issue in validIssues) {
      // 1. Add normal text before the issue
      if (issue.offset > currentOffset) {
        children.add(
          TextSpan(
            text: currentText.substring(currentOffset, issue.offset),
            style: style,
          ),
        );
      }

      // 2. Add the text with grammar issue (red wavy underline)
      children.add(
        TextSpan(
          text: currentText.substring(
            issue.offset,
            issue.offset + issue.length,
          ),
          style: style?.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: Colors.red,
            // Optional: Add a light red background for better visibility
            // backgroundColor: Colors.red.withOpacity(0.1),
          ),
        ),
      );

      currentOffset = issue.offset + issue.length;
    }

    // 3. Add remaining text
    if (currentOffset < currentText.length) {
      children.add(
        TextSpan(text: currentText.substring(currentOffset), style: style),
      );
    }

    return TextSpan(style: style, children: children);
  }
}
