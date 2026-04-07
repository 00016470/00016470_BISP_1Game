from pathlib import Path
from pydantic_settings import BaseSettings
from functools import lru_cache

# Always load .env from the backend/ directory, regardless of working directory
_ENV_FILE = Path(__file__).parent.parent / ".env"


class Settings(BaseSettings):
    database_url: str = "sqlite+aiosqlite:///./gaming_club.db"
    secret_key: str = "insecure-dev-secret-change-in-production"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    allowed_origins: str = "http://localhost:3000,http://localhost:5173"
    rate_limit_per_minute: int = 100
    environment: str = "development"

    @property
    def async_database_url(self) -> str:
        """Convert DATABASE_URL to async driver format for Railway/Render."""
        url = self.database_url
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+asyncpg://", 1)
        elif url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return url

    @property
    def is_production(self) -> bool:
        return self.environment.lower() in ("production", "prod")

    @property
    def origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    model_config = {"env_file": str(_ENV_FILE), "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
