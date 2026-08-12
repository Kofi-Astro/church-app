FROM python:3.12-slim

WORKDIR /app

# System deps kept minimal on purpose — add only what a future feature
# genuinely needs (e.g. image processing libs), don't pre-install extras.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Runtime config (SUPABASE_URL, keys, etc.) is injected as environment
# variables by the hosting platform — never baked into the image.
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
