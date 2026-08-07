import 'package:flutter/material.dart';

/// Navigator เฉพาะพื้นที่เนื้อหาของแท็บเรียนรู้
///
/// การเปิดหน้าผ่านตัวช่วยนี้จะไม่ทับ HomeShell และ BottomNav
/// หากหน้าเรียนรู้ถูกเปิดนอก HomeShell จะย้อนกลับไปใช้ Navigator ปัจจุบัน
/// เพื่อให้หน้ายังทำงานได้ตามปกติ
final GlobalKey<NavigatorState> learningNavigatorKey =
    GlobalKey<NavigatorState>();

Future<T?> pushLearningPage<T>(
  BuildContext context,
  Route<T> route,
) {
  try {
    final navState = learningNavigatorKey.currentState;
    if (navState != null && navState.mounted) {
      return navState.push<T>(route);
    }
  } catch (_) {}
  return Navigator.of(context, rootNavigator: true).push<T>(route);
}
