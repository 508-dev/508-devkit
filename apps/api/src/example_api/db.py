from __future__ import annotations

from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

metadata = MetaData()


class Base(DeclarativeBase):
    metadata = metadata
