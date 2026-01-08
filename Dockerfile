# BioMCP Server
# Native HTTP transport via FastMCP

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Copy application files
COPY . /app/

# Install Python dependencies (without alphagenome for now)
RUN uv sync --no-dev

# Install alphagenome separately (optional genomics features)
RUN uv pip install git+https://github.com/google-deepmind/alphagenome.git || echo "AlphaGenome install failed, continuing without it"

# Expose port
EXPOSE 8000

# Health check - MCP streamable HTTP responds to POST with initialize
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sfL -X POST http://localhost:8000/mcp \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"healthcheck","version":"1.0"}}}' \
        | grep -q "protocolVersion" || exit 1

# Run the MCP server in streamable HTTP mode
CMD ["uv", "run", "biomcp", "run", "--mode", "streamable_http"]
