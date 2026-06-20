FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart_frog build

FROM debian:bullseye-slim
COPY --from=build /app/build/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]