FROM node:18-bookworm # Or stick with node:18-buster if needed

WORKDIR /app

# Install system dependencies (if still needed for native modules)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Rollup dependency explicitly first (if still required)
RUN npm install --save-dev @rollup/rollup-linux-x64-gnu

# Copy package files and install dependencies
# This leverages Docker layer caching
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Generate Prisma Client
# Ensure schema is copied before this step (covered by COPY . .)
RUN npx prisma generate

# Build the application
RUN npm run build

# Expose the port the application ACTUALLY listens on
EXPOSE 4173

# Define the command to run when the container starts
# 1. Apply DB migrations (prisma db push is okay for SQLite on start)
# 2. Start the application preview server (ensure package.json preview script targets port 4173)
CMD ["sh", "-c", "npx prisma db push && npm run preview"]
# Using shell form `sh -c` allows running multiple commands easily
