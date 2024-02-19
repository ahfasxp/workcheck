import 'package:process_run/process_run.dart';
import 'package:workcheck/app/app.logger.dart';

class ShellService {
  final _log = getLogger('ShellService');

  final _shell = Shell();

  Future<String> run(String command) async {
    try {
      var response = await _shell.run(command);

      String result = response.map((line) => line.stdout).join();

      return result;
    } catch (e) {
      _log.e(e);
      throw 'Error running command: $command';
    }
  }
}
