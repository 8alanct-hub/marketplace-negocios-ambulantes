# Módulo de autenticación

## Instalar dependencias

```bash
pip install -r requirements.txt
```

## Variables de entorno

Añade a `.env`:
- `JWT_SECRET_KEY`: secreto aleatorio largo, generado localmente.
- `JWT_ALGORITHM=HS256`
- `ACCESS_TOKEN_EXPIRE_MINUTES=60`

Genera una clave con:
```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Copia el resultado en `JWT_SECRET_KEY`. No lo compartas ni lo subas a Git.

## Ejecutar

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Endpoints

- `POST /auth/register`: crea cuenta con rol `USUARIO` o `NEGOCIO`. Nunca permite registrar `ADMIN` públicamente.
- `POST /auth/login`: recibe correo y contraseña y devuelve JWT.
- `GET /auth/me`: requiere `Authorization: Bearer <token>`.

No se crean ni alteran tablas. El modelo `User` mapea la tabla existente `usuarios`.
