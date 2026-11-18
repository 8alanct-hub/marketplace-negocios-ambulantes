
from datetime import datetime
from decimal import Decimal

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
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Business(Base):
    __tablename__ = "negocios"

    id_negocio: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        primary_key=True,
        autoincrement=True,
    )

    id_usuario: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey(
            "usuarios.id_usuario",
            ondelete="RESTRICT",
            onupdate="CASCADE",
        ),
        nullable=False,
        unique=True,
    )

    tipo: Mapped[str] = mapped_column(
        Enum("FIJO", "AMBULANTE", name="tipo_negocio"),
        nullable=False,
        server_default=text("'FIJO'"),
    )

    nombre_comercial: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    descripcion: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    telefono: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    direccion: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    latitud: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 7),
        nullable=True,
    )

    longitud: Mapped[Decimal | None] = mapped_column(
        Numeric(10, 7),
        nullable=True,
    )

    ubicacion_actualizada: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    logo_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    banner_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    estado: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        server_default=text("1"),
    )

    fecha_registro: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )

    fecha_actualizacion: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        server_onupdate=text("CURRENT_TIMESTAMP"),
    )

    motivo_suspension: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    suspendido_por: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        nullable=True,
    )

    fecha_suspension: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )
