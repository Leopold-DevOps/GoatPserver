# Builds both servers into one image; docker-compose picks which one to run.
#
# Build context is the REPO ROOT, not this folder, so the whole source tree is
# available - see the "context: .." in docker-compose.yml.
#
# The image is Debian based (the stock Microsoft .NET images). That is
# deliberate and unrelated to the host distro: the host only needs Docker, so
# this runs the same on Alpine, Debian or anything else.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY source/ ./

# Publish each server separately. Resources (xml, worlds, web) come along via
# the CopyToOutputDirectory rules in Shared.csproj.
RUN dotnet publish App/App.csproj -c Release -o /out/app \
 && dotnet publish WorldServer/WorldServer.csproj -c Release -o /out/world


FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# envsubst, used by the entrypoint to render the configs at start time
RUN apt-get update \
 && apt-get install -y --no-install-recommends gettext-base \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /out/ /app/
COPY deploy/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# The code keys several Linux code paths off this, most importantly picking
# SignalListenerLinux instead of SignalListenerWindows - the Windows one calls
# SetConsoleCtrlHandler through DllImport("Kernel32") and would throw here.
ENV IS_DOCKER=1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
