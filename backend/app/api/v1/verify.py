from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.models.schemas import VerifyResponse, ConsensusScores, C2PAResponse, ProvenanceResponse, DeepfakeResponse, Adjustment
import hashlib
import uuid
import datetime
from typing import Optional

router = APIRouter()

@router.post("/verify", response_model=VerifyResponse)
async def verify_asset(
    file: Optional[UploadFile] = File(None),
    claim: Optional[str] = Form(None)
):
    if not file and not claim:
        raise HTTPException(status_code=400, detail="Please submit either a media file or a claim statement.")

    task_id = str(uuid.uuid4())
    file_bytes = b""
    sha256_hash = "N/A"

    if file:
        file_bytes = await file.read()
        sha256_hash = hashlib.sha256(file_bytes).hexdigest()

    # 1. C2PA Parsing Simulation
    has_c2pa = b"c2pa" in file_bytes or b"jumb" in file_bytes
    c2pa_res = C2PAResponse(
        has_c2pa=has_c2pa,
        creator="Reuters Editorial" if has_c2pa else None,
        publisher="Reuters News Agency" if has_c2pa else None,
        created_at=datetime.datetime.now().isoformat() if has_c2pa else None
    )

    # 2. Provenance & EXIF Simulation
    prov_res = ProvenanceResponse(
        reused_count=4 if file else 1,
        earliest_date=(datetime.datetime.now() - datetime.timedelta(days=30)).isoformat(),
        source_domain="reuters.com" if has_c2pa else "unknown.com"
    )

    # 3. Deepfake Pipeline Simulation
    is_synthetic = b"Midjourney" in file_bytes or b"DALL-E" in file_bytes or b"StableDiffusion" in file_bytes
    img_risk = 88.0 if is_synthetic else (12.4 if file else 0.0)
    df_res = DeepfakeResponse(
        overall_risk=img_risk,
        image_risk=img_risk,
        video_risk=0.0,
        audio_risk=0.0
    )

    # 4. Consensus Weighted Scoring Engine
    adjustments = []
    base_trust = 50

    if has_c2pa:
        base_trust += 40
        adjustments.append(Adjustment(impact=40, factor="Valid C2PA Signature (Reuters Trust CA)", category="c2pa"))
    else:
        adjustments.append(Adjustment(impact=0, factor="Unsigned Media (No C2PA Metadata)", category="c2pa"))

    if has_c2pa:
        base_trust += 20
        adjustments.append(Adjustment(impact=20, factor="High Publisher Reputation (reuters.com)", category="reputation"))
    else:
        base_trust -= 15
        adjustments.append(Adjustment(impact=-15, factor="Unverified Source Domain (unknown.com)", category="reputation"))

    if is_synthetic:
        base_trust -= 50
        adjustments.append(Adjustment(impact=-50, factor="High Deepfake GAN Footprint detected", category="deepfake"))
    else:
        base_trust += 10
        adjustments.append(Adjustment(impact=10, factor="No Deepfake anomalies identified", category="deepfake"))

    final_trust = max(0, min(100, base_trust))
    verdict = "TRUE" if final_trust >= 80 else ("MISLEADING" if final_trust >= 50 else "FALSE")
    justification = "Signature verified against Trusted lists, containing no deepfake markers." if final_trust >= 80 else (
        "Content carries unverified metadata and moderate manipulation risks." if final_trust >= 50 else
        "High probability of synthetic modification detected by deepfake classifier."
    )

    con_res = ConsensusScores(
        trust_score=final_trust,
        authenticity_score=final_trust,
        manipulation_score=int(img_risk),
        risk_score=int((100 - final_trust) * 0.4),
        confidence_score=94,
        verdict=verdict,
        justification=justification,
        adjustments=adjustments
    )

    return VerifyResponse(
        task_id=task_id,
        sha256=sha256_hash,
        status="COMPLETED",
        consensus=con_res,
        c2pa=c2pa_res,
        provenance=prov_res,
        deepfake=df_res
    )
