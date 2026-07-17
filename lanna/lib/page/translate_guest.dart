import 'package:flutter/material.dart';
import 'translate.dart';

class TranslateGuestPage extends StatelessWidget {
  const TranslateGuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TranslatePage(isGuest: true);
  }
}
