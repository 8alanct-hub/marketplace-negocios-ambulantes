
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict


class BusinessCreateRequest(BaseModel):
    tipo: Literal["FIJO", "AMBULANTE"]


class BusinessResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_negocio: int
    id_usuario: int
    tipo: str
    nombre_comercial: str
    descripcion: str | None
    telefono: str | None
    direccion: str
    latitud: Decimal | None
    longitud: Decimal | None
    ubicacion_actualizada: datetime | None
    logo_url: str | None
    banner_url: str | None
    estado: bool
    fecha_registro: datetime
    fecha_actualizacion: datetime


from pydantic import Field, field_validator, model_validator


class BusinessUpdateRequest(BaseModel):
    nombre_comercial: str | None = Field(default=None, max_length=150)
    descripcion: str | None = None
    telefono: str | None = Field(default=None, max_length=20)
    direccion: str | None = Field(default=None, max_length=255)
    tipo: Literal["FIJO", "AMBULANTE"] | None = None

    latitud: Decimal | None = Field(
        default=None,
        ge=-90,
        le=90,
        max_digits=10,
        decimal_places=7,
    )

    longitud: Decimal | None = Field(
        default=None,
        ge=-180,
        le=180,
        max_digits=10,
        decimal_places=7,
    )

    logo_url: str | None = Field(default=None, max_length=500)
    banner_url: str | None = Field(default=None, max_length=500)

    @field_validator(
        "nombre_comercial",
        "descripcion",
        "telefono",
        "direccion",
    )
    @classmethod
    def strip_text(cls, value):
        if value is not None:
            return value.strip()
        return value

    @model_validator(mode="after")
    def validate_coordinates(self):
        if (self.latitud is None) != (self.longitud is None):
            raise ValueError(
                "La latitud y longitud deben proporcionarse juntas."
            )
        return self

class BusinessListResponse(BaseModel):
    items: list[BusinessResponse]
