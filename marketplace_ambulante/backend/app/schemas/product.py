
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ProductCreateRequest(BaseModel):
    id_categoria: int = Field(gt=0)
    nombre: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    tipo: Literal["PRODUCTO", "SERVICIO"]
    precio: Decimal = Field(
        ge=0,
        max_digits=12,
        decimal_places=2,
    )
    imagen_url: str | None = Field(default=None, max_length=500)
    stock: int | None = Field(default=None, ge=0)
    disponible: bool = True

    @field_validator("nombre")
    @classmethod
    def validar_nombre(cls, value):
        value = value.strip()
        if not value:
            raise ValueError("El nombre no puede estar vacío.")
        return value

    @field_validator("descripcion")
    @classmethod
    def limpiar_descripcion(cls, value):
        return value.strip() if value is not None else value


class ProductUpdateRequest(BaseModel):
    id_categoria: int | None = Field(default=None, gt=0)
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    descripcion: str | None = None
    tipo: Literal["PRODUCTO", "SERVICIO"] | None = None
    precio: Decimal | None = Field(
        default=None,
        ge=0,
        max_digits=12,
        decimal_places=2,
    )
    imagen_url: str | None = Field(default=None, max_length=500)
    stock: int | None = Field(default=None, ge=0)
    disponible: bool | None = None

    @field_validator("nombre")
    @classmethod
    def validar_nombre(cls, value):
        if value is not None:
            value = value.strip()
            if not value:
                raise ValueError("El nombre no puede estar vacío.")
        return value

    @field_validator("descripcion")
    @classmethod
    def limpiar_descripcion(cls, value):
        return value.strip() if value is not None else value


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_producto: int
    id_negocio: int
    id_categoria: int
    nombre: str
    descripcion: str | None
    tipo: str
    precio: Decimal
    imagen_url: str | None
    stock: int | None
    disponible: bool
    estado: bool


class ProductListResponse(BaseModel):
    items: list[ProductResponse]
