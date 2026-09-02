#!/usr/bin/env bash
#
# One-command deploy to the remote box. Run from Git Bash:
#
#   ./deploy/deploy.sh            client only  - rebuilds the swf, copies it up,
#                                 restarts the account server (~40s)
#   ./deploy/deploy.sh --full     also pushes, pulls on the box and rebuilds the
#                                 image (~3min) - needed for XML, map or C# changes
#
# Why two modes: client.swf is overlaid from a mount at container start, so it
# needs no image rebuild. XML and maps are baked into the image, so they do.
# See deploy/README.md.
#
# The VPN to this box drops intermittently, so every remote step retries.

set -euo pipefail

HOST="${GOAT_HOST:-root@192.168.2.69}"
REMOTE_DIR="${GOAT_DIR:-/root/GoatPserver}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FULL=0
[ "${1:-}" = "--full" ] && FULL=1

SSH_OPTS=(-o ConnectTimeout=15 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o BatchMode=yes)

say()  { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }
fail() { printf "\n\033[1;31mFAILED: %s\033[0m\n" "$*" >&2; exit 1; }

# Retry wrapper - the WireGuard tunnel to this box drops often enough that a
# single failure means nothing. Three attempts with a short backoff.
retry() {
    local n=0
    until "$@"; do
        n=$((n+1))
        [ $n -ge 3 ] && return 1
        printf "   retry %d/3...\n" "$n" >&2
        sleep 3
    done
}

remote() { retry ssh "${SSH_OPTS[@]}" "$HOST" "$@"; }

# ---------------------------------------------------------------- preflight
say "Checking the box is reachable"
remote true || fail "cannot reach $HOST - is the WireGuard tunnel up?"

if [ $FULL -eq 1 ]; then
    # The image is built from the box's git checkout, so anything not pushed
    # will not be in it. Refuse rather than deploy something misleading.
    if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
        git -C "$ROOT" status --short
        fail "uncommitted changes - commit them first, they will not reach the image otherwise"
    fi
fi

# ------------------------------------------------------------ build client
say "Building client.swf"
JAVA="$ROOT/tools/jre/jdk-11.0.32+9-jre/bin/java.exe"
SDK="$(cygpath -w "$ROOT/tools/flexsdk")"
W="$(cygpath -w "$ROOT")"
"$JAVA" -Xmx2g -jar "$SDK\lib\mxmlc.jar" +flexlib="$SDK\frameworks" \
    -load-config="$W\tools\build-config.xml" -theme= \
    -external-library-path+="$W\tools\playerglobal32_0.swc" \
    -library-path+="$W\client\libs" \
    -library-path+="$SDK\frameworks\libs\framework.swc" \
    -source-path+="$W\client\src" \
    -swf-version=15 -default-size 800 600 -default-frame-rate 60 \
    -default-background-color 0x000000 -optimize=true -use-direct-blit=true \
    -keep-as3-metadata+=Inject -keep-as3-metadata+=Embed \
    -keep-as3-metadata+=PostConstruct -keep-as3-metadata+=ArrayElementType \
    -strict=true -warnings=false \
    -o "$W\client.swf" -- "$W\client\src\WebMain.as" 2>&1 | tail -25
# PIPESTATUS, not $?: the pipe through tail would otherwise mask a failed
# compile and we would deploy the previous swf as though it were the new one.
[ "${PIPESTATUS[0]}" -eq 0 ] || fail "client build failed - see errors above"
[ -f "$ROOT/client.swf" ] || fail "client.swf was not produced"
LOCAL_SIZE=$(stat -c%s "$ROOT/client.swf")
echo "   built: $LOCAL_SIZE bytes"

# ----------------------------------------------------------------- copy swf
# Must precede any container work: the entrypoint overlays /incoming onto the
# web resources at container START, so a swf copied after `compose up` is not
# picked up until the next restart and the previous build stays served.
say "Copying client.swf to the box"
retry scp "${SSH_OPTS[@]}" "$ROOT/client.swf" "$HOST:$REMOTE_DIR/deploy/web/client.swf"     || fail "scp failed"

# --------------------------------------------------------------- push/pull
if [ $FULL -eq 1 ]; then
    BRANCH="$(git -C "$ROOT" branch --show-current)"
    say "Pushing $BRANCH"
    retry git -C "$ROOT" push origin "$BRANCH"

    say "Pulling and rebuilding the image on the box (slow)"
    remote "cd $REMOTE_DIR && git pull --ff-only && cd deploy && docker compose up -d --build"         || fail "remote rebuild failed"
fi

# The image may be unchanged (client-only work), in which case `up` leaves the
# containers running and the new swf would never be overlaid. Restart always.
say "Restarting the account server"
remote "cd $REMOTE_DIR/deploy && docker compose restart app" || fail "restart failed"

# ------------------------------------------------------------------ verify
say "Verifying"
HOSTIP="${HOST#*@}"
for i in 1 2 3 4 5 6 7 8 9 10; do
    SERVED=$(curl -s -o /dev/null -w "%{size_download}" --max-time 20 \
        "http://$HOSTIP:8080/client.swf" || echo 0)
    [ "$SERVED" = "$LOCAL_SIZE" ] && break
    sleep 3
done

echo "   local:  $LOCAL_SIZE bytes"
echo "   served: $SERVED bytes"
if [ "$SERVED" != "$LOCAL_SIZE" ]; then
    fail "served swf does not match the one just built - the app container may still be starting; re-run verify in a moment"
fi

remote "cd $REMOTE_DIR/deploy && docker compose ps --format '{{.Service}} {{.Status}}'" || true

printf "\n\033[1;32mDeployed. Connect with:\033[0m\n"
printf "  \"%s/flashplayer_18_sa (1).exe\" http://%s:8080/client.swf\n\n" "$ROOT" "$HOSTIP"
