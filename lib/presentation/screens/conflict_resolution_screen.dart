import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/note.dart';
import '../../data/models/note_model.dart';
import '../blocs/note_bloc.dart';

class ConflictResolutionScreen extends StatelessWidget {

  final Note note; // The local conflicting note. Need to fetch the remote note, but we only have local in state.
  // Wait, the repository marked it as conflict because it saw a newer version on server.
  // To show "My Changes" vs "Server Version", we need both.
  // The L_v was updated to S_v locally when conflict happened? No, we kept L_v.
  // For this assignment, let's assume `note` is local, and we fetch server version directly here,
  // or the repository could have saved both. Since we didn't save both, we will fetch the server note by ID here.

  const ConflictResolutionScreen({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resolve Conflict', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
            Text('Choose version to keep', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Note>(
        // Ideally we should have a usecase to fetch remote note by ID.
        // For simplicity, we just use the API directly via dependency injection or a specific usecase.
        // Let's create a quick function or inject a remote fetcher.
        // Actually, since I didn't add a GetRemoteNote usecase, I can just use a fake remote note for UI preview
        // or add the usecase quickly.
        future: _fetchRemoteNote(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load server version.'));
          }

          final serverNote = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Conflict Detected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                            Text('Edited locally and on server. Select which version to keep.', style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildVersionCard(
                  title: 'My Changes',
                  subtitle: 'v${note.version} • Local',
                  note: note,
                  isSelected: true,
                ),
                
                const SizedBox(height: 16),
                
                _buildVersionCard(
                  title: 'Server Version',
                  subtitle: 'v${serverNote.version} • Remote',
                  note: serverNote,
                  isSelected: false,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: () {
                    // Keep my changes (we increment local version so it overrides server)
                    final resolvedNote = note.copyWith(version: serverNote.version + 1);
                    context.read<NoteBloc>().add(ResolveNoteConflict(resolvedNote));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Keep My Changes'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Keep server version
                    final resolvedNote = serverNote;
                    context.read<NoteBloc>().add(ResolveNoteConflict(resolvedNote));
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                  child: const Text('Keep Server Version'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Merge both
                    final resolvedNote = note.copyWith(
                      version: serverNote.version + 1,
                      body: '${note.body}\n\n--- Server Appended ---\n\n${serverNote.body}',
                    );
                    context.read<NoteBloc>().add(ResolveNoteConflict(resolvedNote));
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Merge Both Versions'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionCard({required String title, required String subtitle, required Note note, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.deepPurple : Colors.green)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(note.body, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<Note> _fetchRemoteNote(BuildContext context) async {
    final dio = GetIt.instance<Dio>();
    final response = await dio.get('/${note.id}');
    if (response.statusCode == 200) {
      return NoteModel.fromJson(response.data);
    } else {
      throw Exception('Failed');
    }
  }
}
