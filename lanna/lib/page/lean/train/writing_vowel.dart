import 'package:flutter/material.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingVowelPage extends StatelessWidget {
  const WritingVowelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WritingModePage(
      title: 'ฝึกเขียนสระ',
      items: vowels,
    );
  }
}
