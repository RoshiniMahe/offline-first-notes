import 'package:hive/hive.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
enum SyncStatusModel {
  @HiveField(0)
  synced,
  @HiveField(1)
  pendingSync,
  @HiveField(2)
  conflict,
}

extension SyncStatusModelX on SyncStatusModel {
  SyncStatus toEntity() {
    switch (this) {
      case SyncStatusModel.synced:
        return SyncStatus.synced;
      case SyncStatusModel.pendingSync:
        return SyncStatus.pendingSync;
      case SyncStatusModel.conflict:
        return SyncStatus.conflict;
    }
  }
}

extension SyncStatusX on SyncStatus {
  SyncStatusModel toModel() {
    switch (this) {
      case SyncStatus.synced:
        return SyncStatusModel.synced;
      case SyncStatus.pendingSync:
        return SyncStatusModel.pendingSync;
      case SyncStatus.conflict:
        return SyncStatusModel.conflict;
    }
  }
}

@HiveType(typeId: 1)
class NoteModel extends Note {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String title;
  @override
  @HiveField(2)
  final String body;
  @override
  @HiveField(3)
  final int version;
  @HiveField(4)
  final SyncStatusModel syncStatusModel;
  @override
  @HiveField(5)
  final DateTime updatedAt;
  @override
  @HiveField(6)
  final bool isDeleted;

  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.version,
    required this.syncStatusModel,
    required this.updatedAt,
    this.isDeleted = false,
  }) : super(
          id: id,
          title: title,
          body: body,
          version: version,
          syncStatus: syncStatusModel == SyncStatusModel.synced
              ? SyncStatus.synced
              : syncStatusModel == SyncStatusModel.conflict
                  ? SyncStatus.conflict
                  : SyncStatus.pendingSync,
          updatedAt: updatedAt,
          isDeleted: isDeleted,
        );

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      body: note.body,
      version: note.version,
      syncStatusModel: note.syncStatus.toModel(),
      updatedAt: note.updatedAt,
      isDeleted: note.isDeleted,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      version: json['version'] ?? 0,
      syncStatusModel: SyncStatusModel.synced, // Always synced from remote
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      // syncStatus is local only
    };
  }
}
