class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? locationId;
  final String? managerId;
  final String? department;
  final String? avatarUrl;
  final String? fcmToken;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final bool isActiveFlag;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.locationId,
    this.managerId,
    this.department,
    this.avatarUrl,
    this.fcmToken,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    required this.isActiveFlag,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';
  bool get isAdmin => role == 'super_admin' || role == 'location_admin';
  bool get canAccess => status == 'active';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'employee',
      status: json['status'] ?? 'pending',
      locationId: json['location_id'],
      managerId: json['manager_id'],
      department: json['department'],
      avatarUrl: json['avatar_url'],
      fcmToken: json['fcm_token'],
      rejectionReason: json['rejection_reason'],
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
      isActiveFlag: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'location_id': locationId,
      'manager_id': managerId,
      'department': department,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'rejection_reason': rejectionReason,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'is_active': isActiveFlag,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
