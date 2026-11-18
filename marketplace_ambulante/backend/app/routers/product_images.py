
from pathlib import Path
from uuid import uuid4
from io import BytesIO

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Request,
    UploadFile,
    status,
)
from PIL import Image, UnidentifiedImageError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.business import Business
from app.models.product import Product
from app.routers.auth import get_current_user


router = APIRouter(
    prefix="/productos",
    tags=["Imágenes de productos"],
)

UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "products"

MAX_FILE_SIZE = 5 * 1024 * 1024

ALLOWED_FORMATS = {
    "JPEG": ".jpg",
    "PNG": ".png",
    "WEBP": ".webp",
}


@router.post("/{id_producto}/imagen")
async def subir_imagen_producto(
    id_producto: int,
    request: Request,
    archivo: UploadFile = File(...),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Verificar que el producto pertenezca al negocio del usuario.
    producto = db.scalar(
        select(Product)
        .join(
            Business,
            Product.id_negocio == Business.id_negocio,
        )
        .where(
            Product.id_producto == id_producto,
            Business.id_usuario == current_user.id_usuario,
        )
    )

    if producto is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Producto no encontrado en tu negocio",
        )

    contenido = await archivo.read(MAX_FILE_SIZE + 1)

    if not contenido:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El archivo está vacío",
        )

    if len(contenido) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="La imagen no puede superar los 5 MB",
        )

    try:
        imagen = Image.open(BytesIO(contenido))
        formato = imagen.format

        if formato not in ALLOWED_FORMATS:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail="Formato no permitido. Usa JPG, PNG o WEBP",
            )

        imagen.verify()

    except UnidentifiedImageError:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="El archivo no es una imagen válida",
        )

    except OSError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se pudo procesar la imagen",
        )

    extension = ALLOWED_FORMATS[formato]
    nombre_archivo = f"{uuid4().hex}{extension}"

    carpeta_producto = UPLOAD_DIR / str(id_producto)
    carpeta_producto.mkdir(parents=True, exist_ok=True)

    ruta_archivo = carpeta_producto / nombre_archivo

    try:
        ruta_archivo.write_bytes(contenido)

        url = (
            f"{str(request.base_url).rstrip('/')}"
            f"/uploads/products/{id_producto}/{nombre_archivo}"
        )

        producto.imagen_url = url

        db.commit()
        db.refresh(producto)

    except Exception:
        db.rollback()
        ruta_archivo.unlink(missing_ok=True)

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo guardar la imagen del producto",
        )

    return {
        "mensaje": "Imagen del producto subida correctamente",
        "id_producto": producto.id_producto,
        "url": producto.imagen_url,
    }
