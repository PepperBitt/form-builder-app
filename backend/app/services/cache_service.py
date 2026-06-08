import json
import os
from typing import Optional

import redis

from app.core.config import get_settings

settings = get_settings()

try:
    redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
except redis.RedisError:
    redis_client = None


def invalidate_form_cache(form_id: str) -> None:
    if redis_client is None:
        return
    try:
        redis_client.delete(f"form:{form_id}")
    except redis.RedisError:
        pass


def get_cached_form(form_id: str) -> Optional[dict]:
    if redis_client is None:
        return None
    try:
        cached = redis_client.get(f"form:{form_id}")
        if cached:
            return json.loads(cached)
    except redis.RedisError:
        pass
    return None


def set_cached_form(form_id: str, form_data: dict, ttl: int = 3600) -> None:
    if redis_client is None:
        return
    try:
        redis_client.setex(f"form:{form_id}", ttl, json.dumps(form_data, default=str))
    except redis.RedisError:
        pass
