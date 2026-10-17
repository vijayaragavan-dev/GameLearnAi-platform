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
    this.imageAsset,
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
  final String? imageAsset;

  bool isUnlockedForLevel(int playerLevel, {bool adminOverride = false}) {
    if (adminOverride) return true;
    return playerLevel >= requiredLevel;
  }

  List<String> get sadQuotes => switch (id) {
        'bao_panda' => [
            'Take a deep breath... even the strongest bamboo bends in the storm. We\'ll rebuild next time! 🎋💧',
            'Rest your mind for a second. With patience and focus, you will master this! 🐼',
            'Mistakes are just raw stones waiting to be polished into gems! Keep going! 🌱',
          ],
        'spark_fox' => [
            'Oof, slippery track! Dust off your paws, we sprint again right away! 🦊💨',
            'Even the quickest foxes miss a turn! Keep that spark alive and try again! ⚡',
            'Don\'t lose speed in your heart! Every retry makes you 10x faster! 🔥',
          ],
        'pip_owl' => [
            'A temporary bump, young scholar! Every great thinker failed before solving the puzzle. 🦉💙',
            'Don\'t be discouraged! Review the tricky concepts and let\'s take flight again! 📚',
            'Wisdom isn\'t never failing—it\'s rising every single time you fall! ✨',
          ],
        'milo_cat' => [
            'Aww whiskers... that was tough! But an explorer never gives up an expedition! 🐱🐾',
            'Cats always land on their feet! Shake it off and let\'s pounce back in! 🧶',
            'No worries at all! Exploring means testing boundaries! Let\'s go again! 🐾',
          ],
        'pippin_penguin' => [
            'Brrr, chilly score! But penguins thrive in blizzards! 🐧❄️',
            'A little slip on the ice! Recalibrate the trajectory and slide back in! ⛸️',
            'Let\'s review the formula together—mastery is just one attempt away! 🧪',
          ],
        'nova_bot' => [
            'Suboptimal run detected... but self-calibration is already underway! 🤖🛠️',
            'Defeat routine bypassed! Processing fresh neural learning models... ⚡',
            'Every error is priceless debugging data! Let\'s reboot and retry! 🔋',
          ],
        'blaze_dragon' => [
            'The flame flickered, but it will NEVER extinguish! Reignite your fire! 🐉🔥',
            'A true dragon draws strength from battle! Rise and conquer! ⚔️',
            'Roar past this obstacle! Your inner intellect is invincible! 🌋',
          ],
        _ => [
            'Don\'t give up! Every mistake is a step toward true mastery! 💧',
            'Take a breath, reset, and let\'s try again together! You\'ve got this! 💙',
          ],
      };

  List<String> get moderateQuotes => switch (id) {
        'bao_panda' => [
            'Good balance! Your foundation is growing stronger with every quiz! 🎋✨',
            'Solid architecture! A few fine polishes and you\'ll hit 100%! 🐼',
            'Patience and persistence turn stone into jade. Keep your rhythm! 🌱',
          ],
        'spark_fox' => [
            'Great sprint! You\'re zooming closer and closer to top speed! 🦊⚡',
            'Super quick reflexes! Just a tiny dash left to complete perfection! 💨',
            'The momentum is electric! Let\'s sprint into the next rank! 🔥',
          ],
        'pip_owl' => [
            'Commendable effort, scholar! Your intellect deepens with each test! 🦉💡',
            'More than halfway to absolute perfection! Maintain this scholarly focus! 📖',
            'A keen mind in the making! Let\'s master the final details together! 🌟',
          ],
        'milo_cat' => [
            'Pawsome progress! You\'re getting super agile with these concepts! 🐱🐾',
            'You tracked down the answers like a real hunter! Almost at the summit! 🧶',
            'That\'s the adventurous spirit! The golden trophy is right within reach! 🗺️',
          ],
        'pippin_penguin' => [
            'Smooth sliding! You navigated through those tricky icy questions! 🐧❄️',
            'Scientific method in action! Solid hypothesis and good accuracy! 🧪',
            'Waddle forward with confidence! Peak mastery is right in sight! ⛸️',
          ],
        'nova_bot' => [
            'Accuracy exceeding baseline! Processing capacity expanding rapidly! 🤖⚡',
            'High bandwidth performance! Fine-tuning logic gates for 100%! 🔋',
            'Neural network upgraded! You are well on the road to mastery! 🛰️',
          ],
        'blaze_dragon' => [
            'The flame grows fiercer! You\'re forging real power here! 🐉🔥',
            'A mighty demonstration! Just a little more heat to melt away the doubts! ⚔️',
            'Your wings are spreading! Soar higher and conquer the summit! 🌋',
          ],
        _ => [
            'Solid work! You\'re so close to total mastery! Keep pushing! ⚡',
            'Great momentum! Review those few questions and you\'ll crush 100%! 🚀',
          ],
      };

  List<String> get victoryQuotes => switch (id) {
        'bao_panda' => [
            'SPECTACULAR! Pure architectural mastery! You make it look so effortless! 🐼🏆🎋',
            'Incredible focus and balance! You are a true master of this world! 🌟🎋',
            'Magnificent! Your knowledge is indestructible and rock solid! 💚',
          ],
        'spark_fox' => [
            'LIGHTNING FAST & FLAWLESS! You completely obliterated that challenge! 🦊⚡🏆',
            'Unstoppable speed! You zoomed through like a brilliant shooting star! 💨🔥',
            'PURE GENIUS! That was the smoothest sprint I\'ve ever seen! 🥇',
          ],
        'pip_owl' => [
            'SCHOLAR SUPREME! A display of peerless intellect and dedication! 🦉✨👑',
            'Astounding! You soared to the highest peak of knowledge today! 📜🌟',
            'The cosmos aligns for your triumph! An absolute masterclass! 🧠💎',
          ],
        'milo_cat' => [
            'PURR-FECT SCORE! You conquered this territory like an absolute legend! 🐱👑🐾',
            'MEOW-GICAL! That was brilliantly sharp, explorer! High-paws! 🐾🎉',
            'Top of the mountain! You discovered every secret effortlessly! 🗺️🏆',
          ],
        'pippin_penguin' => [
            'ABSOLUTE ZERO FAULTS! A scientific breakthrough of pure brilliance! 🐧🏆❄️',
            'Flawless glide from start to finish! Top marks in all metrics, professor! 🎓✨',
            'Nobel-worthy performance! You completely aced the test! 🧪🥇',
          ],
        'nova_bot' => [
            'SYSTEM PERFECTION ACHIEVED! Neural score: MAXIMUM LEGENDARY! 🤖🚀💎',
            'Overclocked to 100%! Flawless logic matrix, human master! ⚡👑',
            'Mission Accomplished with 100% precision! Victory protocol initiated! 🎉🔋',
          ],
        'blaze_dragon' => [
            'AN INFERNO OF GLORY! You scorched the challenge and conquered the peak! 🐉🔥👑',
            'ROARING TRIUMPH! Your knowledge burns brighter than a thousand suns! 🌋🏆',
            'ALL HAIL THE CHAMPION! A legendary victory carved in dragon fire! ⚔️🌟',
          ],
        _ => [
            'AMAZING! Outstanding performance! You\'re an absolute genius! 🎉🏆',
            'FLAWLESS VICTORY! Take a bow, champion! 🌟✨',
          ],
      };
}

/// The 10 Official Cartoon Characters Roster
abstract final class MascotRoster {
  static const List<MascotCharacter> characters = [
    // 1. Level 1 - Pip the Scholar Owl
    MascotCharacter(
      id: 'pip_owl',
      name: 'Pip',
      species: 'Scholar Owl',
      title: 'THE SAGE GUARDIAN',
      emoji: '🦉',
      requiredLevel: 1,
      bio: 'Curious, bright, and always keeping your streak alive! The perfect scholar companion to start your adventure.',
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
      imageAsset: 'assets/images/mascot_owl.png',
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
      imageAsset: 'assets/images/sparky_login.png',
    ),

    // 3. Level 3 - Bao the Bamboo Panda
    MascotCharacter(
      id: 'bao_panda',
      name: 'Bao',
      species: 'Zen Panda',
      title: 'BAMBOO ARCHITECT',
      emoji: '🐼',
      requiredLevel: 3,
      bio: 'Calm, lovable, and deeply focused. Teaches that strong architecture and patience make code indestructible.',
      primaryColor: Color(0xFF10B981),   // Emerald Green
      secondaryColor: Color(0xFF059669), // Forest Green
      accentColor: Color(0xFFFBBF24),    // Sun Amber
      bellyColor: Color(0xFFF0FDF4),     // Mint Cream
      quotes: [
        'Take a calm breath. Every complex system is built one clean class at a time! 🐼🎋',
        'Balance and mindfulness make bug-free software!',
        'High-five! Keep your learning momentum rolling!',
      ],
      tags: ['Calm', 'Mindful', 'Code Balance'],
      imageAsset: 'assets/images/mascot_panda.png',
    ),

    // 4. Level 5 - Milo the Explorer Cat
    MascotCharacter(
      id: 'milo_cat',
      name: 'Milo',
      species: 'Explorer Cat',
      title: 'PATHFINDER VOYAGER',
      emoji: '🐱',
      requiredLevel: 5,
      bio: 'Curious adventurer with a compass and safari hat. Always ready to chart unknown curriculum paths and discover secret easter eggs.',
      primaryColor: Color(0xFFF97316),   // Warm Explorer Orange
      secondaryColor: Color(0xFFEA580C), // Deep Rust
      accentColor: Color(0xFF3B82F6),    // Cobalt Blue
      bellyColor: Color(0xFFFFF7ED),     // Warm Peach
      quotes: [
        'Adventure awaits around every semicolon! Follow the path! 🧭🗺️',
        'Curiosity is the greatest superpower of any programmer!',
        'Let\'s chart new territory in today\'s coding expedition!',
      ],
      tags: ['Adventurous', 'Curious', 'Pathfinder'],
      imageAsset: 'assets/images/mascot_cat.png',
    ),

    // 5. Level 7 - Professor Pippin the Penguin
    MascotCharacter(
      id: 'pippin_penguin',
      name: 'Pippin',
      species: 'Professor Penguin',
      title: 'ACADEMIC DEAN',
      emoji: '🐧',
      requiredLevel: 7,
      bio: 'Wise professor with a graduation cap and pointer. Keeps your theoretical foundations rock-solid and test scores at 100%.',
      primaryColor: Color(0xFF0284C7),   // Sky Ocean Blue
      secondaryColor: Color(0xFF0369A1), // Deep Navy
      accentColor: Color(0xFFFBBF24),    // Golden Tassel
      bellyColor: Color(0xFFF0F9FF),     // Pure Ice White
      quotes: [
        'Class is in session! Conceptual mastery is your golden key! 🐧🎓',
        'Always test your edge cases before deploying to production!',
        'Excellence is not an accident; it is the habit of daily learning!',
      ],
      tags: ['Scholarly', 'Wise', 'Quiz Master'],
      imageAsset: 'assets/images/mascot_penguin.png',
    ),

    // 6. Level 9 - Nova the AI Game Bot
    MascotCharacter(
      id: 'nova_bot',
      name: 'Nova',
      species: 'AI Game Bot',
      title: 'CYBER COMPANION',
      emoji: '🤖',
      requiredLevel: 9,
      bio: 'Futuristic robotic buddy with an interactive controller screen. Powers up your gaming agility and rapid problem-solving.',
      primaryColor: Color(0xFF3B82F6),   // Vivid Tech Blue
      secondaryColor: Color(0xFF1D4ED8), // Deep Blue
      accentColor: Color(0xFF06B6D4),    // Cyan Neon
      bellyColor: Color(0xFFEFF6FF),     // Electric White
      quotes: [
        'Beep boop! Neural pathways optimized! Ready for the next mission! 🤖🎮',
        'Algorithms activated! Let\'s compute the optimal solution!',
        'You and I make an unstoppable pair! Game on!',
      ],
      tags: ['Cyber', 'AI Tutor', 'Game Agility'],
      imageAsset: 'assets/images/mascot_robot.png',
    ),

    // 7. Level 12 - Blaze the Phoenix Dragon
    MascotCharacter(
      id: 'blaze_dragon',
      name: 'Blaze',
      species: 'Mythic Dragon',
      title: 'INFERNO CHAMPION',
      emoji: '🐲',
      requiredLevel: 12,
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
      imageAsset: 'assets/images/mascot_dragon.png',
    ),

    // 8. Level 15 - Barnaby the Logic Bear
    MascotCharacter(
      id: 'barnaby_bear',
      name: 'Barnaby',
      species: 'Gentle Bear',
      title: 'LOGIC ARCHITECT',
      emoji: '🐻',
      requiredLevel: 15,
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

    // 9. Level 18 - Finley the Bug Hunter Frog
    MascotCharacter(
      id: 'finley_frog',
      name: 'Finley',
      species: 'Tree Frog',
      title: 'BUG HUNTER',
      emoji: '🐸',
      requiredLevel: 18,
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
    // Canonical aliases for backward compatibility
    final canonicalId = switch (id) {
      'milo_monkey' => 'milo_cat',
      'luna_lynx' => 'nova_bot',
      'toby_turtle' => 'bao_panda',
      _ => id,
    };
    for (final c in characters) {
      if (c.id == canonicalId) return c;
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
  focused,
  sad,
  motivating;

  String get label => switch (this) {
        idle => 'Idle Float',
        celebrating => 'Victory Jump',
        thinking => 'Thinking',
        waving => 'Waving',
        focused => 'Deep Focus',
        sad => 'Feeling Down',
        motivating => 'Motivated Spirit',
      };

  String get emoji => switch (this) {
        idle => '✨',
        celebrating => '🎉',
        thinking => '🤔',
        waving => '👋',
        focused => '🎯',
        sad => '💧',
        motivating => '⚡',
      };
}
