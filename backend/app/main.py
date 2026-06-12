from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import verify, reputation, graph, reports

app = FastAPI(
    title="DeepTruth X Trust Intelligence API",
    description="Monolithic verification engine orchestrating C2PA, EXIF, OSINT, and Consensus scoring.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(verify.router, prefix="/api/v1", tags=["Ingest & Verify"])
app.include_router(reputation.router, prefix="/api/v1", tags=["Reputation Index"])
app.include_router(graph.router, prefix="/api/v1", tags=["Trust Graph"])
app.include_router(reports.router, prefix="/api/v1", tags=["Forensic Reports"])

@app.get("/health", tags=["System"])
def health_check():
    return {"status": "healthy", "service": "DeepTruth X Core"}
