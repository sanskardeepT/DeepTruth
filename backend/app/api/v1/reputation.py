from fastapi import APIRouter, HTTPException
from app.models.schemas import ReputationResponse

router = APIRouter()

@router.get("/reputation/{domain}", response_model=ReputationResponse)
def get_domain_reputation(domain: str):
    clean = domain.replace("https://", "").replace("http://", "").split("/")[0].lower().strip()

    if not clean:
        raise HTTPException(status_code=400, detail="Invalid domain query.")

    if clean in ["reuters.com", "apnews.com", "bbc.co.uk", "nytimes.com"]:
        return ReputationResponse(
            domain=clean,
            reputation_score=98,
            historical_accuracy=99.4,
            incidents_count=0,
            transparency_tier="EXCELLENT"
        )
    elif "leak" in clean or "rumor" in clean or "buzz" in clean or "free" in clean:
        return ReputationResponse(
            domain=clean,
            reputation_score=28,
            historical_accuracy=32.1,
            incidents_count=14,
            transparency_tier="POOR_OPAQUE"
        )
    else:
        return ReputationResponse(
            domain=clean,
            reputation_score=70,
            historical_accuracy=80.5,
            incidents_count=1,
            transparency_tier="MEDIUM_TRANSPARENT"
        )
