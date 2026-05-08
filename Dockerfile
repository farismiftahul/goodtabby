# Production Dockerfile for Render deployment
# Provides both Python and Node.js in a single image

# --- Stage 1: Build ---
FROM python:3.12-slim AS builder

SHELL ["/bin/bash", "--login", "-c"]

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 via nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install 18 \
    && nvm alias default 18 \
    && nvm use default

# Make node/npm available in PATH for subsequent RUN commands
ENV PATH="/root/.nvm/versions/node/v18/bin:${PATH}"

WORKDIR /app
COPY . /app/

# Set ON_RENDER during build so Django loads render.py settings
ENV ON_RENDER=1

# Install Python dependencies
RUN pip install --upgrade pip \
    && pip install pipenv \
    && pipenv install --system --deploy

# Install Node dependencies and build frontend
RUN npm ci && npm run build

# Collect static files
RUN python manage.py collectstatic --noinput -v 0

# --- Stage 2: Runtime ---
FROM python:3.12-slim

SHELL ["/bin/bash", "--login", "-c"]

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 (needed at runtime for npm-run-all)
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install 18 \
    && nvm alias default 18 \
    && nvm use default

ENV PATH="/root/.nvm/versions/node/v18/bin:${PATH}"

WORKDIR /app

# Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code and built assets from builder
COPY --from=builder /app /app

# Install npm-run-all at runtime (needed for render-serve script)
RUN npm install --omit=dev npm-run-all

# Render settings: ensure render.py is loaded (not docker.py)
ENV ON_RENDER=1
ENV IN_DOCKER=0
ENV USING_NGINX=0

# Render provides PORT env var (default 10000)
ENV PORT=10000
EXPOSE ${PORT}

# Run migrations then start the server
CMD ["bash", "-lc", "cd tabbycat && python ../manage.py migrate --noinput && cd /app && npm run render-serve"]
