import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note.dart';
import '../blocs/note_bloc.dart';
import '../blocs/sync_bloc.dart';
import '../widgets/note_card.dart';
import 'add_edit_note_screen.dart';
import 'conflict_resolution_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NoteBloc>().add(LoadNotes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Offline-first sync', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              context.read<SyncBloc>().add(SyncStarted());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              bool isOnline = true;
              bool isSyncing = false;
              if (state is SyncStatusState) {
                isOnline = state.isOnline;
                isSyncing = state.isSyncing;
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: isOnline ? Colors.green : Colors.red,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSyncing)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? (isSyncing ? 'Syncing...' : 'Online') : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: BlocConsumer<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NoteLoaded) {
            final conflicts = state.notes.where((n) => n.syncStatus == SyncStatus.conflict).toList();
            if (conflicts.isNotEmpty) {
              // Open conflict resolution for the first conflict
              _showConflictResolution(context, conflicts.first);
            }
          }
        },
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NoteLoaded) {
            final notes = state.notes;
            if (notes.isEmpty) {
              return const Center(child: Text('No notes yet. Create one!'));
            }
            return ListView.builder(
              itemCount: notes.length,
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteCard(
                  note: note,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditNoteScreen(note: note),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is NoteError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditNoteScreen(),
            ),
          );
        },
        label: const Text('New Note'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showConflictResolution(BuildContext context, Note conflictingNote) {
    // Only show if not already showing (simple workaround: check current route)
    // For a real app, this needs a better queue mechanism.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConflictResolutionScreen(note: conflictingNote),
        fullscreenDialog: true,
      ),
    );
  }
}
