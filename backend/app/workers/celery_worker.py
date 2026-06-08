import os
from celery import Celery

# Use Redis as the broker (make sure you have Redis installed/running on your machine or cloud)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    "worker",
    broker=REDIS_URL,
    backend=REDIS_URL
)

celery_app.conf.update(task_track_started=True)