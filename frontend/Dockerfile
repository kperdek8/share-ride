FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_VERSION=3.16.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin

RUN git clone --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter doctor

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy application code
COPY . .

# Expose port (dla web development)
EXPOSE 3000

# Run Flutter web
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]

