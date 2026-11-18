from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routers.admin import router as admin_router
from app.routers.auth import router as auth_router
from app.routers.businesses import router as businesses_router
from app.routers.categories import router as categories_router
from app.routers.health import router as health_router
from app.routers.payment_methods import router as payment_methods_router
from app.routers.product_images import router as product_images_router
from app.routers.products import router as products_router
from app.routers.uploads import router as uploads_router


app = FastAPI(
    title="Marketplace Ambulante API",
    description="API REST para la aplicación Marketplace Ambulante",
    version="0.2.0",
)

UPLOAD_DIR = Path(__file__).resolve().parent.parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOAD_DIR)),
    name="uploads",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(businesses_router)
app.include_router(categories_router)
app.include_router(payment_methods_router)
app.include_router(uploads_router)
app.include_router(product_images_router)
app.include_router(products_router)
app.include_router(admin_router)


@app.get("/", tags=["Inicio"])
def root():
    return {"message": "Marketplace Ambulante API", "docs": "/docs"}
