import 'package:flutter/material.dart';

/// Represents a static marker that can be displayed on the map
class StaticMarker {
  /// Unique identifier for the marker
  final String id;
  
  /// Latitude coordinate of the marker
  final double latitude;
  
  /// Longitude coordinate of the marker
  final double longitude;
  
  /// Title/name of the marker
  final String title;
  
  /// Category of the marker (flexible string defined by developers)
  final String category;
  
  /// Optional description of the marker
  final String? description;
  
  /// Optional custom icon identifier from the embedded icon set
  final String? iconId;
  
  /// Optional custom color for the marker
  final Color? customColor;
  
  /// Optional priority level for marker display (higher = more important)
  final int? priority;
  
  /// Whether the marker is currently visible
  final bool isVisible;
  
  /// Flexible metadata map for category-specific information
  final Map<String, dynamic>? metadata;

  const StaticMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.category,
    this.description,
    this.iconId,
    this.customColor,
    this.priority,
    this.isVisible = true,
    this.metadata,
  });

  /// Creates a StaticMarker from a JSON map
  factory StaticMarker.fromJson(Map<String, dynamic> json) {
    return StaticMarker(
      id: json['id'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      iconId: json['iconId'] as String?,
      customColor: json['customColor'] != null 
          ? Color(json['customColor'] as int) 
          : null,
      priority: json['priority'] as int?,
      isVisible: json['isVisible'] as bool? ?? true,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Converts the StaticMarker to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'category': category,
      'description': description,
      'iconId': iconId,
      'customColor': customColor?.value,
      'priority': priority,
      'isVisible': isVisible,
      'metadata': metadata,
    };
  }

  /// Creates a copy of this marker with updated fields
  StaticMarker copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? title,
    String? category,
    String? description,
    String? iconId,
    Color? customColor,
    int? priority,
    bool? isVisible,
    Map<String, dynamic>? metadata,
  }) {
    return StaticMarker(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      iconId: iconId ?? this.iconId,
      customColor: customColor ?? this.customColor,
      priority: priority ?? this.priority,
      isVisible: isVisible ?? this.isVisible,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StaticMarker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StaticMarker(id: $id, title: $title, category: $category, lat: $latitude, lng: $longitude)';
  }
} 