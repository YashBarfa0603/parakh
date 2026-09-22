import 'inspector_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String tokenType;
  final InspectorModel inspector;

  AuthResponseModel({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.inspector,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      inspector: InspectorModel.fromJson(json['inspector'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'inspector': inspector.toJson(),
    };
  }
}
