"""admin_features

Revision ID: 003
Revises: 002
Create Date: 2026-04-07
"""
from alembic import op
import sqlalchemy as sa

revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # User approval workflow: existing users are approved by default (server_default=true)
    op.add_column(
        "users",
        sa.Column(
            "is_approved",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
    )
    # Club description field
    op.add_column(
        "clubs",
        sa.Column("description", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("clubs", "description")
    op.drop_column("users", "is_approved")
