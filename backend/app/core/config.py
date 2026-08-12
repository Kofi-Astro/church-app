"""
Application settings.

All configuration is loaded from environment variables (populated from a
.env file in local development, and from real environment variables /
secrets in CI and in production hosting). Nothing sensitive is ever
hard-coded here — see .env.example for the full list of variables this
app expects.
"""
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # General
    app_name: str = "Church App API"
    environment: str = Field(default="dev", description="dev | staging | prod")
    log_level: str = Field(default="INFO")

    # Supabase (Postgres + Auth). Filled in once a Supabase project exists;
    # left blank-safe here so the app can still boot (e.g. for the health
    # check and CI) before those are configured.
    supabase_url: str = Field(default="")
    supabase_service_role_key: str = Field(default="")
    supabase_anon_key: str = Field(default="")

    # Paystack — intentionally not wired up until Phase 5. The setting is
    # declared now so the schema/config shape doesn't change later, but no
    # payment code reads this yet.
    paystack_secret_key: str = Field(default="")

    @property
    def is_production(self) -> bool:
        return self.environment == "prod"


@lru_cache
def get_settings() -> Settings:
    """Cached settings instance — reads the environment once per process."""
    return Settings()
