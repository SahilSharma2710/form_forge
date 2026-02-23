# LinkedIn Post

Just shipped my first open-source Flutter package to pub.dev: form_forge

The problem: Every Flutter app has forms. Login, signup, checkout, profile edit. And every form means the same boilerplate — controllers, validators, dispose, error handling, state management. A simple login form? 87 lines of code. For two fields.

The solution: I built form_forge — a code-generation engine that works like freezed but for forms. You annotate a Dart class with your validation rules, run build_runner, and get a fully functional form with typed controllers, widget rendering, and error display. 12 lines instead of 87.

What makes it different from existing form packages:
- Code generation (not runtime widgets) — compile-time safety
- Async validation with auto-debounce (server-side checks in one annotation)
- Cross-field validation (@MustMatch for confirm password)
- State management agnostic (works with Provider, Riverpod, Bloc)
- Zero runtime dependencies beyond Flutter SDK

It's v0.1.1 — the beginning. But the code-gen pipeline is working end-to-end with 109 tests passing and zero dart analyze warnings.

Check it out:
🔗 pub.dev: https://pub.dev/packages/form_forge
🔗 GitHub: https://github.com/SahilSharma2710/form_forge

If you've ever been frustrated by form boilerplate in Flutter, I'd love your feedback.

#Flutter #Dart #OpenSource #MobileDevelopment #CodeGeneration #pubdev
