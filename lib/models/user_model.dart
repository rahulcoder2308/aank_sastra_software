class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<dynamic> permissions;
  final String? location;
  final String? specialization;
  final String? certifications;
  final String? designation;
  final String totalClients;
  final String analysesDone;
  final String? experience;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.permissions,
    this.location,
    this.specialization,
    this.certifications,
    this.designation,
    this.totalClients = '0',
    this.analysesDone = '0',
    this.experience,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'User',
      permissions: json['permissions'] ?? [],
      location: json['location'],
      specialization: json['specialization'],
      certifications: json['certifications'],
      designation: json['designation'],
      totalClients: json['total_clients']?.toString() ?? '0',
      analysesDone: json['analyses_done']?.toString() ?? '0',
      experience: json['experience'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'permissions': permissions,
      'location': location,
      'specialization': specialization,
      'certifications': certifications,
      'designation': designation,
      'total_clients': totalClients,
      'analyses_done': analysesDone,
      'experience': experience,
    };
  }

  bool hasPermission(String module, String action) {
    if (role == 'Admin') return true;

    for (var p in permissions) {
      if (p['module'] == module) {
        bool check(dynamic value) {
          return value == 1 || value == '1' || value == true;
        }

        switch (action) {
          case 'view':
            return check(p['can_view']);
          case 'create':
            return check(p['can_create']);
          case 'edit':
            return check(p['can_edit']);
          case 'delete':
            return check(p['can_delete']);
        }
      }
    }
    return false;
  }
}
