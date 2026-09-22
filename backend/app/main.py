from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from . import models

_ = models  # Ensure all SQLAlchemy models are loaded into Base metadata
from .routers.auth_router import router as auth_router
from .routers.admin_router import router as admin_router
from .routers.inspection_router import router as inspection_router

# when FastAPI starts, SQLAlchemy checks whether the table exists. If it doesn't, it creates it.
Base.metadata.create_all(bind=engine)

app = FastAPI(title="PARAKH API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

import os
from fastapi.staticfiles import StaticFiles

uploads_dir = os.path.join(os.getcwd(), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(inspection_router)

@app.get("/")
def root():
    return {"message": "Parakh API IS Running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)