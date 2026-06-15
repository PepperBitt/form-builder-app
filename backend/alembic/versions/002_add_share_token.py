"""Add share_token to forms

Revision ID: 002_share_token
Revises: 001_initial
Create Date: 2026-06-15
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002_share_token"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "forms",
        sa.Column("share_token", sa.String(), nullable=True),
    )
    op.create_index("ix_forms_share_token", "forms", ["share_token"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_forms_share_token", table_name="forms")
    op.drop_column("forms", "share_token")
