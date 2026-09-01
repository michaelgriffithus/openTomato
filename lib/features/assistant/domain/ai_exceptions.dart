import '../../../core/errors/app_exceptions.dart';

abstract class AiException extends AppException {
  const AiException(super.message, super.userMessage);

  @override
  String toString() => 'AiException: $message';
}

class NoActiveProviderException extends AiException {
  const NoActiveProviderException()
      : super(
          'No assistant provider is active',
          'Add an API key in Settings → AI provider to use the assistant.',
        );
}

class ConsentRequiredException extends AiException {
  const ConsentRequiredException(String provider)
      : super(
          'Consent is required for $provider',
          'Review what is sent to $provider before the first message.',
        );
}

class InvalidApiKeyException extends AiException {
  const InvalidApiKeyException(String provider)
      : super(
          'Invalid API key for $provider',
          'The $provider API key was rejected. Check Settings → AI provider.',
        );
}

class RateLimitException extends AiException {
  const RateLimitException(String provider)
      : super(
          'Rate limit exceeded for $provider',
          'Rate limit reached for $provider. Wait a moment and try again.',
        );
}

class AiNetworkException extends AiException {
  const AiNetworkException([
    super.message = 'Network error',
    super.userMessage = 'Network error. Check your connection and try again.',
  ]);
}

/// The provider ran a safety classifier and declined to answer.
class ModelDeclinedException extends AiException {
  const ModelDeclinedException()
      : super(
          'The model declined this request',
          'The model declined to answer this request.',
        );
}

class ApiErrorException extends AiException {
  final int? statusCode;

  ApiErrorException(String message, [this.statusCode, String? userMessage])
      : super(
          message,
          userMessage ??
              (statusCode == null ? message : '$message (HTTP $statusCode)'),
        );
}
