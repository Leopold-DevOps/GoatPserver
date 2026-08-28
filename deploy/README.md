# Running the server on a remote box over WireGuard

Your PC runs only the Flash client. The remote box runs Redis, the account
server (8080) and the world server (2050), all in containers. Over WireGuard
the two look like localhost to each other, so nothing else has to change.

The host distro does not matter - only Docker does. These images are the stock
Microsoft .NET ones, which are Debian based regardless of what the host runs.

## First time, on the server

```sh
git clone https://github.com/Leopold-DevOps/GoatPserver.git
cd GoatPserver/deploy
cp .env.example .env
echo $SSH_CONNECTION         # 3rd value is the address your PC reaches this box on
nano .env                    # set SERVER_ADDRESS to that address
docker compose up -d --build
```

`SERVER_ADDRESS` is the one setting that matters and the one that is easy to
get wrong. The account server hands it to clients as the place to open the
game socket, so it must be the address **your PC** can reach over the VPN. If
you leave it at `127.0.0.1`, every client is told to connect to itself; you
get a server list and then a connection that never completes.

Do not assume it is a `10.x` tunnel address. If WireGuard terminates on the
router rather than on this box, there is no `wg0` here at all and the right
answer is the box's LAN address, e.g. `192.168.2.69`. `echo $SSH_CONNECTION`
sidesteps the question - whatever it reports is reachable from your PC by
definition, because that is the address your SSH session is using.

`.env` is gitignored, so your friend's address never lands in the repo.

## First time, on your PC

Build the client and copy it over. It is a build artifact and deliberately not
in git, so it is mounted into the container rather than baked into the image:

```sh
scp client.swf user@10.0.0.1:~/GoatPserver/deploy/web/client.swf
```

Then point the Flash player at the server instead of localhost:

```
http://10.0.0.1:8080/client.swf
```

You do **not** need a client rebuild to change servers. The client now reads
its own load URL and talks to whatever host served it (`AppEngineHost`), so the
same swf works against localhost and the remote box. Only the port split
between release and testing is still fixed in `ReleaseSetup`.

## Updating after code changes

Server-side changes:

```sh
git pull && docker compose up -d --build
```

Client-side changes - rebuild on your PC, then just copy the swf over; the
volume mount means no image rebuild and no restart:

```sh
scp client.swf user@10.0.0.1:~/GoatPserver/deploy/web/client.swf
```

Map and XML changes are baked into the image, so those need the `--build`.

## What the pieces do

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Builds both servers into one image; compose picks which to run |
| `entrypoint.sh` | Renders configs from templates at start, then execs the server |
| `config/*.template` | `server.json` / `wServer.json` with the address substituted in |
| `web/` | Mounted over the account server's web resources; holds `client.swf` |
| `.env` | Your `SERVER_ADDRESS`, not committed |

Configs are rendered at container start rather than committed so that the only
machine-specific value lives in `.env`.

`IS_DOCKER=1` is set in the image. The code keys two unrelated things off it:
it picks `SignalListenerLinux` instead of the Windows one, whose constructor
calls `SetConsoleCtrlHandler` through `DllImport("Kernel32")` and would throw
on Linux; and it makes the account server read `/data/server.json`. Both are
what we want here, but be aware they are coupled.

## Checks and gotchas

Redis is not published to the host. Only the two servers reach it, over the
compose network, so it is not exposed on the VPN.

Flash needs a socket policy to connect to a non-local host. The world server
already answers `policy-file-request` inline on 2050 with
`allow-access-from domain="*"`, so this works without a separate policy daemon
on port 843.

If the client loads but no maps or items exist, check the resources actually
made it into the image - `Shared.csproj` writes its copy globs with Windows
backslashes (`resources\**\*`), which MSBuild normalises on Linux, but it is
the first thing to rule out:

```sh
docker compose exec world ls resources/worlds/Exalt
```

Logs:

```sh
docker compose logs -f world
docker compose logs -f app
```

The `iceTomb Chest` and `Grim Reaper` warnings at startup are pre-existing
content the fork ships without. They are noise, not a broken deploy.
