from fastapi import FastAPI
from datetime import datetime

app = FastAPI(title="AI Assistant API")

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.get("/")
async def root():
    return {"message": "AI Assistant API is running"}
