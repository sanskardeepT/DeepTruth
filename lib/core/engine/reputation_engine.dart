import '../models/trust_verification_models.dart';
import 'reputation_history_engine.dart';

class ReputationEngine {
  ReputationEngine._();
  static final ReputationEngine instance = ReputationEngine._();

  Future<ReputationResult> evaluateDomain(String domain) async {
    return ReputationHistoryEngine.instance.getReputation(domain);
  }
}
