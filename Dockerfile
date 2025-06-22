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

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV="prod"

# Install Elixir deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files before compiling deps
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy BEAM source
COPY lib lib
COPY priv priv

###############################################################################
# Proper asset build step
###############################################################################

# -- 1) Copy package.json for caching
COPY assets/package.json assets/package-lock.json ./assets/

# -- 2) Install node modules
RUN cd assets && npm install

# -- 3) Copy remaining assets
COPY assets assets

# -- 4) Compile static assets with esbuild/tailwind
RUN mix assets.deploy

# -- 5) Compile the rest of the app
RUN mix compile

# Copy runtime and rel configs
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

# Use least privileged user
RUN useradd -ms /bin/bash appuser
USER appuser

# Copy the built release from the builder stage
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/financial_agent ./

# Entrypoint: start the release
# CMD ["/app/bin/financial_agent", "start"]

CMD ["/app/bin/server"]
