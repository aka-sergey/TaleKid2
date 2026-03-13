import logging

import boto3
from botocore.config import Config as BotoConfig

from app.config import get_settings

logger = logging.getLogger("worker.s3")


class S3Service:
    def __init__(self):
        settings = get_settings()
        self._client = boto3.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            aws_access_key_id=settings.S3_ACCESS_KEY_ID,
            aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
            region_name="ru-1",
            config=BotoConfig(signature_version="s3v4"),
        )
        self._bucket = settings.S3_BUCKET
        self._public_url = settings.STORAGE_PUBLIC_URL

    def upload_bytes(self, key: str, data: bytes, content_type: str = "image/png") -> str:
        """Upload bytes to S3 and return public URL."""
        self._client.put_object(
            Bucket=self._bucket,
            Key=key,
            Body=data,
            ContentType=content_type,
            ACL="public-read",
        )
        url = f"{self._public_url}/{self._bucket}/{key}"
        logger.info("Uploaded to S3: %s", key)
        return url

    def delete_prefix(self, prefix: str):
        """Delete all objects with the given prefix."""
        response = self._client.list_objects_v2(Bucket=self._bucket, Prefix=prefix)
        for obj in response.get("Contents", []):
            self._client.delete_object(Bucket=self._bucket, Key=obj["Key"])
