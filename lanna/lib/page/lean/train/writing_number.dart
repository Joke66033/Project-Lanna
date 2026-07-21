import 'package:flutter/material.dart';
import 'package:lanna/services/lanna_char_service.dart';
import 'writing_mode.dart';
import 'writing_data.dart';

class WritingNumberPage extends StatefulWidget {
  const WritingNumberPage({super.key});

  @override
  State<WritingNumberPage> createState() => _WritingNumberPageState();
}

class _WritingNumberPageState extends State<WritingNumberPage> {
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
      final chars = await _charService.getAllCharacters(categoryCharId: 'CL0007');
      if (mounted) {
        setState(() {
          _items = chars.map((c) => WritingItem(
            char: c.lannaChar,
            label: c.thaiEquivalent.split(' ').first,
            type: WritingType.number,
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
      title: 'ฝึกเขียนตัวเลข',
      items: _items,
    );
  }
}
