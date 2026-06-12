from fastapi import APIRouter
from app.models.schemas import GraphResponse, GraphNode, GraphEdge
import uuid

router = APIRouter()

@router.get("/graph/lineage/{media_hash}", response_model=GraphResponse)
def get_graph_lineage(media_hash: str):
    # Generates a standard mock graph layout representing lineage
    creator_id = f"act_{uuid.uuid4().hex[:6]}"
    org_id = f"org_{uuid.uuid4().hex[:6]}"
    domain_id = f"dom_{uuid.uuid4().hex[:6]}"
    media_id = "media_main"
    campaign_id = f"camp_{uuid.uuid4().hex[:6]}"
    botnet_id = f"bot_{uuid.uuid4().hex[:6]}"
    dffam_id = f"df_{uuid.uuid4().hex[:6]}"

    nodes = [
        GraphNode(id=creator_id, label="AP Photographer", type="Person"),
        GraphNode(id=org_id, label="Associated Press", type="Organization"),
        GraphNode(id=domain_id, label="apnews.com", type="Domain"),
        GraphNode(id=media_id, label=f"Media: {media_hash[:8]}", type="Media"),
        GraphNode(id=campaign_id, label="Narrative Spike #4", type="Campaign"),
        GraphNode(id=botnet_id, label="Botnet Cluster Alpha", type="BotNetwork"),
        GraphNode(id=dffam_id, label="GAN Synthesis", type="DeepfakeFamily")
    ]

    edges = [
        GraphEdge(from_node=creator_id, to_node=media_id, relation="CREATED"),
        GraphEdge(from_node=org_id, to_node=creator_id, relation="BELONGS_TO"),
        GraphEdge(from_node=domain_id, to_node=media_id, relation="HOSTS"),
        GraphEdge(from_node=media_id, to_node=campaign_id, relation="PART_OF"),
        GraphEdge(from_node=botnet_id, to_node=campaign_id, relation="PROPAGATED_BY"),
        GraphEdge(from_node=media_id, to_node=dffam_id, relation="GENERATED_BY")
    ]

    return GraphResponse(nodes=nodes, edges=edges)
