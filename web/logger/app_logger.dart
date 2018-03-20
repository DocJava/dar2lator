const _isDevEnv = true;

logToConsole(dynamic message) {
  if (!_isDevEnv) {
    return;
  }

  String output = "$message";
  print(output);
}