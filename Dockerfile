# Use a lightweight Python base image
FROM python:3.14-slim@sha256:2751cbe93751f0147bc1584be957c6dd4c5f977c3d4e0396b56456a9fd4ed137
COPY --from=ghcr.io/astral-sh/uv:0.9.17@sha256:5cb6b54d2bc3fe2eb9a8483db958a0b9eebf9edff68adedb369df8e7b98711a2 /uv /uvx /bin/

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
