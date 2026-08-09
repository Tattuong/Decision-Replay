import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_purchase_sheet.dart';
import '../../widgets/dr_design.dart';
import 'create_note_sheet.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const NotesScreen({super.key, this.onSearchTap});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final notesProv = context.watch<NotesProvider>();
    final notes = (_filter == 'pinned'
            ? notesProv.filtered(pinnedOnly: true)
            : notesProv.filtered(labelId: _filter == 'all' ? null : _filter))
      ..sort((a, b) {
        if (_filter != 'pinned' && a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return DrScaffold(
      extendBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: DrNotesHeader(
              title: AppStrings.t(context, 'yourNotes'),
              onSearch: widget.onSearchTap,
              trailing: CoinBalanceChip(
                variant: CoinChipVariant.header,
                onTap: () => CoinPurchaseSheet.show(context),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          DrFilterChip(
                            label: AppStrings.t(context, 'allNotes'),
                            selected: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          DrFilterChip(
                            label: AppStrings.t(context, 'pinnedFilter'),
                            selected: _filter == 'pinned',
                            onTap: () => setState(() => _filter = 'pinned'),
                          ),
                          ...notesProv.labels.map(
                            (l) => DrFilterChip(
                              label: l.name,
                              selected: _filter == l.id,
                              onTap: () => setState(() => _filter = l.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (notes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: DrEmptyState(
                      icon: _filter == 'pinned' ? Icons.push_pin_outlined : Icons.edit_note_rounded,
                      message: AppStrings.t(context, _filter == 'pinned' ? 'noPinnedNotes' : 'emptyNotes'),
                      action: AppStrings.t(context, 'createNew'),
                      onAction: () => CreateNoteSheet.show(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                    sliver: SliverToBoxAdapter(
                      child: DrMasonryGrid(
                        spacing: 12,
                        children: [
                          for (final note in notes)
                            DrNoteCard(
                              note: note,
                              label: notesProv.labelFor(note.labelId),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
