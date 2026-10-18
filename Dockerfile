FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
ARG BUILD_VERSION=development
ARG BUILD_COMMIT=unknown
WORKDIR /src
COPY src/gml-core/ src/gml-core/
COPY src/Gml.Web.Api/ src/Gml.Web.Api/
RUN dotnet publish src/Gml.Web.Api/src/Gml.Web.Api/Gml.Web.Api.csproj \
    -c "$BUILD_CONFIGURATION" -o /app/publish /p:UseAppHost=false \
    -p:GmlCoreRoot=/src/src/gml-core \
    -p:BuildVersion="$BUILD_VERSION" -p:BuildCommit="$BUILD_COMMIT"

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
USER root
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Gml.Web.Api.dll"]
