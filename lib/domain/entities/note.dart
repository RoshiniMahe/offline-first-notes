import 'package:equatable/equatable.dart';

enum SyncStatus { synced, pendingSync, conflict }

class Note extends Equatable {
  final String id;
  final String title;
  final String body;
  final int version;
  final SyncStatus syncStatus;
  final DateTime updatedAt;
  final bool isDeleted;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.version,
    required this.syncStatus,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    int? version,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        version,
        syncStatus,
        updatedAt,
        isDeleted,
      ];
}
