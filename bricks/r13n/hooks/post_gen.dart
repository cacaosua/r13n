import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

Future<void> run(HookContext context) async {
  final runProcess = ProcessOverrides.current?.runProcess ?? Process.run;
  final progress = context.logger.progress('Running "flutter format ."');
  final result = await runProcess(
    'flutter',
    ['format', '.'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  progress.complete();

  if (result.exitCode != ExitCode.success.code) {
    throw Exception(result.stderr);
  }
}

/// The classes below should be part of their own library, but Mason
/// does not yet support that, so for now they are here.
///
/// Enjoy.

const _asyncRunZoned = runZoned;

/// Type definition for [Process.run].
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool runInShell,
});

/// This class facilitates overriding [Process.run].
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
@visibleForTesting
abstract class ProcessOverrides {
  static final _token = Object();

  /// Returns the current [ProcessOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [ProcessOverrides].
  ///
  /// See also:
  /// * [ProcessOverrides.runZoned] to provide [ProcessOverrides]
  /// in a fresh [Zone].
  ///
  static ProcessOverrides? get current {
    return Zone.current[_token] as ProcessOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    RunProcess? runProcess,
  }) {
    final overrides = _ProcessOverridesScope(runProcess);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The method used to run a [Process].
  RunProcess get runProcess => Process.run;
}

class _ProcessOverridesScope extends ProcessOverrides {
  _ProcessOverridesScope(this._runProcess);

  final ProcessOverrides? _previous = ProcessOverrides.current;
  final RunProcess? _runProcess;

  @override
  RunProcess get runProcess {
    return _runProcess ?? _previous?.runProcess ?? super.runProcess;
  }
}
