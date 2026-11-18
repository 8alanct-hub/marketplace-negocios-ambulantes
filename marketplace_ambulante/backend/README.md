# Marketplace Ambulante API

Base inicial de FastAPI para conectarse a la base de datos existente `ecosistema_negocios`.

## Preparación

1. Crear y activar un entorno virtual.
2. Instalar dependencias: `pip install -r requirements.txt`
3. Copiar `.env.example` a `.env` y completar la contraseña.
4. Iniciar: `uvicorn app.main:app --reload --host 127.0.0.1 --port 8000`

## Comprobaciones

- `GET /`
- `GET /health`
- `GET /health/db`
- Documentación: `/docs`

La aplicación no crea ni modifica tablas automáticamente.
