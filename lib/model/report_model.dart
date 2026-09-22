class ReportModel {
  final int? id;
  final int inspectionId;
  final String? inspectionNumber;
  final String? reportHash;
  final String? canonicalHash;
  final String? pdfUrl;
  final String? reportUrl;
  final String status;
  final String? finalizedAt;
  final String? message;

  ReportModel({
    this.id,
    required this.inspectionId,
    this.inspectionNumber,
    this.reportHash,
    this.canonicalHash,
    this.pdfUrl,
    this.reportUrl,
    required this.status,
    this.finalizedAt,
    this.message,
  });

  String get displayId => (inspectionNumber != null && inspectionNumber!.isNotEmpty)
      ? inspectionNumber!
      : '#$inspectionId';

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] is int
          ? json['id']
          : (json['report_id'] is int ? json['report_id'] : int.tryParse(json['report_id']?.toString() ?? '')),
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.tryParse(json['inspection_id']?.toString() ?? '0') ?? 0,
      inspectionNumber: json['inspection_number']?.toString(),
      reportHash: json['report_hash']?.toString(),
      canonicalHash: json['canonical_hash']?.toString(),
      pdfUrl: json['pdf_url']?.toString(),
      reportUrl: json['report_url']?.toString(),
      status: json['status']?.toString() ?? 'FINALIZED',
      finalizedAt: json['finalized_at']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'inspection_number': inspectionNumber,
      'report_hash': reportHash,
      'canonical_hash': canonicalHash,
      'pdf_url': pdfUrl,
      'report_url': reportUrl,
      'status': status,
      'finalized_at': finalizedAt,
      'message': message,
    };
  }
}
