import '../../../../core/errors/app_exceptions.dart';

abstract class HAException extends AppException {
  HAException(super.message, super.userMessage);

  @override
  String toString() => 'HAException: $message';
}

class HAConnectionException extends HAException {
  HAConnectionException([
    super.message = 'Cannot connect to Home Assistant',
    super.userMessage =
        'Cannot connect to Home Assistant. Check your network and the URL.',
  ]);
}

class HATlsHandshakeException extends HAConnectionException {
  HATlsHandshakeException([
    super.message = 'Home Assistant TLS handshake failed',
    super.userMessage =
        'Home Assistant HTTPS handshake failed. Use http on your local network '
            'or a certificate your phone trusts.',
  ]);
}

class HAWebSocketTimeoutException extends HAConnectionException {
  HAWebSocketTimeoutException([
    super.message = 'Home Assistant WebSocket timed out',
    super.userMessage =
        'Home Assistant live connection timed out. OpenTomato will retry.',
  ]);
}

class HAClosedSocketException extends HAConnectionException {
  HAClosedSocketException([
    super.message = 'Home Assistant socket closed unexpectedly',
    super.userMessage =
        'Home Assistant connection closed unexpectedly. OpenTomato will retry.',
  ]);
}

class HAAuthenticationException extends HAException {
  HAAuthenticationException([
    super.message = 'Invalid Home Assistant access token',
    super.userMessage =
        'Invalid Home Assistant access token. Check your settings.',
  ]);
}

class HAEntityNotFoundException extends HAException {
  final String entityId;

  HAEntityNotFoundException(
    this.entityId, [
    String message = 'Entity not found',
  ]) : super(message, "Entity '$entityId' not found in Home Assistant.");
}

class HAApiException extends HAException {
  final int? statusCode;

  HAApiException(
    String message, [
    this.statusCode,
    String? userMessage,
  ]) : super(
          message,
          userMessage ?? 'Home Assistant API error (status: $statusCode).',
        );
}

class HAInvalidDataException extends HAException {
  HAInvalidDataException([
    super.message = 'Received invalid data from Home Assistant',
    super.userMessage = 'Received invalid data from Home Assistant.',
  ]);
}
