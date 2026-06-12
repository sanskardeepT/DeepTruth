from pydantic import BaseModel, Field
from typing import List, Optional

class Adjustment(BaseModel):
    impact: int
    factor: str
    category: str

class ConsensusScores(BaseModel):
    trust_score: int = Field(..., ge=0, le=100)
    authenticity_score: int = Field(..., ge=0, le=100)
    manipulation_score: int = Field(..., ge=0, le=100)
    risk_score: int = Field(..., ge=0, le=100)
    confidence_score: int = Field(..., ge=0, le=100)
    verdict: str
    justification: str
    adjustments: List[Adjustment]

class C2PAResponse(BaseModel):
    has_c2pa: bool
    creator: Optional[str] = None
    publisher: Optional[str] = None
    created_at: Optional[str] = None

class ProvenanceResponse(BaseModel):
    reused_count: int
    earliest_date: Optional[str] = None
    source_domain: Optional[str] = None

class DeepfakeResponse(BaseModel):
    overall_risk: float
    image_risk: float
    video_risk: float
    audio_risk: float

class VerifyResponse(BaseModel):
    task_id: str
    sha256: str
    status: str
    consensus: ConsensusScores
    c2pa: C2PAResponse
    provenance: ProvenanceResponse
    deepfake: DeepfakeResponse

class ReputationResponse(BaseModel):
    domain: str
    reputation_score: int
    historical_accuracy: float
    incidents_count: int
    transparency_tier: str

class GraphNode(BaseModel):
    id: str
    label: str
    type: str

class GraphEdge(BaseModel):
    from_node: str = Field(..., alias="from")
    to_node: str = Field(..., alias="to")
    relation: str

    class Config:
        populate_by_name = True

class GraphResponse(BaseModel):
    nodes: List[GraphNode]
    edges: List[GraphEdge]
