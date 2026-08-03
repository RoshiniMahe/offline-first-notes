// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 1;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      version: fields[3] as int,
      syncStatusModel: fields[4] as SyncStatusModel,
      updatedAt: fields[5] as DateTime,
      isDeleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.syncStatusModel)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusModelAdapter extends TypeAdapter<SyncStatusModel> {
  @override
  final int typeId = 0;

  @override
  SyncStatusModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatusModel.synced;
      case 1:
        return SyncStatusModel.pendingSync;
      case 2:
        return SyncStatusModel.conflict;
      default:
        return SyncStatusModel.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatusModel obj) {
    switch (obj) {
      case SyncStatusModel.synced:
        writer.writeByte(0);
        break;
      case SyncStatusModel.pendingSync:
        writer.writeByte(1);
        break;
      case SyncStatusModel.conflict:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
