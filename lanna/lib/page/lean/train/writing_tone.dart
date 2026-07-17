import 'package:flutter/material.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingTonePage extends StatelessWidget {
  const WritingTonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WritingModePage(
      title: 'ฝึกเขียนวรรณยุกต์',
      items: tones,
    );
  }
}
