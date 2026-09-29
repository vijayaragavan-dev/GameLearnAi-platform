import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_manager.dart';
import '../../../core/models/mascot_character.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/brutal_widgets.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/active_mascot_provider.dart';
import '../widgets/cartoon_mascot_view.dart';

/// Admin & Character Studio Screen:
/// - Showcase all 10 first-party 2D cartoon learning companions
/// - Modify active character, accessories, and rich animation moods
/// - Level-up unlocks (Level 1 to 20)
/// - Admin master toggle to unlock all characters for testing
class AdminCharacterStudioScreen extends ConsumerStatefulWidget {
  const AdminCharacterStudioScreen({super.key});

  @override
  ConsumerState<AdminCharacterStudioScreen> createState() => _AdminCharacterStudioScreenState();
}

class _AdminCharacterStudioScreenState extends ConsumerState<AdminCharacterStudioScreen> {
  late MascotCharacter _previewCharacter;
  late MascotAccessory _previewAccessory;
  MascotMood _previewMood = MascotMood.idle;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    final active = ref.read(activeMascotProvider);
    _previewCharacter = active.character;
    _previewAccessory = active.accessory;
    _previewMood = active.mood;
  }

  void _onTapMascot() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _previewCharacter.quotes.length;
      _previewMood = MascotMood.celebrating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeState = ref.watch(activeMascotProvider);
    final dashState = ref.watch(dashboardProvider);
    final int realLevel = dashState.data?.gamification.currentLevel ?? 1;

    // Effective level (real or simulated via admin override)
    final int effectiveLevel = activeState.adminLevelOverride ?? realLevel;
    final bool adminUnlock = activeState.adminUnlockAll;

    final isEquipped = activeState.character.id == _previewCharacter.id &&
        activeState.accessory == _previewAccessory;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131720) : const Color(0xFFF7F5EF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131720) : const Color(0xFFF7F5EF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : NeoBrutalColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CHARACTER STUDIO',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isDark ? Colors.white : NeoBrutalColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: NeoBrutalColors.lemonYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NeoBrutalColors.ink, width: 1.8),
                boxShadow: NeoBrutalShadows.hardXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'LVL $effectiveLevel',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            children: [
              ResponsiveCenter(
                maxWidth: 720,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. INTERACTIVE LIVE MASCOT PREVIEW STAGE ──
                    _buildLiveStage(isDark, isEquipped, effectiveLevel, adminUnlock),
                    const SizedBox(height: 16),

                    // ── 3. ACCESSORY CUSTOMIZER BAR ──
                    _buildAccessoryBar(isDark),
                    const SizedBox(height: 16),

                    // ── 4. ANIMATION MOOD SELECTOR ──
                    _buildMoodSelector(isDark),
                    const SizedBox(height: 20),

                    // ── 5. 10-CHARACTER ROSTER CATALOG ──
                    Text(
                      '10 CARTOON COMPANIONS (UNLOCK BY LEVELING UP)',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white70 : NeoBrutalColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRosterGrid(isDark, effectiveLevel, adminUnlock, activeState.character.id),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStage(bool isDark, bool isEquipped, int effectiveLevel, bool adminUnlock) {
    final isUnlocked = _previewCharacter.isUnlockedForLevel(effectiveLevel, adminOverride: adminUnlock);
    final quote = _previewCharacter.quotes[_quoteIndex % _previewCharacter.quotes.length];

    return BrutalCard(
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_previewCharacter.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewCharacter.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : NeoBrutalColors.ink,
                        ),
                      ),
                      Text(
                        '${_previewCharacter.species} • ${_previewCharacter.title}',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? const Color(0xFF93C5FD) : NeoBrutalColors.cobaltBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isUnlocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626), width: 1.5),
                ),
                child: Text(
                  isUnlocked ? 'UNLOCKED' : 'REQ LVL ${_previewCharacter.requiredLevel}',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Mascot Stage
          Center(
            child: CartoonMascotView(
              character: _previewCharacter,
              accessory: _previewAccessory,
              mood: _previewMood,
              size: 132,
              onTap: _onTapMascot,
            ),
          ),
          const SizedBox(height: 10),

          // Speech Bubble
          GestureDetector(
            onTap: _onTapMascot,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF283040) : NeoBrutalColors.pastelBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$quote"',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark ? Colors.white : NeoBrutalColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Equip Button
          BrutalButton(
            text: isEquipped
                ? 'CURRENTLY EQUIPPED'
                : (isUnlocked ? 'EQUIP AS MY MAIN COMPANION' : 'LOCKED (LEVEL ${_previewCharacter.requiredLevel} REQUIRED)'),
            icon: isEquipped ? Icons.check_circle_rounded : (isUnlocked ? Icons.stars_rounded : Icons.lock_rounded),
            backgroundColor: isEquipped
                ? const Color(0xFF10B981)
                : (isUnlocked ? NeoBrutalColors.lemonYellow : Colors.grey.shade400),
            textColor: isEquipped ? Colors.white : NeoBrutalColors.ink,
            onPressed: isUnlocked
                ? () {
                    ref.read(audioManagerProvider).play(Sfx.achievementUnlock);
                    ref.read(activeMascotProvider.notifier).selectCharacter(_previewCharacter.id);
                    ref.read(activeMascotProvider.notifier).setAccessory(_previewAccessory);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Equipped ${_previewCharacter.name} as your companion!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryBar(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCESSORY CUSTOMIZATION',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isDark ? Colors.white70 : NeoBrutalColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MascotAccessory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final acc = MascotAccessory.values[i];
              final isSelected = acc == _previewAccessory;
              return GestureDetector(
                onTap: () {
                  ref.read(audioManagerProvider).play(Sfx.buttonTap);
                  setState(() => _previewAccessory = acc);
                  ref.read(activeMascotProvider.notifier).setAccessory(acc);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6) : (isDark ? const Color(0xFF1E2430) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                    boxShadow: isSelected ? NeoBrutalShadows.hardSm : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(acc.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        acc.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : NeoBrutalColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANIMATION & MOOD POSE',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isDark ? Colors.white70 : NeoBrutalColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MascotMood.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final mood = MascotMood.values[i];
              final isSelected = mood == _previewMood;
              return GestureDetector(
                onTap: () {
                  ref.read(audioManagerProvider).play(Sfx.buttonTap);
                  setState(() => _previewMood = mood);
                  ref.read(activeMascotProvider.notifier).setMood(mood);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF1E2430) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                    boxShadow: isSelected ? NeoBrutalShadows.hardSm : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        mood.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : NeoBrutalColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRosterGrid(bool isDark, int effectiveLevel, bool adminUnlock, String activeId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: MascotRoster.characters.length,
      itemBuilder: (context, i) {
        final char = MascotRoster.characters[i];
        final isUnlocked = char.isUnlockedForLevel(effectiveLevel, adminOverride: adminUnlock);
        final isSelected = char.id == _previewCharacter.id;
        final isEquipped = char.id == activeId;

        return GestureDetector(
          onTap: () {
            ref.read(audioManagerProvider).play(Sfx.buttonTap);
            setState(() {
              _previewCharacter = char;
              _quoteIndex = 0;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF283040) : const Color(0xFFEFF6FF))
                  : (isDark ? const Color(0xFF1E2430) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : NeoBrutalColors.ink,
                width: isSelected ? 3.0 : 2.0,
              ),
              boxShadow: isSelected ? NeoBrutalShadows.hard : NeoBrutalShadows.hardSm,
            ),
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mini avatar
                    Expanded(
                      child: Center(
                        child: CartoonMascotView(
                          character: char,
                          accessory: isSelected ? _previewAccessory : MascotAccessory.none,
                          size: 72,
                          isAnimated: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      char.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : NeoBrutalColors.ink,
                      ),
                    ),
                    Text(
                      char.species,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : NeoBrutalColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUnlocked ? const Color(0xFFE8FBE8) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: NeoBrutalColors.ink, width: 1.0),
                          ),
                          child: Text(
                            'LVL ${char.requiredLevel}',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked ? const Color(0xFF166534) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (isEquipped)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NeoBrutalColors.ink, width: 1.0),
                            ),
                            child: const Text(
                              'EQUIPPED',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NeoBrutalColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'LVL ${char.requiredLevel}',
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
