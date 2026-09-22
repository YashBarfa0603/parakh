class InspectorModel {
  final int id;
  final String name;
  final String email;
  final String phone;

  final String inspectorId;
  final String department;
  final String designation;
  final String office;

  final String state;
  final String district;
  final String city;

  final String accountStatus;
  final String? rejectionReason;

  InspectorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.inspectorId,
    required this.department,
    required this.designation,
    required this.office,
    required this.state,
    required this.district,
    required this.city,
    this.accountStatus = 'PENDING',
    this.rejectionReason,
  });

  bool get isApproved => accountStatus.toUpperCase() == 'APPROVED';
  bool get isPending => accountStatus.toUpperCase() == 'PENDING';
  bool get isRejected => accountStatus.toUpperCase() == 'REJECTED';

  factory InspectorModel.fromJson(Map<String, dynamic> json) {
    return InspectorModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      inspectorId: json['inspector_id'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      office: json['office'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      accountStatus: json['account_status'] ?? 'PENDING',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'inspector_id': inspectorId,
      'department': department,
      'designation': designation,
      'office': office,
      'state': state,
      'district': district,
      'city': city,
      'account_status': accountStatus,
      'rejection_reason': rejectionReason,
    };
  }
}
