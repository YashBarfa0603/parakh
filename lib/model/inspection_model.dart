import '../core/constants.dart';
import 'declaration_model.dart';
import 'finding_model.dart';

class InspectionImageModel {
  final int id;
  final String angle;
  final String imageUrl;
  final String? sha256;
  final String? quality;
  final String? authenticityStatus;

  InspectionImageModel({
    required this.id,
    required this.angle,
    required this.imageUrl,
    this.sha256,
    this.quality,
    this.authenticityStatus,
  });

  ImageAngle get imageAngle => ImageAngle.fromString(angle);

  factory InspectionImageModel.fromJson(Map<String, dynamic> json) {
    return InspectionImageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      angle: json['angle']?.toString() ?? 'FRONT',
      imageUrl: json['image_url']?.toString() ?? '',
      sha256: json['sha256']?.toString(),
      quality: json['quality']?.toString() ?? json['image_quality']?.toString(),
      authenticityStatus: json['authenticity_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'angle': angle,
      'image_url': imageUrl,
      'sha256': sha256,
      'quality': quality,
      'authenticity_status': authenticityStatus,
    };
  }
}

class BatchModel {
  final String? batchNumber;
  final String? manufacturingDate;
  final String? rawManufacturingDate;
  final String? expiryDate;
  final String? rawExpiryDate;
  final String? bestBefore;

  BatchModel({
    this.batchNumber,
    this.manufacturingDate,
    this.rawManufacturingDate,
    this.expiryDate,
    this.rawExpiryDate,
    this.bestBefore,
  });

  String? get displayManufacturingDate {
    if (manufacturingDate != null && manufacturingDate!.trim().isNotEmpty) {
      return manufacturingDate;
    }
    return rawManufacturingDate;
  }

  String? get displayExpiryDate {
    if (expiryDate != null && expiryDate!.trim().isNotEmpty) {
      return expiryDate;
    }
    return rawExpiryDate ?? bestBefore;
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      batchNumber: json['batch_number']?.toString(),
      manufacturingDate: json['manufacturing_date']?.toString(),
      rawManufacturingDate: json['raw_manufacturing_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      rawExpiryDate: json['raw_expiry_date']?.toString(),
      bestBefore: json['best_before']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_number': batchNumber,
      'manufacturing_date': manufacturingDate,
      'raw_manufacturing_date': rawManufacturingDate,
      'expiry_date': expiryDate,
      'raw_expiry_date': rawExpiryDate,
      'best_before': bestBefore,
    };
  }
}

class InspectionModel {
  final int id;
  final int? inspectorId;
  final String status;
  final String? complianceResult;

  final String? productName;
  final String? productCode;
  final String? brand;

  final String? manufacturerName;
  final String? manufacturerAddress;

  final String? netQuantity;
  final String? quantityUnit;

  final String? mrp;
  final bool? mrpInclusiveOfTaxes;

  final String? consumerCarePhone;
  final String? consumerCareEmail;
  final String? consumerCareAddress;

  final String? countryOfOrigin;
  final String? category;
  final String? commodityType;

  final String? importerName;
  final String? importerAddress;

  final String? canonicalHash;
  final String? finalizedAt;
  final String? processingError;

  final String? createdAt;
  final String? updatedAt;

  final String? inspectionNumber;
  final int? inspectorSeq;

  final BatchModel? batch;
  final int declarationsCount;
  final int findingsCount;
  final List<InspectionImageModel> images;
  final List<DeclarationModel> declarations;
  final List<FindingModel> findings;

  InspectionModel({
    required this.id,
    this.inspectorId,
    required this.status,
    this.complianceResult,
    this.productName,
    this.productCode,
    this.brand,
    this.manufacturerName,
    this.manufacturerAddress,
    this.netQuantity,
    this.quantityUnit,
    this.mrp,
    this.mrpInclusiveOfTaxes,
    this.consumerCarePhone,
    this.consumerCareEmail,
    this.consumerCareAddress,
    this.countryOfOrigin,
    this.category,
    this.commodityType,
    this.importerName,
    this.importerAddress,
    this.canonicalHash,
    this.finalizedAt,
    this.processingError,
    this.createdAt,
    this.updatedAt,
    this.inspectionNumber,
    this.inspectorSeq,
    this.batch,
    this.declarationsCount = 0,
    this.findingsCount = 0,
    this.images = const [],
    this.declarations = const [],
    this.findings = const [],
  });

  String get displayId => (inspectionNumber != null && inspectionNumber!.isNotEmpty)
      ? inspectionNumber!
      : '#$id';

  ComplianceStatus get complianceStatus => ComplianceStatus.fromBackend(complianceResult);
  bool get isFinalized => status.toUpperCase() == 'FINALIZED';

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'] as List<dynamic>? ?? [];
    var parsedImages = rawImages.map((e) => InspectionImageModel.fromJson(e as Map<String, dynamic>)).toList();

    var rawDeclarations = json['declarations'] as List<dynamic>? ?? [];
    var parsedDeclarations = rawDeclarations.map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>)).toList();

    var rawFindings = json['findings'] as List<dynamic>? ?? [];
    var parsedFindings = rawFindings.map((e) => FindingModel.fromJson(e as Map<String, dynamic>)).toList();

    return InspectionModel(
      id: (json['id'] ?? json['inspection_id']) is int
          ? (json['id'] ?? json['inspection_id'])
          : int.tryParse((json['id'] ?? json['inspection_id'])?.toString() ?? '0') ?? 0,
      inspectorId: json['inspector_id'] is int
          ? json['inspector_id']
          : int.tryParse(json['inspector_id']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'PENDING',
      complianceResult: json['compliance_result']?.toString(),
      productName: json['product_name']?.toString(),
      productCode: json['product_code']?.toString(),
      brand: json['brand']?.toString(),
      manufacturerName: json['manufacturer_name']?.toString(),
      manufacturerAddress: json['manufacturer_address']?.toString(),
      netQuantity: json['net_quantity']?.toString(),
      quantityUnit: json['quantity_unit']?.toString(),
      mrp: json['mrp']?.toString(),
      mrpInclusiveOfTaxes: json['mrp_inclusive_of_taxes'] as bool?,
      consumerCarePhone: json['consumer_care_phone']?.toString(),
      consumerCareEmail: json['consumer_care_email']?.toString(),
      consumerCareAddress: json['consumer_care_address']?.toString(),
      countryOfOrigin: json['country_of_origin']?.toString(),
      category: json['category']?.toString(),
      commodityType: json['commodity_type']?.toString(),
      importerName: json['importer_name']?.toString(),
      importerAddress: json['importer_address']?.toString(),
      canonicalHash: json['canonical_hash']?.toString(),
      finalizedAt: json['finalized_at']?.toString(),
      processingError: json['processing_error']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      inspectionNumber: json['inspection_number']?.toString(),
      inspectorSeq: json['inspector_seq'] is int
          ? json['inspector_seq']
          : int.tryParse(json['inspector_seq']?.toString() ?? ''),
      batch: json['batch'] != null ? BatchModel.fromJson(json['batch']) : null,
      declarationsCount: json['declarations_count'] is int
          ? json['declarations_count']
          : parsedDeclarations.length,
      findingsCount: json['findings_count'] is int
          ? json['findings_count']
          : parsedFindings.length,
      images: parsedImages,
      declarations: parsedDeclarations,
      findings: parsedFindings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspector_id': inspectorId,
      'status': status,
      'compliance_result': complianceResult,
      'product_name': productName,
      'product_code': productCode,
      'brand': brand,
      'manufacturer_name': manufacturerName,
      'manufacturer_address': manufacturerAddress,
      'net_quantity': netQuantity,
      'quantity_unit': quantityUnit,
      'mrp': mrp,
      'mrp_inclusive_of_taxes': mrpInclusiveOfTaxes,
      'consumer_care_phone': consumerCarePhone,
      'consumer_care_email': consumerCareEmail,
      'consumer_care_address': consumerCareAddress,
      'country_of_origin': countryOfOrigin,
      'category': category,
      'commodity_type': commodityType,
      'importer_name': importerName,
      'importer_address': importerAddress,
      'canonical_hash': canonicalHash,
      'finalized_at': finalizedAt,
      'processing_error': processingError,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'inspection_number': inspectionNumber,
      'inspector_seq': inspectorSeq,
      if (batch != null) 'batch': batch!.toJson(),
      'declarations_count': declarationsCount,
      'findings_count': findingsCount,
      'images': images.map((e) => e.toJson()).toList(),
      'declarations': declarations.map((e) => e.toJson()).toList(),
      'findings': findings.map((e) => e.toJson()).toList(),
    };
  }
}
