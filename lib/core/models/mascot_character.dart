import 'package:flutter/material.dart';

/// 10 Unique, First-Party 2D Cartoon Learning Companions.
/// Designed in vibrant comic/Duolingo style, unlocked by leveling up.
class MascotCharacter {
  const MascotCharacter({
    required this.id,
    required this.name,
    required this.species,
    required this.title,
    required this.emoji,
    required this.requiredLevel,
    required this.bio,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.bellyColor,
    required this.quotes,
    required this.tags,
  });

  final String id;
  final String name;
  final String species;
  final String title;
  final String emoji;
  final int requiredLevel;
  final String bio;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bellyColor;
  final List<String> quotes;
  final List<String> tags;

  bool isUnlockedForLevel(int playerLevel, {bool adminOverride = false}) {
    if (adminOverride) return true;
    return playerLevel >= requiredLevel;
  }
}

/// The 10 Official Cartoon Characters Roster
abstract final class MascotRoster {
  static const List<MascotCharacter> characters = [
    // 1. Level 1 - Pip the Sage Owl
    MascotCharacter(
      id: 'pip_owl',
      name: 'Pip',
      species: 'Sage Owl',
      title: 'THE SAGE GUARDIAN',
      emoji: '🦉',
      requiredLevel: 1,
      bio: 'Curious, bright, and always keeping your streak alive! The perfect companion to start your adventure.',
      primaryColor: Color(0xFF58CC02),   // Duolingo Emerald Green
      secondaryColor: Color(0xFF46A302), // Forest Green
      accentColor: Color(0xFFF59E0B),    // Amber Gold
      bellyColor: Color(0xFFE8FBE8),     // Mint White
      quotes: [
        'Protect that daily streak! A 5-minute quiz today keeps your mind razor-sharp! 🔥',
        'Did you know? Consistent practice boosts recall by over 40%! 🧠✨',
        'Tap me anytime for good luck and a high-five! I\'m cheering for you! 🦉💚',
        'Every master was once a beginner. Keep leveling up! ⚡',
      ],
      tags: ['Curious', 'Wise', 'Streak Shield'],
    ),

    // 2. Level 2 - Spark the Swift Fox
    MascotCharacter(
      id: 'spark_fox',
      name: 'Spark',
      species: 'Swift Fox',
      title: 'SPEED SPRINTER',
      emoji: '🦊',
      requiredLevel: 2,
      bio: 'Quick-thinking, agile, and always eager to sprint through tough quiz questions and bugs.',
      primaryColor: Color(0xFFFF6B4A),   // Fox Coral Orange
      secondaryColor: Color(0xFFE04522), // Deep Flame
      accentColor: Color(0xFFFBBF24),    // Sun Amber
      bellyColor: Color(0xFFFFF2E8),     // Cream White
      quotes: [
        'Speed is great, but precision wins the boss battle! 🦊💨',
        'Ready to sprint through the next topic map? Let\'s zoom!',
        'No concept is too tricky when your mind is lightning quick! ⚡',
      ],
      tags: ['Agile', 'Speedy', 'XP Booster'],
    ),

    // 3. Level 3 - Barnaby the Logic Bear
    MascotCharacter(
      id: 'barnaby_bear',
      name: 'Barnaby',
      species: 'Gentle Bear',
      title: 'LOGIC ARCHITECT',
      emoji: '🐻',
      requiredLevel: 3,
      bio: 'Patient, sturdy, and methodical. Helps you break complex computer science problems into bite-sized logic.',
      primaryColor: Color(0xFFD97706),   // Warm Honey Caramel
      secondaryColor: Color(0xFFB45309), // Roasted Toffee
      accentColor: Color(0xFF3B82F6),    // Cobalt Blue
      bellyColor: Color(0xFFFEF3C7),     // Butter Cream
      quotes: [
        'Take a deep breath. Build the solution brick by brick! 🐻🍯',
        'Strong foundations withstand any tricky test question.',
        'Patience and persistence always triumph over confusion.',
      ],
      tags: ['Patient', 'Sturdy', 'Deep Logic'],
    ),

    // 4. Level 5 - Finley the Bug Hunter Frog
    MascotCharacter(
      id: 'finley_frog',
      name: 'Finley',
      species: 'Tree Frog',
      title: 'BUG HUNTER',
      emoji: '🐸',
      requiredLevel: 5,
      bio: 'Sharp-eyed and bouncy. Can spot a syntax bug or logical edge-case from a mile away!',
      primaryColor: Color(0xFF84CC16),   // Bright Lime
      secondaryColor: Color(0xFF65A30D), // Moss Green
      accentColor: Color(0xFF6366F1),    // Indigo
      bellyColor: Color(0xFFECFCCB),     // Pale Lime
      quotes: [
        'Ribbit! I just caught a sneaky logic bug right in front of us! 🐸🎯',
        'Hop right into your next lesson without fear!',
        'Every mistake is just a bug ready to be debugged!',
      ],
      tags: ['Observant', 'Debugger', 'Bug Hunter'],
    ),

    // 5. Level 7 - Milo the Code Monkey
    MascotCharacter(
      id: 'milo_monkey',
      name: 'Milo',
      species: 'Clever Monkey',
      title: 'ALGORITHM TINKERER',
      emoji: '🐵',
      requiredLevel: 7,
      bio: 'Playful and endlessly inventive. Loves tinkering with data structures and exploring multiple solutions.',
      primaryColor: Color(0xFF92400E),   // Cinnamon Cocoa
      secondaryColor: Color(0xFF78350F), // Dark Cocoa
      accentColor: Color(0xFFFACC15),    // Banana Yellow
      bellyColor: Color(0xFFFFEDD5),     // Warm Peach
      quotes: [
        'Let\'s monkey around with some clever algorithms today! 🐵🍌',
        'Why solve it one way when you can discover three new ways?',
        'High-five! Your coding instincts are getting super sharp!',
      ],
      tags: ['Playful', 'Creative', 'Algorithm Tinkerer'],
    ),

    // 6. Level 9 - Luna the Shadow Lynx
    MascotCharacter(
      id: 'luna_lynx',
      name: 'Luna',
      species: 'Cyber Lynx',
      title: 'SHADOW CODER',
      emoji: '🐱',
      requiredLevel: 9,
      bio: 'Silent, calm, and laser-focused. Pounces gracefully onto difficult algorithmic challenges with zero hesitation.',
      primaryColor: Color(0xFF8B5CF6),   // Vivid Purple
      secondaryColor: Color(0xFF6D28D9), // Dark Violet
      accentColor: Color(0xFF06B6D4),    // Electric Cyan
      bellyColor: Color(0xFFEDE9FE),     // Soft Lavender
      quotes: [
        'Quiet focus yields the cleanest code. Stay in the zone! 🐱✨',
        'Sharp eyes, clear thoughts, zero syntax errors.',
        'Pounce gracefully on the next challenge like a true lynx.',
      ],
      tags: ['Stealthy', 'Focused', 'Laser Precision'],
    ),

    // 7. Level 12 - Pippin the Chill Penguin
    MascotCharacter(
      id: 'pippin_penguin',
      name: 'Pippin',
      species: 'Cool Penguin',
      title: 'ICE DEBUGGER',
      emoji: '🐧',
      requiredLevel: 12,
      bio: 'Ice-cold composure in the heat of battle. Never sweats a timed quiz or tricky system architecture question.',
      primaryColor: Color(0xFF0284C7),   // Sky Ocean Blue
      secondaryColor: Color(0xFF0369A1), // Deep Navy
      accentColor: Color(0xFFFB923C),    // Bright Tangerine
      bellyColor: Color(0xFFF0F9FF),     // Pure Ice White
      quotes: [
        'Keep calm and debug gracefully. Ice cold logic wins! 🐧❄️',
        'When the pressure rises, just slide smoothly past the obstacles.',
        'Cool heads write elegant software!',
      ],
      tags: ['Composed', 'Chill', 'Pressure Proof'],
    ),

    // 8. Level 15 - Toby the Tech Turtle
    MascotCharacter(
      id: 'toby_turtle',
      name: 'Toby',
      species: 'Armored Turtle',
      title: 'SHIELD ARCHITECT',
      emoji: '🐢',
      requiredLevel: 15,
      bio: 'Unshakable defense and legendary wisdom. Teaches that slow and steady systematic mastery outlasts rushed cramming.',
      primaryColor: Color(0xFF059669),   // Emerald Jade
      secondaryColor: Color(0xFF047857), // Forest Jade
      accentColor: Color(0xFF3B82F6),    // Electric Blue
      bellyColor: Color(0xFFD1FAE5),     // Mint Jade
      quotes: [
        'Slow and steady conquers the entire syllabus! 🐢🛡️',
        'An impenetrable defense begins with deep conceptual understanding.',
        'Never rush perfection. You are building mastery that lasts a lifetime.',
      ],
      tags: ['Resilient', 'Wise', 'Master Architect'],
    ),

    // 9. Level 18 - Blaze the Phoenix Dragon
    MascotCharacter(
      id: 'blaze_dragon',
      name: 'Blaze',
      species: 'Mythic Dragon',
      title: 'INFERNO CHAMPION',
      emoji: '🐲',
      requiredLevel: 18,
      bio: 'Breathes unstoppable passion into your study sessions. Forged in high-level quizzes and champions arena victories.',
      primaryColor: Color(0xFFDC2626),   // Crimson Flame
      secondaryColor: Color(0xFFB91C1C), // Deep Crimson
      accentColor: Color(0xFFFBBF24),    // Golden Spark
      bellyColor: Color(0xFFFEF2F2),     // Rose Cream
      quotes: [
        'Ignite your true potential! Breathe fire into your quizzes! 🐲🔥',
        'Champions aren\'t born in comfort; they are forged in persistence!',
        'Your learning streak burns brighter than a thousand stars!',
      ],
      tags: ['Legendary', 'Fiery', 'Arena Champion'],
    ),

    // 10. Level 20 - Astra the Cosmic Griffin
    MascotCharacter(
      id: 'astra_griffin',
      name: 'Astra',
      species: 'Cosmic Griffin',
      title: 'CELESTIAL SOVEREIGN',
      emoji: '🦅',
      requiredLevel: 20,
      bio: 'The pinnacle of knowledge. A celestial entity of pure intellect that soars across all worlds and masteries.',
      primaryColor: Color(0xFF6366F1),   // Cosmic Indigo
      secondaryColor: Color(0xFF4338CA), // Deep Stellar
      accentColor: Color(0xFFFACC15),    // Star Gold
      bellyColor: Color(0xFFEEF2FF),     // Stellar Starlight
      quotes: [
        'The universe of knowledge is infinite — and you have conquered its highest peaks! 🦅✨',
        'You have achieved true mastery across all realms.',
        'Soar boldly among the greatest legends of GameLearn AI!',
      ],
      tags: ['Transcendent', 'Sovereign', 'Cosmic Intellect'],
    ),
  ];

  static MascotCharacter findById(String? id) {
    if (id == null || id.isEmpty) return characters.first;
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return characters.first;
  }
}

/// Accessories that can be equipped onto any cartoon mascot
enum MascotAccessory {
  none(id: 'none', label: 'None', emoji: '✖️'),
  crown(id: 'crown', label: 'Royal Crown', emoji: '👑'),
  wizardHat(id: 'wizard', label: 'Wizard Hat', emoji: '🧙'),
  goggles(id: 'goggles', label: 'Tech Goggles', emoji: '🥽'),
  halo(id: 'halo', label: 'Golden Halo', emoji: '💫'),
  cape(id: 'cape', label: 'Super Cape', emoji: '🦸'),
  flower(id: 'flower', label: 'Sakura Bloom', emoji: '🌸'),
  headphones(id: 'headphones', label: 'DJ Headphones', emoji: '🎧');

  const MascotAccessory({required this.id, required this.label, required this.emoji});

  final String id;
  final String label;
  final String emoji;

  static MascotAccessory fromId(String? id) {
    if (id == null) return MascotAccessory.none;
    for (final a in MascotAccessory.values) {
      if (a.id == id) return a;
    }
    return MascotAccessory.none;
  }
}

/// Dynamic Moods / Animation states
enum MascotMood {
  idle,
  celebrating,
  thinking,
  waving,
  focused;

  String get label => switch (this) {
        idle => 'Idle Float',
        celebrating => 'Victory Jump',
        thinking => 'Thinking',
        waving => 'Waving',
        focused => 'Deep Focus',
      };

  String get emoji => switch (this) {
        idle => '✨',
        celebrating => '🎉',
        thinking => '🤔',
        waving => '👋',
        focused => '🎯',
      };
}
