from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Category


router = APIRouter(prefix="/categorias", tags=["Categorías"])


@router.get("")
def listar_categorias(db: Session = Depends(get_db)):
    categorias = db.scalars(
        select(Category)
        .where(Category.estado.is_(True))
        .order_by(Category.nombre.asc())
    ).all()

    return {
        "items": [
            {
                "id_categoria": categoria.id_categoria,
                "nombre": categoria.nombre,
            }
            for categoria in categorias
        ]
    }
