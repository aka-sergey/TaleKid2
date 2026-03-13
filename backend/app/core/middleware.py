import logging
import time
from uuid import uuid4

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("talekid")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware that logs every incoming request and its duration."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = str(uuid4())[:8]
        start_time = time.perf_counter()

        logger.info(
            "[%s] --> %s %s",
            request_id,
            request.method,
            request.url.path,
        )

        try:
            response = await call_next(request)
        except Exception:
            logger.exception("[%s] Unhandled exception", request_id)
            raise

        elapsed_ms = (time.perf_counter() - start_time) * 1000
        logger.info(
            "[%s] <-- %s %s [%d] %.1fms",
            request_id,
            request.method,
            request.url.path,
            response.status_code,
            elapsed_ms,
        )

        response.headers["X-Request-ID"] = request_id
        return response
