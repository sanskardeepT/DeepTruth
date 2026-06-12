import 'package:uuid/uuid.dart';
import '../models/trust_verification_models.dart';

class TrustGraphService {
  TrustGraphService._();
  static final TrustGraphService instance = TrustGraphService._();

  final _uuid = const Uuid();

  TrustGraph generateLineage({
    required String creatorName,
    required String publisherName,
    required String sourceDomain,
    required String deepfakeFamily,
  }) {
    final creatorId = 'actor_${_uuid.v4().substring(0, 8)}';
    final orgId = 'org_${_uuid.v4().substring(0, 8)}';
    final domainId = 'domain_${_uuid.v4().substring(0, 8)}';
    final mediaId = 'media_${_uuid.v4().substring(0, 8)}';
    final campaignId = 'campaign_${_uuid.v4().substring(0, 8)}';
    final botNetId = 'botnet_${_uuid.v4().substring(0, 8)}';
    final dfFamId = 'df_${_uuid.v4().substring(0, 8)}';

    final nodes = [
      TrustGraphNode(
          id: creatorId,
          label: creatorName.isEmpty ? 'Unknown Artist' : creatorName,
          type: 'Person',
          properties: const {'trust': 'Verified'}),
      TrustGraphNode(
          id: orgId,
          label: publisherName.isEmpty ? 'Unknown Agency' : publisherName,
          type: 'Organization',
          properties: const {'credibility': 'High'}),
      TrustGraphNode(
          id: domainId,
          label: sourceDomain.isEmpty ? 'unknown.com' : sourceDomain,
          type: 'Domain',
          properties: const {'tls': 'Valid'}),
      TrustGraphNode(
          id: mediaId,
          label: 'Asset SHA-256',
          type: 'Media',
          properties: const {'hash': 'df878a8767...'}),
      TrustGraphNode(
          id: campaignId,
          label: 'Narrative Spike #4',
          type: 'Campaign',
          properties: const {'virality': 'High'}),
      TrustGraphNode(
          id: botNetId,
          label: 'Bot Cluster Alpha',
          type: 'BotNetwork',
          properties: const {'nodes': 48}),
      TrustGraphNode(
          id: dfFamId,
          label: deepfakeFamily.isEmpty ? 'StableDiffusion-v2' : deepfakeFamily,
          type: 'DeepfakeFamily',
          properties: const {'method': 'GAN'}),
    ];

    final edges = [
      TrustGraphEdge(from: creatorId, to: mediaId, relation: 'CREATED'),
      TrustGraphEdge(from: orgId, to: creatorId, relation: 'BELONGS_TO'),
      TrustGraphEdge(from: domainId, to: mediaId, relation: 'HOSTS'),
      TrustGraphEdge(from: mediaId, to: campaignId, relation: 'PART_OF'),
      TrustGraphEdge(from: botNetId, to: campaignId, relation: 'PROPAGATED_BY'),
      TrustGraphEdge(from: mediaId, to: dfFamId, relation: 'GENERATED_BY'),
    ];

    return TrustGraph(nodes: nodes, edges: edges);
  }
}
