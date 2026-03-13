import boto3
from botocore.client import Config
from app.config import get_settings


class S3Service:
    def __init__(self):
        settings = get_settings()
        self.client = boto3.client(
            's3',
            endpoint_url=settings.S3_ENDPOINT_URL,
            aws_access_key_id=settings.S3_ACCESS_KEY_ID,
            aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
            config=Config(signature_version='s3v4'),
            region_name='ru-1',
        )
        self.bucket = settings.S3_BUCKET
        self.public_url = settings.STORAGE_PUBLIC_URL

    def upload_file(self, key: str, data: bytes, content_type: str = 'image/jpeg') -> str:
        """Upload file to S3 and return public URL."""
        self.client.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=data,
            ContentType=content_type,
            ACL='public-read',
        )
        return f"{self.public_url}/{key}"

    def delete_file(self, key: str) -> None:
        """Delete a file from S3."""
        self.client.delete_object(Bucket=self.bucket, Key=key)

    def delete_prefix(self, prefix: str) -> None:
        """Delete all files with given prefix."""
        response = self.client.list_objects_v2(Bucket=self.bucket, Prefix=prefix)
        if 'Contents' in response:
            objects = [{'Key': obj['Key']} for obj in response['Contents']]
            self.client.delete_objects(
                Bucket=self.bucket,
                Delete={'Objects': objects},
            )


# ---------------------------------------------------------------------------
# Lazy singleton – avoids initialisation at import time so the module can be
# imported safely even when S3 env-vars are not yet configured (e.g. during
# tests or when running unrelated CLI commands).
# ---------------------------------------------------------------------------
_s3_service: S3Service | None = None


def get_s3_service() -> S3Service:
    """Return the shared S3Service instance, creating it on first call."""
    global _s3_service
    if _s3_service is None:
        _s3_service = S3Service()
    return _s3_service
