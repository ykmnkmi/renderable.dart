import 'dart:io';

// import 'package:jinja/jinja.dart';
import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

Future<void> main() async {
  final path = Platform.script.resolve('templates').toFilePath();

  final env = Environment(
    globals: <String, Object?>{
      'now': () {
        final dt = DateTime.now().toLocal();
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      },
    },
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  final data = {
    'users': [
      {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
      {'fullname': 'Jane Doe', 'email': 'janedoe@dev.py'}
    ],
  };

  render(env, data);

  await for (var _ in stdin) {
    render(env, data);
  }
}

void render(Environment env, Map<String, Object?> data) {
  try {
    stdout.write(env.getTemplate('users.html').render(data));
  } catch (e, st) {
    stderr.writeln(e);
    stderr.write(Trace.format(st));
  }
}
