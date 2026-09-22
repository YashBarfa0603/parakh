class OcrStatusModel {
  final String status;
  final int? resultId;
  final int detections;
  final String? error;

  OcrStatusModel({
    required this.status,
    this.resultId,
    this.detections = 0,
    this.error,
  });

  factory OcrStatusModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OcrStatusModel(status: 'NONE');
    return OcrStatusModel(
      status: json['status']?.toString() ?? 'NONE',
      resultId: json['result_id'] is int ? json['result_id'] : int.tryParse(json['result_id']?.toString() ?? ''),
      detections: json['detections'] is int ? json['detections'] : 0,
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'result_id': resultId,
    'detections': detections,
    'error': error,
  };
}

class ImageUploadResponse {
  final String message;
  final int imageId;
  final int inspectionId;
  final String angle;
  final String? captureSource;
  final String imageUrl;
  final String? sha256;
  final int? width;
  final int? height;
  final String? imageQuality;
  final String? authenticityStatus;
  final OcrStatusModel? ocr;

  ImageUploadResponse({
    required this.message,
    required this.imageId,
    required this.inspectionId,
    required this.angle,
    this.captureSource,
    required this.imageUrl,
    this.sha256,
    this.width,
    this.height,
    this.imageQuality,
    this.authenticityStatus,
    this.ocr,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      message: json['message']?.toString() ?? '',
      imageId: json['image_id'] is int ? json['image_id'] : int.tryParse(json['image_id']?.toString() ?? '0') ?? 0,
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.tryParse(json['inspection_id']?.toString() ?? '0') ?? 0,
      angle: json['angle']?.toString() ?? 'FRONT',
      captureSource: json['capture_source']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      sha256: json['sha256']?.toString(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      imageQuality: json['image_quality']?.toString(),
      authenticityStatus: json['authenticity_status']?.toString(),
      ocr: json['ocr'] != null ? OcrStatusModel.fromJson(json['ocr']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'image_id': imageId,
    'inspection_id': inspectionId,
    'angle': angle,
    'capture_source': captureSource,
    'image_url': imageUrl,
    'sha256': sha256,
    'width': width,
    'height': height,
    'image_quality': imageQuality,
    'authenticity_status': authenticityStatus,
    'ocr': ocr?.toJson(),
  };
}
