
from pydantic import BaseModel, Field


class PaymentMethodResponse(BaseModel):
    id: str
    nombre: str
    descripcion: str


class PaymentMethodListResponse(BaseModel):
    items: list[PaymentMethodResponse]


class BusinessPaymentMethodsResponse(BaseModel):
    modalidad_ids: list[str]


class BusinessPaymentMethodsUpdateRequest(BaseModel):
    modalidad_ids: list[str] = Field(default_factory=list)
