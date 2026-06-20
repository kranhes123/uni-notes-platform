FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart_frog build
RUN dart compile exe build/bin/server.dart -o build/bin/server

FROM debian:bullseye-slim
COPY --from=build /app/build/bin/server /app/bin/server
RUN chmod +x /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]