###############################################################################
# Build stage
###############################################################################

# Use official Hex + Erlang + Elixir on Debian
ARG ELIXIR_VERSION=1.16.2
ARG OTP_VERSION=26.2.2
ARG DEBIAN_VERSION=bullseye-20240130-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# Install build tools
RUN apt-get update -y && \
    apt-get install -y build-essential git npm && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set build dir
WORKDIR /app

# Install Hex & Rebar (Elixir build tools)
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV="prod"

# -----------------------------
# ✅ Install Elixir dependencies early for caching
# -----------------------------

# Copy only mix files first for efficient Docker layer caching
COPY mix.exs mix.lock ./

# This line ensures `mix deps.get` runs for the specified MIX_ENV
RUN mix deps.get --only $MIX_ENV

# Ensure config dir exists so `deps.compile` won't fail
RUN mkdir config

# Copy only the relevant config files for compilation
COPY config/config.exs config/${MIX_ENV}.exs config/

# Compile dependencies
RUN mix deps.compile

# -----------------------------
# ✅ Copy source code & assets
# -----------------------------

# Copy BEAM source
COPY lib lib
COPY priv priv

# Copy assets manifest and lockfile first to cache Node modules
COPY assets/package.json assets/package-lock.json ./assets/

# Install node modules
RUN cd assets && npm install

# Copy remaining static assets
COPY assets assets

# Build static assets
RUN mix assets.deploy

# Compile the app
RUN mix compile

# Copy runtime config and release files
COPY config/runtime.exs config/
COPY rel rel

# Build the release
RUN mix release

###############################################################################
# Release stage
###############################################################################

FROM ${RUNNER_IMAGE}

# Install minimal runtime dependencies
RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

# Use a least privileged user
RUN useradd -ms /bin/bash appuser
USER appuser

# Copy built release from builder
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/financial_agent ./

# Entrypoint for release
CMD ["/app/bin/server"]
