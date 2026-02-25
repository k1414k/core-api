# Dockerfile for the Rails Auction API

# --- Base Stage ---
# This stage installs all necessary system dependencies, Ruby, and Node.js.
# Using a specific Ubuntu version for reproducibility.
# This image is compatible with both AMD64 and ARM64 architectures.
FROM ubuntu:22.04 AS base

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV LANG=C.UTF-8 \
    RAILS_ENV=production \
    # Add ruby and node binaries to PATH
    PATH="/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 1. Install System Dependencies
# - software-properties-common: For add-apt-repository
# - build-essential: For compiling native gem extensions
# - libsqlite3-dev: For the sqlite3 gem
# - git: For cloning the repository
# - curl: For downloading Node.js setup script
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    libsqlite3-dev \
    git \
    curl

# 2. Install Ruby
# Using the brightbox PPA to get a specific Ruby version without compiling from source.
ARG RUBY_VERSION=3.2.4
RUN add-apt-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends ruby${RUBY_VERSION%-*} ruby${RUBY_VERSION%-*}-dev

# 3. Install Node.js and Yarn
# Required for Rails asset pipeline or if using a JS framework.
ARG NODE_MAJOR=18
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g yarn

# 4. Install Bundler
# Install a specific version of bundler for consistency.
ARG BUNDLER_VERSION=2.4.22
RUN gem install bundler -v ${BUNDLER_VERSION} --no-document


# --- Builder Stage ---
# This stage clones the repository and installs the application dependencies.
FROM base AS builder

# Set the working directory
WORKDIR /app

# Clone the application from GitHub.
# NOTE: Using HTTPS instead of SSH to avoid insecurely handling SSH keys in the image.
# If your repository is private, consider using build secrets or a multi-stage build
# where the code is copied from the local context.
RUN git clone https://github.com/k1414k/core-api.git .

# Install gems, excluding development and test groups for a smaller image.
RUN bundle config set --local without 'development:test' && \
    bundle install --jobs=$(nproc) --retry 3


# --- Final Image Stage ---
# This is the final, clean image that will be run.
FROM base AS final

# Set the working directory
WORKDIR /app

# Copy the application code and installed gems from the builder stage
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Expose the port Rails runs on
EXPOSE 3000

# Set the entrypoint to run database migrations and the main command
# to start the Rails server.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]