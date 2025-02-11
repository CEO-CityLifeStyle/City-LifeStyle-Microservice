# Stage 1: Development
FROM debian:latest as development

# Install required dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils libglu1-mesa wget nginx && \
    apt-get clean

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter

# Add flutter to path
ENV PATH="/flutter/bin:${PATH}"

# Initialize Flutter
RUN flutter precache && \
    flutter doctor && \
    flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy the Flutter project
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Start development server
CMD ["flutter", "run", "--web-port", "3000", "--web-hostname", "0.0.0.0"]

# Stage 2: Production builder
FROM debian:latest as builder

# Install required dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils libglu1-mesa && \
    apt-get clean

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter

# Add flutter to path
ENV PATH="/flutter/bin:${PATH}"

# Initialize Flutter
RUN flutter precache && \
    flutter doctor && \
    flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy the Flutter project
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build for web
RUN flutter build web --release

# Stage 3: Production
FROM nginx:alpine as production

# Copy built files from builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 3000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:3000/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
