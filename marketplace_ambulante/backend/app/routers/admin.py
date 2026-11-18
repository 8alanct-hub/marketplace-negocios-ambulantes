
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    verify_password,
)
from app.database import get_db
from app.models import Business, User
from app.routers.auth import get_current_user


router = APIRouter(prefix="/admin", tags=["Administración"])


class AdminLoginRequest(BaseModel):
    correo: EmailStr
    clave: str


class CambioEstadoRequest(BaseModel):
    estado: str
    motivo: str | None = Field(default=None, max_length=255)


def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.rol != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos de administrador.",
        )

    return current_user


def fecha_formateada(fecha):
    if fecha is None:
        return ""

    return fecha.strftime("%d/%m/%Y")


def obtener_id_prefijado(valor: str, prefijo: str) -> int:
    if not valor.startswith(prefijo):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro no encontrado.",
        )

    try:
        identificador = int(valor[len(prefijo):])
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro no encontrado.",
        )

    if identificador <= 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro no encontrado.",
        )

    return identificador


def datos_suspension(fecha, motivo, suspendido_por, db):
    if fecha is None:
        return {
            "motivo": "",
            "cuando": "",
        }

    administrador = (
        db.get(User, suspendido_por)
        if suspendido_por is not None
        else None
    )

    nombre_admin = (
        f"{administrador.nombre} {administrador.apellido}"
        if administrador
        else "Administrador"
    )

    return {
        "motivo": motivo or "",
        "cuando": f"{fecha_formateada(fecha)} · por {nombre_admin}",
    }


@router.post("/login")
def admin_login(
    data: AdminLoginRequest,
    db: Session = Depends(get_db),
):
    correo = str(data.correo).strip().lower()

    user = db.scalar(
        select(User).where(User.correo == correo)
    )

    if (
        user is None
        or not user.estado
        or user.rol != "ADMIN"
        or not verify_password(data.clave, user.password_hash)
    ):
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"mensaje": "Correo o contraseña incorrectos."},
        )

    token = create_access_token(str(user.id_usuario))

    return {
        "nombre": f"{user.nombre} {user.apellido}",
        "correo": user.correo,
        "token": token,
    }


@router.get("/usuarios")
def listar_usuarios(
    admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    resultado = db.execute(
        select(User, Business)
        .outerjoin(
            Business,
            Business.id_usuario == User.id_usuario,
        )
        .where(User.rol != "ADMIN")
        .order_by(User.fecha_registro.desc())
    ).all()

    usuarios = []

    for user, business in resultado:
        suspension = datos_suspension(
            user.fecha_suspension,
            user.motivo_suspension,
            user.suspendido_por,
            db,
        )

        usuarios.append({
            "id": f"u_{user.id_usuario}",
            "nombre": f"{user.nombre} {user.apellido}",
            "correo": user.correo,
            "telefono": user.telefono or "",
            "rol": "Negocio" if user.rol == "NEGOCIO" else "Cliente",
            "registro": fecha_formateada(user.fecha_registro),
            "estado": "Activo" if user.estado else "Suspendido",
            "negocioId": (
                f"n_{business.id_negocio}"
                if business else None
            ),
            "motivo": suspension["motivo"],
            "cuando": suspension["cuando"],
        })

    return usuarios


@router.get("/negocios")
def listar_negocios(
    admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    resultado = db.execute(
        select(Business, User)
        .join(User, User.id_usuario == Business.id_usuario)
        .order_by(Business.fecha_registro.desc())
    ).all()

    negocios = []

    for business, user in resultado:
        if business.tipo == "FIJO":
            lugar = business.direccion or "Sin dirección"
        elif business.ubicacion_actualizada:
            lugar = "Ubicación actualizada"
        else:
            lugar = "Sin ubicación registrada"

        suspension = datos_suspension(
            business.fecha_suspension,
            business.motivo_suspension,
            business.suspendido_por,
            db,
        )

        negocios.append({
            "id": f"n_{business.id_negocio}",
            "nombre": business.nombre_comercial or "Negocio sin nombre",
            "tipo": business.tipo.lower(),
            "descripcion": business.descripcion or "",
            "duenoId": f"u_{user.id_usuario}",
            "lugar": lugar,
            "registro": fecha_formateada(business.fecha_registro),
            "estado": "Activo" if business.estado else "Suspendido",
            "motivo": suspension["motivo"],
            "cuando": suspension["cuando"],
        })

    return negocios


@router.patch("/usuarios/{usuario_id}")
def cambiar_estado_usuario(
    usuario_id: str,
    data: CambioEstadoRequest,
    admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    id_real = obtener_id_prefijado(usuario_id, "u_")

    usuario = db.get(User, id_real)

    if usuario is None or usuario.rol == "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado.",
        )

    if data.estado not in ("Activo", "Suspendido"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El estado debe ser Activo o Suspendido.",
        )

    if data.estado == "Suspendido":
        motivo = (data.motivo or "").strip()

        if not motivo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Debes indicar un motivo de suspensión.",
            )

        usuario.estado = False
        usuario.motivo_suspension = motivo
        usuario.suspendido_por = admin.id_usuario
        usuario.fecha_suspension = datetime.now()

        mensaje = "Usuario suspendido correctamente."

    else:
        usuario.estado = True
        usuario.motivo_suspension = None
        usuario.suspendido_por = None
        usuario.fecha_suspension = None

        mensaje = "Usuario reactivado correctamente."

    db.commit()
    db.refresh(usuario)

    return {
        "mensaje": mensaje,
        "id": f"u_{usuario.id_usuario}",
        "estado": data.estado,
    }


@router.patch("/negocios/{negocio_id}")
def cambiar_estado_negocio(
    negocio_id: str,
    data: CambioEstadoRequest,
    admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    id_real = obtener_id_prefijado(negocio_id, "n_")

    negocio = db.get(Business, id_real)

    if negocio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Negocio no encontrado.",
        )

    if data.estado not in ("Activo", "Suspendido"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El estado debe ser Activo o Suspendido.",
        )

    if data.estado == "Suspendido":
        motivo = (data.motivo or "").strip()

        if not motivo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Debes indicar un motivo de suspensión.",
            )

        negocio.estado = False
        negocio.motivo_suspension = motivo
        negocio.suspendido_por = admin.id_usuario
        negocio.fecha_suspension = datetime.now()

        mensaje = "Negocio suspendido correctamente."

    else:
        negocio.estado = True
        negocio.motivo_suspension = None
        negocio.suspendido_por = None
        negocio.fecha_suspension = None

        mensaje = "Negocio reactivado correctamente."

    db.commit()
    db.refresh(negocio)

    return {
        "mensaje": mensaje,
        "id": f"n_{negocio.id_negocio}",
        "estado": data.estado,
    }


@router.get("/reportes")
def listar_reportes(
    admin: User = Depends(get_current_admin),
):
    return []


@router.get("/moderacion")
def listar_moderacion(
    admin: User = Depends(get_current_admin),
):
    return []

