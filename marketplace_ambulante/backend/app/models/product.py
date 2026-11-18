from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.mysql import BIGINT, INTEGER
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Product(Base):
    __tablename__ = "productos"

    id_producto: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        primary_key=True,
        autoincrement=True,
    )

    id_negocio: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("negocios.id_negocio", ondelete="RESTRICT", onupdate="CASCADE"),
        nullable=False,
        index=True,
    )

    id_categoria: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("categorias.id_categoria", ondelete="RESTRICT", onupdate="CASCADE"),
        nullable=False,
        index=True,
    )

    nombre: Mapped[str] = mapped_column(
        String(150), nullable=False
    )

    descripcion: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )

    tipo: Mapped[str] = mapped_column(
        Enum("PRODUCTO", "SERVICIO", name="tipo_producto"),
        nullable=False,
    )

    precio: Mapped[object] = mapped_column(
        Numeric(12, 2), nullable=False
    )

    imagen_url: Mapped[str | None] = mapped_column(
        String(500), nullable=True
    )

    stock: Mapped[int | None] = mapped_column(
        INTEGER(unsigned=True), nullable=True
    )

    disponible: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("1")
    )

    estado: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("1")
    )

    fecha_creacion: Mapped[object] = mapped_column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )

    fecha_actualizacion: Mapped[object] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        server_onupdate=text("CURRENT_TIMESTAMP"),
    )
