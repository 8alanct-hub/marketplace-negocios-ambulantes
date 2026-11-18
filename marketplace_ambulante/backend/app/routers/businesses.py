from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import and_, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Business, User
from app.routers.auth import get_current_user
from app.schemas.business import (
    BusinessCreateRequest,
    BusinessUpdateRequest,
    BusinessResponse,
    BusinessListResponse,
)


router = APIRouter(prefix="/negocios", tags=["Negocios"])


@router.post(
    "",
    response_model=BusinessResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_business(
    data: BusinessCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Una cuenta con rol USUARIO no puede crear un negocio.
    if current_user.rol == "USUARIO":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta cuenta ya tiene el rol de usuario.",
        )

    # Comprobar si el usuario ya tiene un negocio.
    existing = db.scalar(
        select(Business).where(
            Business.id_usuario == current_user.id_usuario
        )
    )

    if existing:
        # No permitir modificar el tipo de un negocio suspendido.
        if not existing.estado and existing.tipo != data.tipo:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tu negocio está suspendido. No puedes modificar sus datos.",
            )

        # Permite recuperar el negocio si se repite la solicitud.
        if existing.tipo != data.tipo:
            existing.tipo = data.tipo
            db.commit()
            db.refresh(existing)

        return existing

    # Crear el negocio sin inventar datos de ubicación.
    business = Business(
        id_usuario=current_user.id_usuario,
        tipo=data.tipo,
        nombre_comercial="",
        direccion="",
        latitud=None,
        longitud=None,
        ubicacion_actualizada=None,
        estado=True,
    )

    try:
        db.add(business)
        db.commit()
        db.refresh(business)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El usuario ya tiene un negocio registrado.",
        )

    return business


@router.get(
    "/mio",
    response_model=BusinessResponse | None,
)
def get_my_business(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # El propietario puede consultar su negocio incluso si está suspendido.
    business = db.scalar(
        select(Business).where(
            Business.id_usuario == current_user.id_usuario
        )
    )

    return business


@router.patch(
    "/mio",
    response_model=BusinessResponse,
)
def update_my_business(
    data: BusinessUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    business = db.scalar(
        select(Business).where(
            Business.id_usuario == current_user.id_usuario
        )
    )

    if business is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes un negocio registrado.",
        )

    # Los negocios suspendidos no pueden modificar sus datos.
    if not business.estado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu negocio está suspendido. No puedes modificar sus datos.",
        )

    cambios = data.model_dump(exclude_unset=True)

    # Estos campos no admiten NULL en la base de datos.
    for campo in ("nombre_comercial", "direccion", "tipo"):
        if campo in cambios and cambios[campo] is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"El campo {campo} no puede ser nulo.",
            )

    # Aplicar los campos enviados, conservando los demás.
    coordenadas_enviadas = (
        "latitud" in cambios or "longitud" in cambios
    )

    for campo, valor in cambios.items():
        setattr(business, campo, valor)

    # La fecha representa cuándo se registró la ubicación real.
    if coordenadas_enviadas:
        if business.latitud is not None and business.longitud is not None:
            business.ubicacion_actualizada = datetime.now()
        else:
            business.ubicacion_actualizada = None

    try:
        db.commit()
        db.refresh(business)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Los datos proporcionados no son compatibles con el negocio.",
        )

    return business


@router.get(
    "",
    response_model=BusinessListResponse,
)
def list_public_businesses(
    db: Session = Depends(get_db),
):
    # Solo se muestran negocios activos y con información pública completa.
    condiciones = [
        Business.estado.is_(True),
        Business.nombre_comercial != "",
        Business.latitud.is_not(None),
        Business.longitud.is_not(None),
        or_(
            and_(
                Business.tipo == "FIJO",
                Business.direccion != "",
            ),
            and_(
                Business.tipo == "AMBULANTE",
                Business.ubicacion_actualizada.is_not(None),
            ),
        ),
    ]

    negocios = db.scalars(
        select(Business)
        .where(*condiciones)
        .order_by(Business.fecha_actualizacion.desc())
    ).all()

    return {"items": negocios}
