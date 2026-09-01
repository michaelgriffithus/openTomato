/// One turn in a provider request. Text only; photos are never sent.
class AiMessage {
  final String role;
  final String content;

  const AiMessage({required this.role, required this.content});

  const AiMessage.system(String content)
      : this(role: 'system', content: content);
  const AiMessage.user(String content) : this(role: 'user', content: content);
  const AiMessage.assistant(String content)
      : this(role: 'assistant', content: content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
