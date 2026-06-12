from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from app.models.schemas import VerifyResponse
import io

router = APIRouter()

@router.post("/reports/generate")
def generate_report(payload: VerifyResponse):
    # Generates a simple text-based diagnostic summary report in PDF format bytes
    # To keep it lightweight and zero-dependency for MVP, we stream raw text diagnostics
    try:
        buffer = io.BytesIO()
        buffer.write(f"DEEPTRUTH X FORENSIC AUDIT REPORT\n".encode('utf-8'))
        buffer.write(f"=================================\n".encode('utf-8'))
        buffer.write(f"Task ID: {payload.task_id}\n".encode('utf-8'))
        buffer.write(f"SHA-256 Hash: {payload.sha256}\n\n".encode('utf-8'))
        buffer.write(f"CONSENSUS SCORE CARD:\n".encode('utf-8'))
        buffer.write(f"- Overall Trust: {payload.consensus.trust_score}/100\n".encode('utf-8'))
        buffer.write(f"- Verdict: {payload.consensus.verdict}\n".encode('utf-8'))
        buffer.write(f"- Justification: {payload.consensus.justification}\n\n".encode('utf-8'))
        buffer.write(f"METADATA INTELLIGENCE:\n".encode('utf-8'))
        buffer.write(f"- C2PA Manifest Present: {payload.c2pa.has_c2pa}\n".encode('utf-8'))
        buffer.write(f"- Source appearances: {payload.provenance.reused_count} appearances\n".encode('utf-8'))
        buffer.write(f"- Deepfake Visual Risk: {payload.deepfake.image_risk}%\n".encode('utf-8'))

        pdf_bytes = buffer.getvalue()
        buffer.close()

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename=report_{payload.task_id}.pdf"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate report: {e}")
