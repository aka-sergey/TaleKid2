#!/usr/bin/env python3
"""
Set CORS configuration on the TimeWeb S3 bucket so that Flutter Web
(CanvasKit renderer) can load images cross-origin.
"""

import os
import sys
from pathlib import Path


def load_env_file(path: str) -> None:
    """Simple .env file loader (no python-dotenv needed)."""
    env_path = Path(path)
    if not env_path.exists():
        print(f"Warning: {path} not found", file=sys.stderr)
        return
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("'\"")
            os.environ.setdefault(key, value)


# Load .env from project root
env_file = Path(__file__).resolve().parent.parent / ".env"
load_env_file(str(env_file))

import boto3
from botocore.client import Config

endpoint = os.environ["S3_ENDPOINT_URL"]
access_key = os.environ["S3_ACCESS_KEY_ID"]
secret_key = os.environ["S3_SECRET_ACCESS_KEY"]
bucket = os.environ["S3_BUCKET"]

client = boto3.client(
    "s3",
    endpoint_url=endpoint,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
    config=Config(signature_version="s3v4"),
    region_name="ru-1",
)

cors_config = {
    "CORSRules": [
        {
            "AllowedOrigins": [
                "https://talekid2-production.up.railway.app",
                "https://talekid.ai",
                "https://www.talekid.ai",
                "http://localhost:*",
                "http://127.0.0.1:*",
            ],
            "AllowedMethods": ["GET", "HEAD"],
            "AllowedHeaders": ["*"],
            "MaxAgeSeconds": 86400,  # cache preflight for 24h
        },
    ]
}

print(f"Setting CORS on bucket: {bucket}")
print(f"Endpoint: {endpoint}")
print(f"CORS config: {cors_config}")

try:
    client.put_bucket_cors(Bucket=bucket, CORSConfiguration=cors_config)
    print("\n✅ CORS configuration set successfully!")

    # Verify
    response = client.get_bucket_cors(Bucket=bucket)
    print(f"\nVerification — current CORS rules:")
    for rule in response.get("CORSRules", []):
        print(f"  Origins: {rule.get('AllowedOrigins')}")
        print(f"  Methods: {rule.get('AllowedMethods')}")
        print(f"  Headers: {rule.get('AllowedHeaders')}")
        print(f"  MaxAge:  {rule.get('MaxAgeSeconds')}")
except Exception as e:
    print(f"\n❌ Error setting CORS: {e}", file=sys.stderr)
    sys.exit(1)
