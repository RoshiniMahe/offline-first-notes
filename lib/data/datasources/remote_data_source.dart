import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/note_model.dart';

abstract class RemoteDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> createNote(NoteModel note);
  Future<NoteModel> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
}

class RemoteDataSourceImpl implements RemoteDataSource {
  final Dio dio;

  String get _getBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/notes';
    }
    return 'http://localhost:3000/notes';
  }

  RemoteDataSourceImpl(this.dio) {
    dio.options.baseUrl = _getBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  @override
  Future<List<NoteModel>> getNotes() async {
    final response = await dio.get('');
    if (response.statusCode == 200) {
      return (response.data as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  @override
  Future<NoteModel> createNote(NoteModel note) async {
    final response = await dio.post('', data: note.toJson());
    if (response.statusCode == 201 || response.statusCode == 200) {
      return NoteModel.fromJson(response.data);
    } else {
      throw Exception('Failed to create note');
    }
  }

  @override
  Future<NoteModel> updateNote(NoteModel note) async {
    final response = await dio.put('/${note.id}', data: note.toJson());
    if (response.statusCode == 200) {
      return NoteModel.fromJson(response.data);
    } else {
      throw Exception('Failed to update note');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    final response = await dio.delete('/$id');
    if (response.statusCode != 200 &&
        response.statusCode != 204 &&
        response.statusCode != 404) {
      throw Exception('Failed to delete note');
    }
  }
}
