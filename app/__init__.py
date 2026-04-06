"""Compatibility package for running the backend from the repository root.

This makes ``app.main`` resolve to ``backend/app/main.py`` when commands like
``python -m uvicorn app.main:app --reload`` are executed from the project root.
"""

from pathlib import Path


_BACKEND_APP_DIR = Path(__file__).resolve().parent.parent / "backend" / "app"

# Point this package at the real backend application modules.
__path__ = [str(_BACKEND_APP_DIR)]
