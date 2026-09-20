# build
FROM node:12-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# release
FROM nginx:1.25-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist/frontend /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]