"""
Worker test fixtures.

Sets up environment so worker modules can be imported safely.
"""

import os
import sys
from pathlib import Path

# ---- path setup ----
ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "worker"))

# ---- mock env vars ----
_MOCK_ENV = {
    "POSTGRESQL_HOST": "localhost",
    "POSTGRESQL_PORT": "5432",
    "POSTGRESQL_USER": "test",
    "POSTGRESQL_PASSWORD": "test",
    "POSTGRESQL_DBNAME": "test",
    "S3_ENDPOINT_URL": "https://s3.test",
    "S3_ACCESS_KEY_ID": "test",
    "S3_SECRET_ACCESS_KEY": "test",
    "S3_BUCKET": "test-bucket",
    "STORAGE_PUBLIC_URL": "https://cdn.test",
    "OPENAI_API_KEY": "sk-test",
    "LEONARDO_API_KEY": "leo-test",
    "REDIS_URL": "redis://localhost:6379",
    "JWT_SECRET": "test-secret-key-for-testing-only-32chars!",
}

for k, v in _MOCK_ENV.items():
    os.environ.setdefault(k, v)
