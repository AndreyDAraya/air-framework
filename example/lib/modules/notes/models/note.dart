import 'dart:convert';

import 'package:flutter/material.dart';

/// Model representing a note in the application.
///
/// Demonstrates:
/// - Immutable data model with factory constructors
/// - JSON serialization for persistence
/// - copyWith pattern for updates
class Note {
  final String id;
  final String title;
  final String content;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  /// Create a new note with default values
  factory Note.create({
    required String title,
    String content = '',
    Color? color,
  }) {
    final now = DateTime.now();
    return Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      color: color ?? Colors.white,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a note from JSON map
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// Convert note to JSON map for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  /// Create a copy with updated fields
  Note copyWith({
    String? title,
    String? content,
    Color? color,
    bool? isPinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Serialize to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string
  static Note fromJsonString(String jsonString) {
    return Note.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Note(id: $id, title: $title)';
}

/// Predefined colors for notes
class NoteColors {
  static const List<Color> palette = [
    Colors.white,
    Color(0xFFFFF9C4), // Yellow
    Color(0xFFFFCCBC), // Orange
    Color(0xFFF8BBD9), // Pink
    Color(0xFFE1BEE7), // Purple
    Color(0xFFC5CAE9), // Indigo
    Color(0xFFBBDEFB), // Blue
    Color(0xFFB2EBF2), // Cyan
    Color(0xFFC8E6C9), // Green
    Color(0xFFD7CCC8), // Brown
  ];

  static Color get random =>
      palette[DateTime.now().millisecond % palette.length];
}
