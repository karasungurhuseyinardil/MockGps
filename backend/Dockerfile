# Build: docker build -t mockgps-api ./backend
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY global.json MockGps.sln ./
COPY src/MockGps.Domain/MockGps.Domain.csproj src/MockGps.Domain/
COPY src/MockGps.Application/MockGps.Application.csproj src/MockGps.Application/
COPY src/MockGps.Infrastructure/MockGps.Infrastructure.csproj src/MockGps.Infrastructure/
COPY src/MockGps.API/MockGps.API.csproj src/MockGps.API/
RUN dotnet restore src/MockGps.API/MockGps.API.csproj
COPY src/ src/
RUN dotnet publish src/MockGps.API/MockGps.API.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_gcServer=0
COPY --from=build /app .
USER $APP_UID
EXPOSE 8080
# Liveness: GET /health · Readiness (database): GET /health/ready — configure in the hosting platform.
ENTRYPOINT ["dotnet", "MockGps.API.dll"]
