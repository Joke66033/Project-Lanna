import 'package:flutter/material.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingConsonantPage extends StatefulWidget {
  const WritingConsonantPage({super.key});

  @override
  State<WritingConsonantPage> createState() => _WritingConsonantPageState();
}

class _WritingConsonantPageState extends State<WritingConsonantPage> {
  final LannaCharService _charService = LannaCharService();
  List<WritingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final chars = await _charService.getAllCharacters(categoryCharId: 'CL0001,CL0002,CL0003');
      if (mounted) {
        setState(() {
          _items = chars.map((c) => WritingItem(
            char: c.lannaChar,
            label: c.thaiEquivalent.split(' ').first,
            type: WritingType.consonant,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('ไม่มีข้อมูล'),
        ),
      );
    }

    return WritingModePage(
      title: 'ฝึกเขียนพยัญชนะ',
      items: _items,
    );
  }
}
