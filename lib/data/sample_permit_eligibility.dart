import '../models/permit.dart';
import '../models/permit_eligibility.dart';

PermitEligibilityResult sampleEligibility() {
  return PermitEligibilityResult(
    permitType: PermitType.residential,
    eligible: true,
    reason: 'Eligible for issuance',
    baseFee: 45,
    surcharges: 0,
    waiverAmount: 18,
    totalDue: 27,
    notes: const ['Low-income waiver applied (-40%).'],
  );
}
