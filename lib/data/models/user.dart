class User{
  final String id;
  final String login;
  final String firstName;
  final String lastName;
  final String email;


  User({
    required this.id,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory User.copy(User user) => User(
    id: user.id,
    login: user.login,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
  );

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    login: json['login'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'login': login,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
  };
}