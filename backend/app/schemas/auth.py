from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator
import re


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    phone: str | None = Field(default=None, max_length=30)

    @field_validator("username")
    @classmethod
    def username_alphanumeric(cls, v: str) -> str:
        if not re.match(r"^[a-zA-Z0-9_]+$", v):
            raise ValueError("Username must contain only letters, numbers, and underscores")
        return v

    @field_validator("phone")
    @classmethod
    def phone_format(cls, v: str | None) -> str | None:
        if v is not None and not re.match(r"^\+?[\d\s\-()]{7,30}$", v):
            raise ValueError("Invalid phone number format")
        return v


class LoginRequest(BaseModel):
    username: str | None = Field(default=None, min_length=1, max_length=100)
    email: EmailStr | None = None
    password: str = Field(min_length=1, max_length=128)

    @model_validator(mode="after")
    def validate_identifier(self) -> "LoginRequest":
        if not self.username and not self.email:
            raise ValueError("Either username or email is required")
        return self


class RefreshRequest(BaseModel):
    refresh_token: str | None = None
    refresh: str | None = None

    @model_validator(mode="after")
    def validate_refresh_token(self) -> "RefreshRequest":
        if not self.refresh_token and not self.refresh:
            raise ValueError("Refresh token is required")
        return self

    @property
    def token(self) -> str:
        return self.refresh_token or self.refresh or ""


_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    phone: str | None
    total_bookings: int = 0
    joined_at: str | None = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    access: str
    refresh: str
    user: UserResponse
