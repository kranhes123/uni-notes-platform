FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart_frog build
RUN dart compile exe build/bin/server.dart -o build/bin/server

FROM debian:bullseye-slim

# poppler-utils -> pdftotext komutunu sağlar (PDF içeriğini okumak için)
# ca-certificates -> Cloudinary gibi HTTPS adreslerine güvenli istek atmak için
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        poppler-utils \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app/build/bin/server /app/bin/server
RUN chmod +x /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]