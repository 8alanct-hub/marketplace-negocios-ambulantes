
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
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Business
from app.routers.auth import get_current_user

router = APIRouter(
    prefix="/negocios/mio/imagenes",
    tags=["Imágenes del negocio"],
)

UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "businesses"

MAX_FILE_SIZE = 5 * 1024 * 1024

ALLOWED_FORMATS = {
    "JPEG": ".jpg",
    "PNG": ".png",
    "WEBP": ".webp",
}


@router.post("/{tipo}")
async def subir_imagen_negocio(
    tipo: str,
    request: Request,
    archivo: UploadFile = File(...),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if tipo not in ("logo", "banner"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El tipo debe ser 'logo' o 'banner'",
        )

    negocio = db.query(Business).filter(
        Business.id_usuario == current_user.id_usuario
    ).first()

    if negocio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes un negocio registrado",
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

    carpeta_negocio = UPLOAD_DIR / str(negocio.id_negocio)
    carpeta_negocio.mkdir(parents=True, exist_ok=True)

    ruta_archivo = carpeta_negocio / nombre_archivo

    try:
        ruta_archivo.write_bytes(contenido)

        url = (
            f"{str(request.base_url).rstrip('/')}"
            f"/uploads/businesses/{negocio.id_negocio}/{nombre_archivo}"
        )

        campo = "logo_url" if tipo == "logo" else "banner_url"
        setattr(negocio, campo, url)

        db.commit()
        db.refresh(negocio)

    except Exception:
        db.rollback()
        ruta_archivo.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudo guardar la imagen",
        )

    return {
        "mensaje": "Imagen subida correctamente",
        "tipo": tipo,
        "url": url,
    }
