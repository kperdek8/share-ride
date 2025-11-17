from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from matching_algorithm import example
from typing import Dict, Any

app = FastAPI(
    title="ShareRide Matching Service",
    description="Usluga dopasowywania pasazerow z kierowcami",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "ShareRide Matching Service", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


# Do zamiany na integracje z Kafka
@app.get("/api/test")
async def test_endpoint():
    return example()
