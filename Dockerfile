# Use a lightweight Python base image
FROM python:3.14-slim@sha256:486b8092bfb12997e10d4920897213a06563449c951c5506c2a2cfaf591c599f
COPY --from=ghcr.io/astral-sh/uv:0.10.0@sha256:78a7ff97cd27b7124a5f3c2aefe146170793c56a1e03321dd31a289f6d82a04f /uv /uvx /bin/

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
