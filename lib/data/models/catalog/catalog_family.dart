import 'package:flutter/material.dart';

/// Exam / Course Family under a [CatalogCategory2] (e.g. "Chartered Accountancy",
/// "Joint Entrance Examination (JEE)", "Staff Selection Commission (SSC)").
@immutable
class CatalogFamily {
  const CatalogFamily({
    required this.id,
    required this.categoryId,
    required this.title,
    this.shortTitle,
    this.code,
    this.description,
    this.iconName,
    this.iconData,
    this.order = 0,
    this.isPopular = false,
    this.aliases = const [],
    this.programIds = const [],
    this.metadata,
    this.isActive = true,
  });

  final String id;
  final String categoryId;
  final String title;
  final String? shortTitle;
  final String? code;
  final String? description;
  final String? iconName;
  final IconData? iconData;
  final int order;
  final bool isPopular;
  final List<String> aliases;
  final List<String> programIds;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  String get displayTitle => shortTitle ?? title;

  IconData get resolvedIcon {
    if (iconData != null) return iconData!;
    return switch (iconName ?? id) {
      'ca' || 'cma' || 'cs' => Icons.account_balance_wallet_rounded,
      'cfa' || 'frm' || 'acca' => Icons.trending_up_rounded,
      'jee' || 'gate' || 'mht_cet' => Icons.engineering_rounded,
      'neet' => Icons.medical_services_rounded,
      'clat' || 'ailet' => Icons.gavel_rounded,
      'cat' || 'xat' || 'snap' => Icons.business_center_rounded,
      'upsc' || 'ssc' || 'state_psc' => Icons.account_balance_rounded,
      'banking' || 'ibps' || 'sbi' => Icons.payments_rounded,
      'defence' || 'nda' || 'cds' => Icons.shield_rounded,
      'ugc_net' || 'teaching' => Icons.menu_book_rounded,
      'design' || 'uceed' || 'nid' => Icons.palette_rounded,
      'architecture' || 'nata' => Icons.apartment_rounded,
      'agriculture' || 'icar' => Icons.agriculture_rounded,
      'cuet' => Icons.school_rounded,
      'cbse' || 'icse' || 'state_board' => Icons.auto_stories_rounded,
      _ => Icons.folder_special_rounded,
    };
  }

  CatalogFamily copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? shortTitle,
    String? code,
    String? description,
    String? iconName,
    IconData? iconData,
    int? order,
    bool? isPopular,
    List<String>? aliases,
    List<String>? programIds,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return CatalogFamily(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      code: code ?? this.code,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      iconData: iconData ?? this.iconData,
      order: order ?? this.order,
      isPopular: isPopular ?? this.isPopular,
      aliases: aliases ?? this.aliases,
      programIds: programIds ?? this.programIds,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'title': title,
    if (shortTitle != null) 'shortTitle': shortTitle,
    if (code != null) 'code': code,
    if (description != null) 'description': description,
    if (iconName != null) 'iconName': iconName,
    'order': order,
    'isPopular': isPopular,
    'aliases': aliases,
    'programIds': programIds,
    if (metadata != null) 'metadata': metadata,
    'isActive': isActive,
  };

  factory CatalogFamily.fromJson(Map<String, dynamic> json) {
    return CatalogFamily(
      id: (json['id'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      shortTitle: json['shortTitle'] as String?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      iconName: json['iconName'] as String?,
      order: (json['order'] as int?) ?? 0,
      isPopular: (json['isPopular'] as bool?) ?? false,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      programIds: (json['programIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogFamily &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
