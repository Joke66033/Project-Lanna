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
  final navigator = learningNavigatorKey.currentState ?? Navigator.of(context);
  return navigator.push<T>(route);
}
