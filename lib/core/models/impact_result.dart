class ImpactResult {
  final String directImpact;
  final String? financialImpact;
  final String? healthImpact;
  final String futureImpact6Months;
  final String futureImpact1Year;
  final String futureImpact5Years;
  final List<String> actionableSteps;
  final String affectedPeopleDescription;

  const ImpactResult({
    required this.directImpact,
    this.financialImpact,
    this.healthImpact,
    required this.futureImpact6Months,
    required this.futureImpact1Year,
    required this.futureImpact5Years,
    this.actionableSteps = const [],
    required this.affectedPeopleDescription,
  });

  factory ImpactResult.fromJson(Map<String, dynamic> json) {
    return ImpactResult(
      directImpact:              json['directImpact']              as String? ?? 'Impact analysis unavailable.',
      financialImpact:           json['financialImpact']           as String?,
      healthImpact:              json['healthImpact']              as String?,
      futureImpact6Months:       json['futureImpact6Months']       as String? ?? '',
      futureImpact1Year:         json['futureImpact1Year']         as String? ?? '',
      futureImpact5Years:        json['futureImpact5Years']        as String? ?? '',
      actionableSteps:           (json['actionableSteps'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      affectedPeopleDescription: json['affectedPeopleDescription'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'directImpact':              directImpact,
    'financialImpact':           financialImpact,
    'healthImpact':              healthImpact,
    'futureImpact6Months':       futureImpact6Months,
    'futureImpact1Year':         futureImpact1Year,
    'futureImpact5Years':        futureImpact5Years,
    'actionableSteps':           actionableSteps,
    'affectedPeopleDescription': affectedPeopleDescription,
  };
}
