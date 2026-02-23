# Twitter/X Thread (post each as a separate tweet)

## Tweet 1 (Hook)
I just published form_forge on pub.dev — the "freezed of forms" for Flutter.

Annotate a Dart class. Run build_runner. Get a production-ready form with validation, error display, and typed submission.

12 lines instead of 87.

Thread 🧵

## Tweet 2 (Before/After)
Before form_forge:
- TextEditingController x2
- dispose() method
- GlobalKey<FormState>
- setState for error handling
- Manual validation logic
= 87 lines for a login form

After form_forge:
- @FormForge() + @IsRequired() + @IsEmail()
= 12 lines. Same result.

## Tweet 3 (Features)
What it generates from your annotated class:

✅ FormController — typed fields, validation, submission
✅ FormWidget — drop-in with error display
✅ FormData — typed data class

Validators: required, email, minLength, maxLength, pattern, min, max, cross-field match, async with debounce

## Tweet 4 (Cross-field + async)
The two features no other Flutter form package nails:

1. Cross-field validation:
@MustMatch('password')
final String confirmPassword;

2. Async validation (email uniqueness check):
@AsyncValidate()
final String email;

Both just work. One annotation each.

## Tweet 5 (CTA)
form_forge v0.1.1 is live on pub.dev:
https://pub.dev/packages/form_forge

GitHub: https://github.com/SahilSharma2710/form_forge

Star it if forms in Flutter have ever frustrated you ⭐

#Flutter #Dart #FormForge #CodeGeneration #pubdev
