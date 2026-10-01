import 'package:equatable/equatable.dart';

/// Represents an authenticated user profile in Odoo ERP (`res.users`).
class UserModel extends Equatable {
  final int id;
  final String name;
  final String login;
  final bool isInternalUser;

  const UserModel({
    required this.id,
    required this.name,
    required this.login,
    this.isInternalUser = true,
  });

  /// Factory constructor to parse Odoo JSON-2 dictionaries, converting
  /// Odoo `false` representations to clean fallback strings.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedId = json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0;
    final parsedName = json['name'] is String
        ? json['name']
        : (json['name'] == false ? '' : json['name'].toString());
    final parsedLogin = json['login'] is String
        ? json['login']
        : (json['login'] == false ? '' : json['login'].toString());
    final isInternal = json['share'] != true;

    return UserModel(
      id: parsedId,
      name: parsedName,
      login: parsedLogin,
      isInternalUser: isInternal,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'login': login};
  }

  @override
  List<Object?> get props => [id, name, login, isInternalUser];
}
