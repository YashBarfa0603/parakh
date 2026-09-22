import '../core/constants.dart';
import 'declaration_model.dart';
import 'finding_model.dart';

class AnalysisResultModel {
  final int inspectionId;
  final String status;
  final String? complianceResult;
  final int processedImages;
  final int ocrItemsCount;
  final int declarationsExtracted;
  final int findingsGenerated;
  final List<DeclarationModel> declarations;
  final List<FindingModel> findings;

  AnalysisResultModel({
    required this.inspectionId,
    required this.status,
    this.complianceResult,
    this.processedImages = 0,
    this.ocrItemsCount = 0,
    this.declarationsExtracted = 0,
    this.findingsGenerated = 0,
    this.declarations = const [],
    this.findings = const [],
  });

  ComplianceStatus get complianceStatus => ComplianceStatus.fromBackend(complianceResult);

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    var rawDecls = json['declarations'] as List<dynamic>? ?? [];
    var declList = rawDecls.map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>)).toList();

    var rawFindings = json['findings'] as List<dynamic>? ?? [];
    var findList = rawFindings.map((e) => FindingModel.fromJson(e as Map<String, dynamic>)).toList();

    return AnalysisResultModel(
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.tryParse(json['inspection_id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      complianceResult: json['compliance_result']?.toString(),
      processedImages: json['processed_images'] is int ? json['processed_images'] : 0,
      ocrItemsCount: json['ocr_items_count'] is int ? json['ocr_items_count'] : 0,
      declarationsExtracted: json['declarations_extracted'] is int
          ? json['declarations_extracted']
          : declList.length,
      findingsGenerated: json['findings_generated'] is int
          ? json['findings_generated']
          : findList.length,
      declarations: declList,
      findings: findList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspection_id': inspectionId,
      'status': status,
      'compliance_result': complianceResult,
      'processed_images': processedImages,
      'ocr_items_count': ocrItemsCount,
      'declarations_extracted': declarationsExtracted,
      'findings_generated': findingsGenerated,
      'declarations': declarations.map((e) => e.toJson()).toList(),
      'findings': findings.map((e) => e.toJson()).toList(),
    };
  }
}
