from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any

app = FastAPI(
    title="ShareRide API",
    description="API dla aplikacji ShareRide - wspólne przejazdy",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "ShareRide API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.get("/api/test")
async def test_endpoint():
    return {
        "message": "Test endpoint działa!",
        "data": {
            "timestamp": "2025-11-14 12:00:00",
            "version": "1.0.0"
        }
    }


@app.post("/api/test")
async def test_post(data: Dict[str, Any]):
    return {
        "message": "Dane otrzymane!",
        "received_data": data,
        "status": "success"
    }

