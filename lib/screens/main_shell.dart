import 'package:flutter/material.dart';

import 'notes/create_note_sheet.dart';
import 'notes/notes_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/ad_banner_slot.dart';
import '../../widgets/dr_design.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      floatingActionButton: _index == 0 ? DrFab(onPressed: () => CreateNoteSheet.show(context)) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: IndexedStack(
        index: _index,
        children: [
          NotesScreen(onSearchTap: () => setState(() => _index = 2)),
          const TasksScreen(),
          const SearchScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerSlot(),
          DrBottomNav(
            index: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}
