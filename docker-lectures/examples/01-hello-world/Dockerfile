# Simple Hello World Dockerfile
FROM alpine:latest

# Set working directory
WORKDIR /app

# Create a simple script
RUN echo '#!/bin/sh' > hello.sh && \
    echo 'echo "Hello, Docker World!"' >> hello.sh && \
    chmod +x hello.sh

# Make the script executable and run it
CMD ["./hello.sh"]
