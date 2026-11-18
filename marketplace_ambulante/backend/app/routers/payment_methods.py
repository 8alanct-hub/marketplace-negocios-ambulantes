
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Business,
    BusinessPaymentMethod,
    PaymentMethod,
    User,
)
from app.routers.auth import get_current_user
from app.schemas.payment_method import (
    PaymentMethodListResponse,
    PaymentMethodResponse,
    BusinessPaymentMethodsResponse,
    BusinessPaymentMethodsUpdateRequest,
)

router = APIRouter(tags=["Modalidades de pago"])


@router.get(
    "/modalidades-pago",
    response_model=PaymentMethodListResponse,
)
def list_payment_methods(
    db: Session = Depends(get_db),
):
    methods = db.scalars(
        select(PaymentMethod)
        .where(PaymentMethod.estado.is_(True))
        .order_by(PaymentMethod.id_modalidad)
    ).all()

    return {
        "items": [
            {
                "id": str(method.id_modalidad),
                "nombre": method.nombre,
                "descripcion": method.descripcion or "",
            }
            for method in methods
        ]
    }


def get_owned_business(
    current_user: User,
    db: Session,
) -> Business:
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

    return business


@router.get(
    "/negocios/mio/modalidades-pago",
    response_model=BusinessPaymentMethodsResponse,
)
def get_my_payment_methods(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    business = get_owned_business(current_user, db)

    associations = db.scalars(
        select(BusinessPaymentMethod).where(
            BusinessPaymentMethod.id_negocio == business.id_negocio,
            BusinessPaymentMethod.habilitada.is_(True),
        )
    ).all()

    return {
        "modalidad_ids": [
            str(item.id_modalidad)
            for item in associations
        ]
    }


@router.put(
    "/negocios/mio/modalidades-pago",
    response_model=BusinessPaymentMethodsResponse,
)
def update_my_payment_methods(
    data: BusinessPaymentMethodsUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    business = get_owned_business(current_user, db)

    # Convertir los identificadores String de Flutter a enteros.
    try:
        modality_ids = [int(value) for value in data.modalidad_ids]
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Los identificadores de modalidades deben ser numéricos.",
        )

    if any(value <= 0 for value in modality_ids):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Los identificadores deben ser positivos.",
        )

    # Eliminar duplicados sin alterar el orden.
    modality_ids = list(dict.fromkeys(modality_ids))

    # Verificar que todas las modalidades existan y estén activas.
    if modality_ids:
        active_ids = set(
            db.scalars(
                select(PaymentMethod.id_modalidad).where(
                    PaymentMethod.id_modalidad.in_(modality_ids),
                    PaymentMethod.estado.is_(True),
                )
            ).all()
        )

        invalid_ids = set(modality_ids) - active_ids

        if invalid_ids:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "Una o más modalidades no existen o están inactivas: "
                    + ", ".join(map(str, sorted(invalid_ids)))
                ),
            )

    # Deshabilitar las asociaciones anteriores.
    existing = db.scalars(
        select(BusinessPaymentMethod).where(
            BusinessPaymentMethod.id_negocio == business.id_negocio
        )
    ).all()

    existing_by_id = {
        item.id_modalidad: item
        for item in existing
    }

    for item in existing:
        item.habilitada = item.id_modalidad in modality_ids

    # Crear las asociaciones que todavía no existen.
    for modality_id in modality_ids:
        if modality_id not in existing_by_id:
            db.add(
                BusinessPaymentMethod(
                    id_negocio=business.id_negocio,
                    id_modalidad=modality_id,
                    habilitada=True,
                )
            )

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No fue posible guardar las modalidades de pago.",
        )

    return {
        "modalidad_ids": [str(value) for value in modality_ids]
    }
