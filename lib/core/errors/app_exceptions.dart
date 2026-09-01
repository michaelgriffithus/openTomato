abstract class AppException implements Exception {
  final String message;
  final String userMessage;

  const AppException(this.message, this.userMessage);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, [
    super.userMessage = 'A network error occurred. Please try again.',
  ]);
}

class ParseException extends AppException {
  const ParseException(
    super.message, [
    super.userMessage = 'OpenTomato could not read the requested data.',
  ]);
}

class AuthException extends AppException {
  const AuthException(
    super.message, [
    super.userMessage = 'Authentication failed. Please check your settings.',
  ]);
}

class DataNotFoundException extends AppException {
  const DataNotFoundException(
    super.message, [
    super.userMessage = 'The requested data is not available.',
  ]);
}
