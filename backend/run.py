import uvicorn

if __name__ == "__main__":
    print("🚀 Starting PARAKH Backend Server on http://0.0.0.0:8000 (accessible on local network)...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
