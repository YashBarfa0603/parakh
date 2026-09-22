class BoundingBoxModel {
  final double? x;
  final double? y;
  final double? width;
  final double? height;

  BoundingBoxModel({this.x, this.y, this.width, this.height});

  factory BoundingBoxModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BoundingBoxModel();
    return BoundingBoxModel(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class DeclarationModel {
  final int? id;
  final String fieldName;
  String? value;
  final String? rawValue;
  final double? confidence;
  String extractionMethod;
  String status;
  final int? sourceImageId;
  final int? sourceOcrItemId;
  final String? evidenceText;
  final BoundingBoxModel? bbox;
  final String? angle;

  DeclarationModel({
    this.id,
    required this.fieldName,
    this.value,
    this.rawValue,
    this.confidence,
    this.extractionMethod = 'AUTOMATED',
    this.status = 'PENDING',
    this.sourceImageId,
    this.sourceOcrItemId,
    this.evidenceText,
    this.bbox,
    this.angle,
  });

  bool get isVerified => status.toUpperCase() == 'VERIFIED';
  bool get isEdited => extractionMethod.toUpperCase() == 'MANUAL_OVERRIDE';

  factory DeclarationModel.fromJson(Map<String, dynamic> json) {
    return DeclarationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      fieldName: json['field_name'] ?? '',
      value: json['value']?.toString(),
      rawValue: json['raw_value']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      extractionMethod: json['extraction_method'] ?? 'AUTOMATED',
      status: json['status'] ?? 'PENDING',
      sourceImageId: json['source_image_id'] is int
          ? json['source_image_id']
          : int.tryParse(json['source_image_id']?.toString() ?? ''),
      sourceOcrItemId: json['source_ocr_item_id'] is int
          ? json['source_ocr_item_id']
          : int.tryParse(json['source_ocr_item_id']?.toString() ?? ''),
      evidenceText: json['evidence_text']?.toString(),
      bbox: json['bbox'] != null ? BoundingBoxModel.fromJson(json['bbox']) : null,
      angle: json['angle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'field_name': fieldName,
      'value': value,
      'raw_value': rawValue,
      'confidence': confidence,
      'extraction_method': extractionMethod,
      'status': status,
      if (sourceImageId != null) 'source_image_id': sourceImageId,
      if (sourceOcrItemId != null) 'source_ocr_item_id': sourceOcrItemId,
      if (evidenceText != null) 'evidence_text': evidenceText,
      if (bbox != null) 'bbox': bbox!.toJson(),
      if (angle != null) 'angle': angle,
    };
  }

  DeclarationModel copyWith({
    int? id,
    String? fieldName,
    String? value,
    String? rawValue,
    double? confidence,
    String? extractionMethod,
    String? status,
    int? sourceImageId,
    int? sourceOcrItemId,
    String? evidenceText,
    BoundingBoxModel? bbox,
    String? angle,
  }) {
    return DeclarationModel(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      value: value ?? this.value,
      rawValue: rawValue ?? this.rawValue,
      confidence: confidence ?? this.confidence,
      extractionMethod: extractionMethod ?? this.extractionMethod,
      status: status ?? this.status,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      sourceOcrItemId: sourceOcrItemId ?? this.sourceOcrItemId,
      evidenceText: evidenceText ?? this.evidenceText,
      bbox: bbox ?? this.bbox,
      angle: angle ?? this.angle,
    );
  }
}
