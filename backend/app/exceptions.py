from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from starlette.status import (
    HTTP_400_BAD_REQUEST,
    HTTP_401_UNAUTHORIZED,
    HTTP_403_FORBIDDEN,
    HTTP_404_NOT_FOUND,
    HTTP_409_CONFLICT,
    HTTP_422_UNPROCESSABLE_ENTITY,
    HTTP_500_INTERNAL_SERVER_ERROR,
)


class AppException(HTTPException):
    def __init__(self, status_code: int, error: str, code: str) -> None:
        super().__init__(status_code=status_code, detail={"error": error, "code": code})
        self.error = error
        self.code = code


class NotFoundError(AppException):
    def __init__(self, resource: str = "Resource") -> None:
        super().__init__(HTTP_404_NOT_FOUND, f"{resource} not found", "NOT_FOUND")


class UnauthorizedError(AppException):
    def __init__(self, message: str = "Authentication required") -> None:
        super().__init__(HTTP_401_UNAUTHORIZED, message, "UNAUTHORIZED")


class ForbiddenError(AppException):
    def __init__(self, message: str = "Access denied") -> None:
        super().__init__(HTTP_403_FORBIDDEN, message, "FORBIDDEN")


class ConflictError(AppException):
    def __init__(self, message: str = "Resource conflict") -> None:
        super().__init__(HTTP_409_CONFLICT, message, "CONFLICT")


class ValidationError(AppException):
    def __init__(self, message: str = "Validation failed") -> None:
        super().__init__(HTTP_400_BAD_REQUEST, message, "VALIDATION_ERROR")


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.error, "code": exc.code},
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    if isinstance(exc.detail, dict):
        return JSONResponse(status_code=exc.status_code, content=exc.detail)
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": str(exc.detail), "code": "HTTP_ERROR"},
    )


async def validation_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    from fastapi.exceptions import RequestValidationError

    errors = []
    if hasattr(exc, "errors"):
        for err in exc.errors():  # type: ignore[union-attr]
            loc = " -> ".join(str(l) for l in err.get("loc", []))
            errors.append(f"{loc}: {err.get('msg', 'invalid')}")
    message = "; ".join(errors) if errors else "Validation failed"
    return JSONResponse(
        status_code=HTTP_422_UNPROCESSABLE_ENTITY,
        content={"error": message, "code": "VALIDATION_ERROR"},
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        content={"error": "Internal server error", "code": "INTERNAL_ERROR"},
    )
