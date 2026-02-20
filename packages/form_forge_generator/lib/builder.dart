import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/form_forge_generator.dart';

/// Builder factory for form_forge code generation.
///
/// Registered in `build.yaml` and invoked by `build_runner`.
Builder formForgeBuilder(BuilderOptions options) =>
    SharedPartBuilder([FormForgeGenerator()], 'form_forge');
