import 'dart:convert';
import 'package:flutter/material.dart';

class CharacterStrokeModel {
  final int? strokeId;
  final String charSymbol;
  final String? charName;
  final String category;
  final int strokeCount;
  final List<List<Offset>> strokePaths;
  final String? createdAt;
  final String? updatedAt;

  CharacterStrokeModel({
    this.strokeId,
    required this.charSymbol,
    this.charName,
    required this.category,
    required this.strokeCount,
    required this.strokePaths,
    this.createdAt,
    this.updatedAt,
  });

  factory CharacterStrokeModel.fromJson(Map<String, dynamic> json) {
    List<List<Offset>> parsedPaths = [];

    dynamic rawStrokes = json['stroke_data'];
    if (rawStrokes is String && rawStrokes.isNotEmpty) {
      try {
        rawStrokes = jsonDecode(rawStrokes);
      } catch (e) {
        rawStrokes = [];
      }
    }

    if (rawStrokes is List) {
      for (var stroke in rawStrokes) {
        if (stroke is List) {
          List<Offset> points = [];
          for (var pt in stroke) {
            if (pt is Map) {
              final double dx = (pt['x'] as num?)?.toDouble() ?? 0.0;
              final double dy = (pt['y'] as num?)?.toDouble() ?? 0.0;
              points.add(Offset(dx, dy));
            } else if (pt is List && pt.length >= 2) {
              final double dx = (pt[0] as num?)?.toDouble() ?? 0.0;
              final double dy = (pt[1] as num?)?.toDouble() ?? 0.0;
              points.add(Offset(dx, dy));
            }
          }
          if (points.isNotEmpty) {
            parsedPaths.add(points);
          }
        }
      }
    }

    return CharacterStrokeModel(
      strokeId: json['stroke_id'] is int ? json['stroke_id'] : int.tryParse(json['stroke_id']?.toString() ?? ''),
      charSymbol: json['char_symbol']?.toString() ?? '',
      charName: json['char_name']?.toString(),
      category: json['category']?.toString() ?? 'consonant',
      strokeCount: (json['stroke_count'] is int) ? json['stroke_count'] : int.tryParse(json['stroke_count']?.toString() ?? '') ?? parsedPaths.length,
      strokePaths: parsedPaths,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final rawStrokes = strokePaths.map((stroke) {
      return stroke.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList();
    }).toList();

    return {
      if (strokeId != null) 'stroke_id': strokeId,
      'char_symbol': charSymbol,
      'char_name': charName,
      'category': category,
      'stroke_count': strokeCount,
      'stroke_data': rawStrokes,
    };
  }
}
