from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Business, Category, Product, User
from app.routers.auth import get_current_user
from app.schemas.product import (
    ProductCreateRequest,
    ProductUpdateRequest,
    ProductResponse,
    ProductListResponse,
)


router = APIRouter(prefix="/productos", tags=["Productos"])


def obtener_negocio_usuario(
    current_user: User,
    db: Session,
    exigir_activo: bool = False,
):
    negocio = db.scalar(
        select(Business).where(
            Business.id_usuario == current_user.id_usuario
        )
    )

    if negocio is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes un negocio registrado.",
        )

    if exigir_activo and not negocio.estado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu negocio está suspendido. No puedes realizar esta operación.",
        )

    return negocio


def obtener_producto_propio(
    id_producto: int,
    id_negocio: int,
    db: Session,
):
    producto = db.scalar(
        select(Product).where(
            Product.id_producto == id_producto,
            Product.id_negocio == id_negocio,
        )
    )

    if producto is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Producto no encontrado.",
        )

    return producto


@router.get(
    "/mio",
    response_model=ProductListResponse,
)
def listar_mis_productos(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Se permite consultar los productos aunque el negocio esté suspendido.
    negocio = obtener_negocio_usuario(current_user, db)

    productos = db.scalars(
        select(Product)
        .where(
            Product.id_negocio == negocio.id_negocio,
            Product.estado.is_(True),
        )
        .order_by(Product.id_producto.desc())
    ).all()

    return {"items": productos}


@router.post(
    "",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
)
def crear_producto(
    data: ProductCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Solo los negocios activos pueden publicar productos.
    negocio = obtener_negocio_usuario(
        current_user,
        db,
        exigir_activo=True,
    )

    categoria = db.get(Category, data.id_categoria)

    if categoria is None or not categoria.estado:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="La categoría no existe o está inactiva.",
        )

    producto = Product(
        id_negocio=negocio.id_negocio,
        id_categoria=data.id_categoria,
        nombre=data.nombre,
        descripcion=data.descripcion,
        tipo=data.tipo,
        precio=data.precio,
        imagen_url=data.imagen_url,
        stock=data.stock,
        disponible=data.disponible,
        estado=True,
    )

    try:
        db.add(producto)
        db.commit()
        db.refresh(producto)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No se pudo crear el producto con los datos proporcionados.",
        )

    return producto


@router.patch(
    "/{id_producto}",
    response_model=ProductResponse,
)
def actualizar_producto(
    id_producto: int,
    data: ProductUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Los negocios suspendidos no pueden modificar sus productos.
    negocio = obtener_negocio_usuario(
        current_user,
        db,
        exigir_activo=True,
    )

    producto = obtener_producto_propio(
        id_producto,
        negocio.id_negocio,
        db,
    )

    cambios = data.model_dump(exclude_unset=True)

    if "id_categoria" in cambios:
        categoria = db.get(Category, cambios["id_categoria"])

        if categoria is None or not categoria.estado:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="La categoría no existe o está inactiva.",
            )

    for campo, valor in cambios.items():
        setattr(producto, campo, valor)

    try:
        db.commit()
        db.refresh(producto)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No se pudieron actualizar los datos del producto.",
        )

    return producto


@router.delete(
    "/{id_producto}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def eliminar_producto(
    id_producto: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Se permite retirar productos incluso si el negocio está suspendido.
    negocio = obtener_negocio_usuario(current_user, db)

    producto = obtener_producto_propio(
        id_producto,
        negocio.id_negocio,
        db,
    )

    # Eliminación lógica: conserva el registro y sus relaciones.
    producto.estado = False

    db.commit()

    return None
