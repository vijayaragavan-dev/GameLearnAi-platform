# GameLearn AI — Flutter Frontend

The GameLearn AI client: a dark, futuristic, gamified adaptive-learning
experience. **Student = Player · Subject = World · Topic = Mission ·
Lesson = Training · Quiz = Challenge · Nova = AI companion.**

## Architecture

```
lib/
├── main.dart                 bootstrap (SharedPreferences -> ProviderScope)
├── app/
│   ├── gamelearn_app.dart    MaterialApp.router + theme
│   └── router.dart           GoRouter (auth redirect, custom transitions)
├── core/
│   ├── config/               build-time configuration (--dart-define)
│   ├── theme/                AppColors · Typography · Motion · Styles
│   ├── network/              ApiClient · ApiException hierarchy
│   ├── models/               contract models (API Contract v1.4.0 shapes)
│   ├── storage/              JWT secure storage
│   ├── audio/                AudioManager (music/SFX, fail-safe)
│   ├── haptics/              centralized haptics
│   └── utils/                formatters / enum presentation
├── features/
│   ├── auth/                 splash · onboarding · login · register · session
│   ├── dashboard/            DASH-001 command center
│   ├── subjects/             SUBJ-001 world selection
│   ├── learning/             PATH-001/002 adventure map · TOPIC-001 · LESSON-001
│   ├── challenge/            ASMT-001..003 · QUIZ-001/002 · recommendation
│   ├── tutor/                AI-001 Nova Tutor
│   ├── gamification/         GAM-001..003 trophy room · streak
│   ├── progress/             PROG-001/002 stats · topic performance
│   ├── profile/              USER-001 profile · local settings
│   └── shell/                bottom navigation scaffold
└── shared/widgets/           Nova, buttons, cards, XP bar, celebrations,
                              skeletons, error/empty/offline states ...
```

**State management:** flutter_riverpod (Notifier / AsyncNotifier).
**Navigation:** go_router with custom page transitions.
**Backend authority rule:** the backend owns XP, levels, achievements,
streaks, mastery, difficulty, recommendations and assessment results. The
client only renders server values — never recomputes them.

## Running

```bash
flutter pub get

# Android emulator (10.0.2.2 reaches host localhost):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Windows desktop:
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

Environment variables are injected at build time; no secrets live in source.

| dart-define     | Purpose                        | Default                  |
|-----------------|--------------------------------|--------------------------|
| `API_BASE_URL`  | backend base URL               | `http://10.0.2.2:8080`   |
| `APP_ENV`       | environment tag (settings UI)  | `dev`                    |

## Tests

```bash
flutter analyze
flutter test                       # unit + widget tests (offline fakes)
flutter test integration_test -d windows   # real-backend journey (skips if unreachable)
```

## Audio assets

All SFX and music loops in `assets/audio/` are synthesized in-house by
`tools/generate_audio.ps1` — original, royalty-free, seamlessly loopable.
