import 'package:flutter/material.dart';
import '../../../features/gamification/services/xp_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Slides down from top and fades out after 2.5 seconds.
void showXPToast(BuildContext context, XPResult result) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _XPToastWidget(
      result: result,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2500), () {
    if (entry.mounted) entry.remove();
  });
}

class _XPToastWidget extends StatefulWidget {
  final XPResult result;
  final VoidCallback onDismiss;

  const _XPToastWidget({required this.result, required this.onDismiss});

  @override
  State<_XPToastWidget> createState() => _XPToastWidgetState();
}

class _XPToastWidgetState extends State<_XPToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();

    // Fade out at end
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: r.leveledUp ? AppColors.primary : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (r.leveledUp ? AppColors.primary : Colors.black)
                        .withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(r.leveledUp ? '🎉' : '⭐',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.leveledUp
                              ? 'Level Up! ${r.newLevelTitle}'
                              : '+${r.xpGained} XP',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800),
                        ),
                        if (r.leveledUp)
                          Text('+${r.xpGained} XP',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
