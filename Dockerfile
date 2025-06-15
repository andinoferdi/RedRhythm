FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Set working directory
WORKDIR /pb

# Copy PocketBase binary
COPY Backend/pocketbase ./pocketbase

# Copy data directory if exists
COPY Backend/pb_data ./pb_data

# Copy migrations
COPY Backend/pb_migrations ./pb_migrations

# Make binary executable
RUN chmod +x pocketbase

# Expose port (Railway uses PORT environment variable)
EXPOSE $PORT

# Run PocketBase
CMD ["sh", "-c", "./pocketbase serve --http 0.0.0.0:$PORT"] 