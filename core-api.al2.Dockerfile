# Dockerfile for the Rails Auction API - Amazon Linux 2 Compatible

# --- Base Stage ---
# This stage installs all necessary system dependencies for an Amazon Linux 2 environment.
# This includes build tools, rbenv for Ruby management, and Node.js.
FROM amazonlinux:2 AS base

# Set environment variables for rbenv and PATH
ENV RBENV_ROOT="/usr/local/rbenv"
ENV PATH="$RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH"
ENV RAILS_ENV="production"
ENV LANG="C.UTF-8"

# 1. Install System Dependencies & Build Tools
# - "Development Tools": For compiling native extensions and Ruby.
# - git, curl: Standard tools for source control and downloads.
# - sqlite-devel: For the sqlite3 gem (equivalent to libsqlite3-dev).
# - openssl-devel, readline-devel, zlib-devel: Required by ruby-build to compile Ruby.
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y git curl sqlite-devel openssl-devel readline-devel zlib-devel && \
    # Clean up yum cache to keep the image smaller
    yum clean all

# 2. Install rbenv and ruby-build
# This is the recommended way to install a specific Ruby version on Amazon Linux.
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT && \
    git clone https://github.com/rbenv/ruby-build.git $RBENV_ROOT/plugins/ruby-build

# 3. Install Ruby
# Install the specific version required by the application.
ARG RUBY_VERSION=3.2.4
RUN rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION

# 4. Install Node.js, Yarn, and Bundler
# - amazon-linux-extras is the standard way to install runtimes like Node.js on AL2.
# - Bundler is installed via gem after Ruby is available.
ARG BUNDLER_VERSION=2.4.22
RUN amazon-linux-extras install -y nodejs18 && \
    npm install -g yarn && \
    gem install bundler -v $BUNDLER_VERSION && \
    # Rehash rbenv to make the bundler executable available.
    rbenv rehash

# --- Builder Stage ---
# This stage clones the repository and installs the application gems.
FROM base AS builder

WORKDIR /app

# Clone the application from GitHub using HTTPS.
RUN git clone https://github.com/k1414k/core-api.git .

# Install gems, excluding development and test groups.
RUN bundle config set --local without 'development:test' && \
    bundle install --jobs=$(nproc) --retry 3

# --- Final Image Stage ---
# This is the minimal, production-ready image.
FROM amazonlinux:2 AS final

# Set environment variables
ENV RAILS_ENV="production" \
    RBENV_ROOT="/usr/local/rbenv" \
    PATH="$RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH" \
    LANG="C.UTF-8"

WORKDIR /app

# Install only the runtime dependencies for the final image.
# We copy the pre-installed rbenv and gems from the builder stage.
RUN yum update -y && \
    yum install -y sqlite git && \
    yum clean all

# Copy rbenv with the installed Ruby from the builder stage.
COPY --from=builder $RBENV_ROOT $RBENV_ROOT
# Copy the application code and installed gems from the builder stage.
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

EXPOSE 3000

# Start the Rails server.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
