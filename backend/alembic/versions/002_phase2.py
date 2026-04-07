"""phase2 tables: wallet, transaction, payment, admin_user; extend clubs/bookings

Revision ID: 002
Revises: 001
Create Date: 2026-04-07 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Extend clubs ──────────────────────────────────────────────────────────
    op.add_column("clubs", sa.Column("latitude", sa.Numeric(10, 7), nullable=True))
    op.add_column("clubs", sa.Column("longitude", sa.Numeric(10, 7), nullable=True))
    op.add_column("clubs", sa.Column("address", sa.Text(), nullable=True))

    # ── Wallets ───────────────────────────────────────────────────────────────
    op.create_table(
        "wallets",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("balance", sa.Numeric(12, 2), nullable=False, server_default="0.00"),
        sa.Column("currency", sa.String(length=3), nullable=False, server_default="UZS"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(op.f("ix_wallets_id"), "wallets", ["id"], unique=False)
    op.create_index(op.f("ix_wallets_user_id"), "wallets", ["user_id"], unique=True)

    # ── Transactions ──────────────────────────────────────────────────────────
    op.create_table(
        "transactions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("wallet_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("booking_id", sa.Integer(), nullable=True),
        sa.Column(
            "type",
            sa.Enum(
                "TOP_UP", "BOOKING_PAYMENT", "REFUND", "ADMIN_ADJUSTMENT",
                name="transactiontype",
            ),
            nullable=False,
        ),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("balance_before", sa.Numeric(12, 2), nullable=False),
        sa.Column("balance_after", sa.Numeric(12, 2), nullable=False),
        sa.Column(
            "status",
            sa.Enum("PENDING", "COMPLETED", "FAILED", "REVERSED", name="transactionstatus"),
            nullable=False,
            server_default="COMPLETED",
        ),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("reference_code", sa.String(length=32), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["wallet_id"], ["wallets.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_transactions_id"), "transactions", ["id"], unique=False)
    op.create_index(op.f("ix_transactions_wallet_id"), "transactions", ["wallet_id"], unique=False)
    op.create_index(op.f("ix_transactions_user_id"), "transactions", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_transactions_reference_code"), "transactions", ["reference_code"], unique=True
    )

    # ── Payments ──────────────────────────────────────────────────────────────
    op.create_table(
        "payments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("booking_id", sa.Integer(), nullable=False),
        sa.Column("transaction_id", sa.Integer(), nullable=True),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column(
            "method",
            sa.Enum("WALLET", "CARD", "CASH", name="paymentmethod"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.Enum("PENDING", "COMPLETED", "FAILED", "REFUNDED", name="paymentstatus"),
            nullable=False,
            server_default="PENDING",
        ),
        sa.Column("validated_by", sa.Integer(), nullable=True),
        sa.Column("validated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"]),
        sa.ForeignKeyConstraint(["transaction_id"], ["transactions.id"]),
        sa.ForeignKeyConstraint(["validated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_payments_id"), "payments", ["id"], unique=False)
    op.create_index(op.f("ix_payments_user_id"), "payments", ["user_id"], unique=False)
    op.create_index(op.f("ix_payments_booking_id"), "payments", ["booking_id"], unique=False)

    # ── Extend bookings ───────────────────────────────────────────────────────
    # Use batch mode so SQLite handles the copy-and-move internally
    with op.batch_alter_table("bookings", recreate="always") as batch_op:
        batch_op.add_column(sa.Column("payment_id", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("total_price", sa.Numeric(12, 2), nullable=True))
        batch_op.add_column(sa.Column("slot_details", sa.JSON(), nullable=True))
        batch_op.create_foreign_key(
            "fk_bookings_payment_id", "payments", ["payment_id"], ["id"]
        )

    # ── Admin users ───────────────────────────────────────────────────────────
    op.create_table(
        "admin_users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column(
            "role",
            sa.Enum("SUPER_ADMIN", "CLUB_ADMIN", "MODERATOR", name="adminrole"),
            nullable=False,
        ),
        sa.Column("club_id", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["club_id"], ["clubs.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(op.f("ix_admin_users_id"), "admin_users", ["id"], unique=False)
    op.create_index(op.f("ix_admin_users_user_id"), "admin_users", ["user_id"], unique=True)


def downgrade() -> None:
    op.drop_table("admin_users")
    with op.batch_alter_table("bookings", recreate="always") as batch_op:
        batch_op.drop_constraint("fk_bookings_payment_id", type_="foreignkey")
        batch_op.drop_column("slot_details")
        batch_op.drop_column("total_price")
        batch_op.drop_column("payment_id")
    op.drop_table("payments")
    op.drop_table("transactions")
    op.drop_table("wallets")
    op.drop_column("clubs", "address")
    op.drop_column("clubs", "longitude")
    op.drop_column("clubs", "latitude")
