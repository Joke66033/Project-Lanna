import 'package:flutter/material.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingConsonantPage extends StatelessWidget {
  const WritingConsonantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WritingModePage(
      title: 'ฝึกเขียนพยัญชนะ',
      items: consonants,
    );
  }
}
