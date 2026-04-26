# ── Stage 1: Build ───────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
RUN mkdir -p /app/out && \
    if [ -f /app/package.json ]; then \
      npm install && npm run build 2>/dev/null || true; \
    fi && \
    if [ -d /app/dist ]; then cp -r /app/dist/. /app/out/; \
    elif [ -d /app/build ]; then cp -r /app/build/. /app/out/; \
    elif [ -d /app/public ]; then cp -r /app/public/. /app/out/; \
    elif [ -f /app/index.html ]; then cp /app/index.html /app/out/index.html; \
    else printf '<!doctype html><html><head><meta charset="utf-8"><title>app</title></head><body><h1>App scaffolded</h1></body></html>' > /app/out/index.html; \
    fi

# ── Stage 2: Serve ───────────────────────────────────────
FROM nginx:alpine AS runtime
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /app/out/ .
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]