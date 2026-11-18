
from sqlalchemy import BigInteger, Boolean, DateTime, Enum, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class User(Base):
    __tablename__ = "usuarios"

    id_usuario: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True
    )
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    apellido: Mapped[str] = mapped_column(String(100), nullable=False)
    correo: Mapped[str] = mapped_column(String(150), nullable=False, unique=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    telefono: Mapped[str | None] = mapped_column(String(20), nullable=True)

    rol: Mapped[str | None] = mapped_column(
        Enum("USUARIO", "NEGOCIO", "ADMIN", name="rol"),
        nullable=True,
        default=None,
    )

    estado: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("1")
    )
    fecha_registro: Mapped[object] = mapped_column(
        DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    fecha_actualizacion: Mapped[object] = mapped_column(
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
        BigInteger,
        nullable=True,
    )

    fecha_suspension: Mapped[object | None] = mapped_column(
        DateTime,
        nullable=True,
    )
