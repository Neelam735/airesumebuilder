# --- Build stage -------------------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

# Install dependencies from the lockfile first so this layer caches.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Vite inlines env vars at BUILD time, so the API base must be a build arg —
# setting it only as a runtime variable would have no effect on the bundle.
# Railway passes service variables of the same name in as build args.
ARG VITE_API_BASE
ENV VITE_API_BASE=$VITE_API_BASE
RUN npm run build

# --- Runtime stage -----------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

COPY --from=build /app/dist /usr/share/nginx/html

# The nginx image renders /etc/nginx/templates/*.template through envsubst at
# startup, substituting only variables that actually exist in the environment.
# That is what lets us bind to Railway's dynamic $PORT while leaving nginx's
# own $uri / $host untouched.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Sensible default so the image also runs locally; Railway overrides PORT.
ENV PORT=8080
EXPOSE 8080
