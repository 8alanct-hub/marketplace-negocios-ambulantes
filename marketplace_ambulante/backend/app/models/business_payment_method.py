
from sqlalchemy import Boolean, ForeignKey, text
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class BusinessPaymentMethod(Base):
    __tablename__ = "negocio_modalidad_pago"

    id_negocio: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey(
            "negocios.id_negocio",
            ondelete="RESTRICT",
            onupdate="CASCADE",
        ),
        primary_key=True,
    )

    id_modalidad: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey(
            "modalidades_pago.id_modalidad",
            ondelete="RESTRICT",
            onupdate="CASCADE",
        ),
        primary_key=True,
    )

    habilitada: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        server_default=text("1"),
    )
