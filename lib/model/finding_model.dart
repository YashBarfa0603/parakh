import '../core/constants.dart';

class FindingModel {
  final int id;
  final String ruleId;
  final String? ruleNumber;
  final String? clause;
  final String requirement;
  final String result;
  final String? evidence;
  final String? reason;
  final String? createdAt;

  FindingModel({
    required this.id,
    required this.ruleId,
    this.ruleNumber,
    this.clause,
    required this.requirement,
    required this.result,
    this.evidence,
    this.reason,
    this.createdAt,
  });

  ComplianceStatus get status => ComplianceStatus.fromBackend(result);
  bool get isPass => result.toUpperCase() == 'PASS';
  bool get isFail => result.toUpperCase() == 'FAIL';
  bool get isReview => result.toUpperCase() == 'REVIEW';

  String get formattedLine {
    final numStr = (ruleNumber != null && ruleNumber!.isNotEmpty) ? ruleNumber! : '6';
    final clauseStr = (clause != null && clause!.isNotEmpty) ? clause! : numStr;
    final resStr = result.toUpperCase();
    final rsnStr = (reason != null && reason!.isNotEmpty) ? reason! : requirement;
    final evStr = (evidence != null && evidence!.trim().isNotEmpty) ? ' ("${evidence!.trim()}")' : '';
    return 'Rule $numStr ($clauseStr) [$resStr] : $rsnStr$evStr';
  }

  factory FindingModel.fromJson(Map<String, dynamic> json) {
    return FindingModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ruleId: json['rule_id']?.toString() ?? '',
      ruleNumber: json['rule_number']?.toString(),
      clause: json['clause']?.toString(),
      requirement: json['requirement']?.toString() ?? '',
      result: json['result']?.toString() ?? 'REVIEW',
      evidence: json['evidence']?.toString(),
      reason: json['reason']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rule_id': ruleId,
      'rule_number': ruleNumber,
      'clause': clause,
      'requirement': requirement,
      'result': result,
      'evidence': evidence,
      'reason': reason,
      'created_at': createdAt,
    };
  }
}
