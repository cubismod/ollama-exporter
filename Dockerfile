# Use a lightweight Python base image
FROM python:3.14-slim@sha256:fd2aff39e5a3ed23098108786a9966fb036fdeeedd487d5360e466bb2a84377b
COPY --from=ghcr.io/astral-sh/uv:0.9.16@sha256:ae9ff79d095a61faf534a882ad6378e8159d2ce322691153d68d2afac7422840 /uv /uvx /bin/

# Set working directory
WORKDIR /app

ENV UV_LINK_MODE=copy

ADD README.md pyproject.toml uv.lock ./

RUN uv venv

# Populate pip and uv caches and resolve wheels (no project install) using BuildKit cache mounts
# (requires BuildKit/Buildx in CI, which the workflow config already sets up)
RUN --mount=type=cache,target=/root/.cache/pip \
	--mount=type=cache,target=/root/.cache/uv \
	uv sync --link-mode=copy --frozen --no-install-project --no-dev

ADD . .

# Install the project (uses cached wheels from previous step) and verify lockfile
RUN --mount=type=cache,target=/root/.cache/pip \
	--mount=type=cache,target=/root/.cache/uv \
	uv sync --link-mode=copy --no-dev && uv lock --check

# Expose the metrics port
EXPOSE 8000

# Define runtime environment variable for Ollama host (can be overridden)
ENV OLLAMA_HOST="http://localhost:11434"

# Start the FastAPI app
CMD ["uvicorn", "ollama_exporter:app", "--host", "0.0.0.0", "--port", "8000"]
