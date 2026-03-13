"""Text processing utilities for the worker."""

import re


def truncate(text: str, max_length: int = 500) -> str:
    """Truncate text to max_length, appending '...' if needed."""
    if len(text) <= max_length:
        return text
    return text[: max_length - 3] + "..."


def clean_json_string(raw: str) -> str:
    """
    Extract JSON from a response that may contain markdown code fences
    or other non-JSON content.
    """
    # Try to extract JSON from markdown code fences
    match = re.search(r"```(?:json)?\s*\n?([\s\S]*?)\n?```", raw)
    if match:
        return match.group(1).strip()

    # Try to find JSON object or array
    for start_char, end_char in [("{", "}"), ("[", "]")]:
        start = raw.find(start_char)
        end = raw.rfind(end_char)
        if start != -1 and end != -1 and end > start:
            return raw[start : end + 1]

    return raw.strip()


def estimate_reading_time_minutes(text: str, wpm: int = 100) -> float:
    """Estimate reading time in minutes for Russian text."""
    words = len(text.split())
    return words / wpm
