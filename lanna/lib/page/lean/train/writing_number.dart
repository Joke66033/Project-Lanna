import 'package:flutter/material.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingNumberPage extends StatelessWidget {
  const WritingNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WritingModePage(
      title: 'ฝึกเขียนตัวเลข',
      items: numbers,
    );
  }
}
