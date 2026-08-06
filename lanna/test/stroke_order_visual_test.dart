import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanna/page/lean/train/writing_canvas.dart';

void main() {
  testWidgets('multi-stroke guide keeps paths and labels aligned', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFDF9F4),
          body: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: 420,
                height: 420,
                child: WritingCanvas(
                  guideChar: 'ᨠ',
                  character: 'ᨠ',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/stroke_order_ka.png'),
    );
  });

  testWidgets('every learning item renders the complete tracing guide', (
    tester,
  ) async {
    final codePointPattern = RegExp(r'U\+([0-9A-F]{4,6})');
    final learningItems = File('codepoints_out.txt')
        .readAsLinesSync()
        .where((line) => line.startsWith('ID:'))
        .map((line) {
          final character = codePointPattern
              .allMatches(line)
              .map(
                (match) =>
                    String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
              )
              .join();
          return (character: character, source: line);
        })
        .toList();

    expect(learningItems.length, 148);

    for (final item in learningItems) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: WritingCanvas(
                key: ValueKey(item.character),
                guideChar: item.character,
                character: item.character,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: item.source);
    }
  });
}
