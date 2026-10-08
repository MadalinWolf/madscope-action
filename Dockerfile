FROM node:22-bookworm-slim

# System deps for Playwright Chromium + git to fetch the MadScope engine.
# ca-certificates is required: the -slim base ships without a CA bundle,
# which breaks TLS (e.g. cloning the engine repo).
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates git python3 \
  && rm -rf /var/lib/apt/lists/*

# Pin the MadScope engine version baked into the image.
ARG MADSCOPE_REF=v1.0.0
RUN git clone --depth 1 --branch "${MADSCOPE_REF}" https://github.com/MadalinWolf/MadScope.git /madscope

WORKDIR /madscope

# Browsers live at a fixed image path: the Actions runtime overrides HOME,
# so Playwright's default (~/.cache) would not match the build-time location.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Engine dependencies, CLI build, and Chromium (+ OS deps) for the engine's
# exact Playwright version.
RUN npm ci \
  && npm run build --workspace=@madscope/cli \
  && npx playwright install --with-deps chromium

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
