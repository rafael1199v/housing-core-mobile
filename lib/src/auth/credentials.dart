class Credentials {
  const Credentials({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory Credentials.fromJson(Map<String, dynamic> json) => Credentials(
        accessToken: (json['accessToken'] ?? '').toString(),
        refreshToken: (json['refreshToken'] ?? '').toString(),
      );
}
