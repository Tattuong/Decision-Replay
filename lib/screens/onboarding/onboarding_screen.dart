import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_entry.dart';
import '../../providers/notes_provider.dart';
import '../main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await context.read<NotesProvider>().completeOnboarding();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardPageData(
        title: AppStrings.t(context, 'onboardTitle1'),
        desc: AppStrings.t(context, 'onboardDesc1'),
        illustration: const _NotesStackIllustration(),
      ),
      _OnboardPageData(
        title: AppStrings.t(context, 'onboardTitle2'),
        desc: AppStrings.t(context, 'onboardDesc2'),
        illustration: const _FormatsIllustration(),
      ),
      _OnboardPageData(
        title: AppStrings.t(context, 'onboardTitle3'),
        desc: AppStrings.t(context, 'onboardDesc3'),
        illustration: const _ThemesIllustration(),
      ),
    ];

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.accentGradient),
          child: SafeArea(
            child: Column(
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        AppStrings.t(context, 'skip'),
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: pages.length,
                  itemBuilder: (_, i) => _OnboardSlide(page: pages[i]),
                ),
              ),
              _PageDots(count: pages.length, index: _index),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (_index < pages.length - 1) {
                        _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                        return;
                      }
                      _finish();
                    },
                    child: Text(_index < pages.length - 1 ? AppStrings.t(context, 'next') : AppStrings.t(context, 'getStarted')),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String title;
  final String desc;
  final Widget illustration;

  const _OnboardPageData({required this.title, required this.desc, required this.illustration});
}

class _OnboardSlide extends StatelessWidget {
  final _OnboardPageData page;

  const _OnboardSlide({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(child: Center(child: page.illustration)),
          const SizedBox(height: 24),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16, height: 1.55),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;

  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _MiniNote extends StatelessWidget {
  final Color color;
  final String title;
  final List<Widget>? extras;

  const _MiniNote({required this.color, required this.title, this.extras});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          if (extras != null) ...[const SizedBox(height: 10), ...extras!],
        ],
      ),
    );
  }
}

class _NotesStackIllustration extends StatelessWidget {
  const _NotesStackIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: Transform.translate(
              offset: const Offset(-36, 18),
              child: _MiniNote(color: NotePalette.cardColors[1], title: 'Weekend plans'),
            ),
          ),
          Transform.rotate(
            angle: 0.08,
            child: Transform.translate(
              offset: const Offset(34, -10),
              child: _MiniNote(color: NotePalette.cardColors[4], title: 'Book list'),
            ),
          ),
          _MiniNote(
            color: NotePalette.cardColors[5],
            title: 'Meeting notes',
            extras: [
              Container(height: 6, width: 90, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 6),
              Container(height: 6, width: 120, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatsIllustration extends StatelessWidget {
  const _FormatsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _MiniNote(
            color: NotePalette.cardColors[0],
            title: 'Grocery run',
            extras: [
              _checkRow('Milk', true),
              const SizedBox(height: 6),
              _checkRow('Bread', false),
            ],
          ),
          Positioned(
            right: 0,
            top: 24,
            child: _formatBadge(Icons.mic_rounded, AppColors.primary),
          ),
          Positioned(
            left: 0,
            bottom: 20,
            child: _formatBadge(Icons.photo_rounded, AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String text, bool done) {
    return Row(
      children: [
        Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: done ? AppColors.primary : AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, decoration: done ? TextDecoration.lineThrough : null)),
        ),
      ],
    );
  }

  Widget _formatBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ThemesIllustration extends StatelessWidget {
  const _ThemesIllustration();

  @override
  Widget build(BuildContext context) {
    final swatches = NotePalette.cardColors.take(6).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Column(
            children: [
              Row(
                children: swatches
                    .map(
                      (c) => Expanded(
                        child: Container(
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.shopPromoGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.palette_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Themes & Shop', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _labelChip('Work', NotePalette.labelColors[1]),
            _labelChip('Ideas', NotePalette.labelColors[2]),
            _labelChip('Personal', NotePalette.labelColors[4]),
          ],
        ),
      ],
    );
  }

  Widget _labelChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
      child: Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }
}
