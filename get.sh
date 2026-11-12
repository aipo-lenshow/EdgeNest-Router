#!/usr/bin/env bash
# EdgeNest Router — one-line installer for Debian / Ubuntu.
#
#   curl -fsSL https://raw.githubusercontent.com/aipo-lenshow/EdgeNest-router/main/get.sh | sudo bash
#
# Asks two things (language, how to run it) and does the rest. Run it again
# later to update, switch between the two ways of running, or remove.
#
# Unattended:  ... | sudo bash -s -- --mode docker --yes
# Options:     --mode docker|native   --port N   --lang zh|en   --yes
#              update | uninstall
set -euo pipefail

CHANNEL="${EDGENEST_CHANNEL:-https://raw.githubusercontent.com/aipo-lenshow/EdgeNest-router/main/router-version.json}"
NAME=edgenest-router
BASE=/etc/edgenest-router
MODE=""; PORT=""; LANG_CHOICE=""; ASSUME_YES=0; ACTION=install
REL_VERSION=""

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    --mode=*) MODE="${1#*=}"; shift ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --port=*) PORT="${1#*=}"; shift ;;
    --lang) LANG_CHOICE="${2:-}"; shift 2 ;;
    --lang=*) LANG_CHOICE="${1#*=}"; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    update|uninstall|install) ACTION="$1"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# ---- wording (en + zh) ----
declare -A T_EN=(
  [need_root]="Please run as root:  curl ... | sudo bash"
  [need_os]="This installer supports Debian and Ubuntu. Detected:"
  [need_cpu]="Unsupported CPU:"
  [lang_q]="Language / 语言"
  [found]="EdgeNest Router is already installed here"
  [menu_q]="What would you like to do?"
  [menu_update]="Update to the latest version"
  [menu_switch]="Switch how it runs (keeps your settings)"
  [menu_remove]="Remove it (keeps your settings)"
  [menu_quit]="Nothing, exit"
  [mode_q]="How should EdgeNest Router run on this machine?"
  [mode_docker]="In Docker   — kept apart from the system, easy to move or remove"
  [mode_native]="Directly    — as a system service, nothing else to install"
  [mode_hint]="Both work the same and update themselves from the panel. Not sure? Press Enter."
  [port_busy]="Port 1123 is already used on this machine. Which port should the panel use?"
  [fetch]="Checking the latest version"
  [fetch_fail]="Could not reach the download server. Check this machine's internet connection and try again."
  [no_pkg]="This release has no package for this machine yet:"
  [dl]="Downloading"
  [sum_bad]="The download is damaged (checksum mismatch). Please run the installer again."
  [deps]="Installing required system tools"
  [docker_install]="Installing Docker"
  [docker_load]="Loading the EdgeNest Router image"
  [docker_down]="Docker is installed but not running. Start it (systemctl start docker) and run this installer again."
  [starting]="Starting EdgeNest Router"
  [stop_other]="Stopping the previous way of running"
  [wait_panel]="Waiting for the panel to come up"
  [panel_slow]="The panel has not answered yet. Check it in a minute; if it stays down see the log:"
  [done]="EdgeNest Router is running"
  [open]="Open the panel in a browser on the same network:"
  [login]="First sign-in"
  [login_hint]="(you will be asked to set your own password)"
  [next]="Then add your subscription in the panel, and point the devices you want through it at this machine as their gateway."
  [rerun]="Run this installer again any time to update, switch or remove."
  [removed]="EdgeNest Router was removed. Your settings are still in"
  [not_installed]="EdgeNest Router is not installed on this machine."
  [uptodate]="Already on the latest version:"
)
declare -A T_ZH=(
  [need_root]="请用 root 运行：curl ... | sudo bash"
  [need_os]="这个安装器支持 Debian 和 Ubuntu。当前系统："
  [need_cpu]="不支持的处理器："
  [lang_q]="Language / 语言"
  [found]="这台机器已经装了 EdgeNest 路由器"
  [menu_q]="想做什么？"
  [menu_update]="更新到最新版"
  [menu_switch]="换一种运行方式（设置保留）"
  [menu_remove]="卸载（设置保留）"
  [menu_quit]="什么都不做，退出"
  [mode_q]="EdgeNest 路由器在这台机器上怎么运行？"
  [mode_docker]="用 Docker 运行 —— 跟系统隔开，以后搬家、卸载都干净"
  [mode_native]="直接装进系统 —— 作为系统服务运行，不用另外装东西"
  [mode_hint]="两种用起来一样，都能在面板里一键升级。拿不准就直接按回车。"
  [port_busy]="这台机器的 1123 端口已经被占用。面板改用哪个端口？"
  [fetch]="正在查询最新版本"
  [fetch_fail]="连不上下载服务器。请检查这台机器能不能上网，然后重试。"
  [no_pkg]="这个版本暂时没有适合这台机器的安装包："
  [dl]="正在下载"
  [sum_bad]="下载的文件损坏（校验不一致）。请重新运行安装器。"
  [deps]="正在安装需要的系统工具"
  [docker_install]="正在安装 Docker"
  [docker_load]="正在载入 EdgeNest 路由器镜像"
  [docker_down]="Docker 已安装但没有运行。请先启动它（systemctl start docker），再重新运行安装器。"
  [starting]="正在启动 EdgeNest 路由器"
  [stop_other]="正在停掉原来的运行方式"
  [wait_panel]="正在等面板启动"
  [panel_slow]="面板还没有响应。过一分钟再看；如果一直打不开，看日志："
  [done]="EdgeNest 路由器已经在运行"
  [open]="用同一个网络里的电脑或手机，在浏览器打开："
  [login]="首次登录"
  [login_hint]="（登录后会要求你设置自己的密码）"
  [next]="接着在面板里添加订阅，再把要走它上网的设备的「网关」改成这台机器的地址。"
  [rerun]="以后要更新、换运行方式或卸载，再运行一次这个安装器就行。"
  [removed]="EdgeNest 路由器已卸载。你的设置还留在"
  [not_installed]="这台机器没有安装 EdgeNest 路由器。"
  [uptodate]="已经是最新版："
)
t() { if [ "$LANG_CHOICE" = zh ]; then printf '%s' "${T_ZH[$1]}"; else printf '%s' "${T_EN[$1]}"; fi; }
say()  { printf '%s\n' "$*"; }
step() { printf '%s==>%s %s\n' "$C_GREEN$C_BOLD" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$*"; }
die()  { printf '%sx%s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; exit 1; }
have_tty() { [ "$ASSUME_YES" = 0 ] && [ -e /dev/tty ] && : </dev/tty 2>/dev/null; }
ask() { # ask <prompt> <default> -> REPLY
  local ans=""
  printf '%s?%s %s %s[%s]%s ' "$C_CYAN$C_BOLD" "$C_RESET" "$1" "$C_DIM" "$2" "$C_RESET" >/dev/tty
  read -r ans </dev/tty || ans=""
  REPLY="${ans:-$2}"
}

print_banner() {
  # Banner: Copperplate "EDGENEST" rasterized to Braille (chafa) and floated
  # in the middle of a Braille-blank star-field that fills the FULL terminal
  # width. Stars are single-dot Braille glyphs (⠁ ⠂ ⠄ ⠈ ⠐ ⠠ ⡀ ⢀) so they
  # share the exact cell width of the letter glyphs — no ASCII/Braille
  # alignment drift — and read as "deep space" rather than ascii dots.
  local cols left right
  cols=$(tput cols 2>/dev/null || echo 100)
  local LOGO_W=80
  left=$(( (cols - LOGO_W) / 2 ))
  [ $left -lt 1 ] && left=1
  right=$(( cols - LOGO_W - left ))
  [ $right -lt 1 ] && right=1

  # Two star tiers so the sky reads as depth, not noise:
  #   - dim tier (Braille single-dot, 8 dot positions): the diffuse "dust"
  #   - bright tier (ASCII *): the rare standout star
  # Both ASCII * and Braille glyphs are 1 cell wide in monospace fonts so
  # column alignment is preserved across mixed rows.
  local -a STAR=("⠁" "⠂" "⠄" "⠈" "⠐" "⠠" "⡀" "⢀")
  local BLANK="⠀"  # U+2800 Braille blank — same width as letter glyphs

  # sky_row $width $seed — emits a row of $width cells with dim stars at
  # ~1 per 17 and bright * at ~1 per 53 (≈ 3× rarer). Cheap LCG keeps the
  # render deterministic per (seed,i) so identical runs look identical.
  sky_row() {
    local w=$1 seed=$2 i out=""
    for ((i=0; i<w; i++)); do
      local n=$(( (seed * 1103515245 + i * 12345 + 1013904223) & 0x7fffffff ))
      if (( n % 53 == 0 )); then
        out+="*"
      elif (( n % 17 == 0 )); then
        out+="${STAR[n % 8]}"
      else
        out+="$BLANK"
      fi
    done
    printf "%s" "$out"
  }

  # text_row $text $seed — center $text on cols, pad both sides with sky.
  # Used for the footer lines so version/author land inside the star field
  # rather than floating in a void below it.
  text_row() {
    local text=$1 seed=$2
    local tlen=${#text}
    local ltext=$(( (cols - tlen) / 2 ))
    [ $ltext -lt 1 ] && ltext=1
    local rtext=$(( cols - tlen - ltext ))
    [ $rtext -lt 1 ] && rtext=1
    printf "%s%s%s" "$(sky_row "$ltext" "$seed")" "$text" "$(sky_row "$rtext" $((seed+1)))"
  }

  echo ""
  # 3 pure star-field rows above the wordmark.
  printf "${C_DIM}"
  for s in 1 2 3; do printf "%s\n" "$(sky_row "$cols" $((s*31)))"; done
  # Logo rows: continuous star-field on each side, letters in the middle.
  printf "${C_RESET}${C_GREEN}${C_BOLD}"
  local row=0
  while IFS= read -r line; do
    row=$((row+1))
    local L="$(sky_row "$left" $((row*53+100)))"
    local R="$(sky_row "$right" $((row*53+200)))"
    printf "%s%s%s\n" "$L" "$line" "$R"
  done <<'LOGO'
⢶⣶⣶⣶⣶⣶⣶⣶⡇⠰⣶⣶⣶⣶⣶⣶⣦⣄⠀⠀⠀⣀⣤⣶⣶⣶⣶⣦⣤⠄⠀⢲⣶⣶⣶⣶⣶⣶⣶⡇⠀⢶⣶⣶⡀⠀⠀⠀⢶⣶⡆⠀⠰⣶⣶⣶⣶⣶⣶⣶⣿⠀⢀⣤⣶⣶⣶⣶⣦⣤⡄⢸⣶⣶⣶⣶⣶⣶⣶⣾
⢸⣿⡏⠉⠉⠉⡉⠉⠃⠀⣿⣿⠉⠉⠉⠉⠻⣿⣷⠀⣼⣿⡟⠋⠉⠉⠉⠻⠏⠀⠀⢸⣿⡏⠉⠉⠉⡉⠉⠃⠀⢸⣿⣿⣿⣦⡀⠀⢸⣿⡇⠀⠀⣿⣿⠉⠉⠉⢉⠉⠙⠀⣾⣿⣏⠉⠉⠉⠛⡟⠀⠘⠉⠉⢹⣿⣟⠉⠉⠙
⢸⣿⣿⣿⣿⣿⡇⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠄⣿⣿⠀⠀⠀⣦⣤⣤⣤⡤⠀⢸⣿⣿⣿⣿⣿⡇⠀⠀⠀⢸⣿⡏⠻⣿⣷⣄⢸⣿⡇⠀⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠹⢿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⢸⣿⣇⠀⠀⠀
⢸⣿⡇⠀⠀⠀⠁⢀⡀⠀⣿⣿⠀⠀⠀⢀⣠⣿⡿⠀⢻⣿⣆⡀⠀⠋⠉⣹⣿⡇⠀⢸⣿⡇⠀⠀⠀⠁⠀⡀⠀⢸⣿⡇⠀⠈⠻⣿⣿⣿⡇⠀⠀⣿⣿⠀⠀⠀⠈⠀⣀⠀⢠⣆⣀⠉⠉⢉⣹⣿⡇⠀⠀⠀⢸⣿⣇⠀⠀⠀
⣼⣿⣿⣿⣿⣿⣿⣿⡇⢠⣿⣿⣿⣿⣿⣿⠿⠟⠁⠀⠀⠙⠿⠿⣿⣿⣿⠿⠟⠃⠀⣼⣿⣿⣿⣿⣿⣿⣿⡇⠀⣼⣿⡇⠀⠀⠀⠙⣿⣿⡇⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⠀⠛⠿⢿⣿⣿⡿⠿⠛⠁⠀⠀⠀⢸⣿⣿⠀⠀⠀
LOGO
  # 2 pure star-field rows below the wordmark, then footer-in-sky, then
  # 1 more sky row to close the frame.
  printf "${C_RESET}${C_DIM}"
  printf "%s\n" "$(sky_row "$cols" 124)"
  printf "%s\n" "$(sky_row "$cols" 155)"
  # Footer lines embedded in the star-field — text in the middle, sky on
  # both sides, so the eye never crosses an empty void between the logo
  # and the version/author info.
  local foot1="Router ${REL_VERSION:-}  ·  by AiPo <aipo@ailenshow.com>"
  local foot2="https://github.com/aipo-lenshow/EdgeNest-router"
  printf "%s\n" "$(text_row "$foot1" 186)"
  printf "%s\n" "$(text_row "$foot2" 217)"
  printf "%s\n" "$(sky_row "$cols" 248)"
  printf "${C_RESET}\n"
}

ask_language() {
  [ -n "$LANG_CHOICE" ] && return
  local def=en
  case "${LC_ALL:-${LANG:-}}" in zh*|ZH*) def=zh ;; esac
  if ! have_tty; then LANG_CHOICE="$def"; return; fi
  local d=1; [ "$def" = zh ] && d=2
  ask "Language / 语言   1) English   2) 中文" "$d"
  case "$REPLY" in 2|zh|ZH|中文) LANG_CHOICE=zh ;; *) LANG_CHOICE=en ;; esac
}

check_host() {
  [ "$(id -u)" = 0 ] || die "$(t need_root)"
  # /etc/os-release defines NAME and VERSION of its own: read it apart.
  local os_ids os_pretty
  os_ids="$( (. /etc/os-release 2>/dev/null; printf '%s %s' "${ID:-}" "${ID_LIKE:-}") )"
  os_pretty="$( (. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-unknown}") )"
  case "$os_ids" in
    *debian*|*ubuntu*) ;;
    *) die "$(t need_os) $os_pretty" ;;
  esac
  case "$(uname -m)" in
    x86_64) ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    *) die "$(t need_cpu) $(uname -m)" ;;
  esac
  command -v curl >/dev/null 2>&1 || { apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl ca-certificates >/dev/null; }
}

# How it is installed right now: docker | native | "".
installed_mode() {
  if command -v docker >/dev/null 2>&1 && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$NAME"; then echo docker; return; fi
  if [ -f /etc/systemd/system/$NAME.service ]; then echo native; return; fi
  echo ""
}

# manifest_get <key-path> : read a string out of the release manifest
# without needing jq (python3 ships with Debian / Ubuntu).
MANIFEST=""
fetch_manifest() {
  [ -n "$MANIFEST" ] && return
  MANIFEST="$(curl -fsSL --connect-timeout 15 --max-time 60 "$CHANNEL" 2>/dev/null)" || die "$(t fetch_fail)"
  REL_VERSION="$(manifest_get version)"
  [ -n "$REL_VERSION" ] || die "$(t fetch_fail)"
}
manifest_get() {
  printf '%s' "$MANIFEST" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for k in sys.argv[1].split("/"):
    d=d.get(k,"") if isinstance(d,dict) else ""
print(d if isinstance(d,str) else "")' "$1"
}

# download <manifest key> <dest> : fetch a release file and verify it.
download() {
  local key="$1" dest="$2" url sum got
  url="$(manifest_get "downloads/$key")"; sum="$(manifest_get "sha256/$key")"
  [ -n "$url" ] && [ -n "$sum" ] || die "$(t no_pkg) $key"
  step "$(t dl) $(basename "$url" | sed 's/%2B/+/g')"
  curl -fL --connect-timeout 20 --retry 3 --progress-bar -o "$dest" "$url" || die "$(t fetch_fail)"
  got="$(sha256sum "$dest" | cut -d' ' -f1)"
  [ "$got" = "$sum" ] || { rm -f "$dest"; die "$(t sum_bad)"; }
}

choose_mode() {
  case "$MODE" in docker|native) return ;; "") ;; *) die "--mode docker|native" ;; esac
  if ! have_tty; then MODE=docker; return; fi
  say ""
  say "${C_BOLD}$(t mode_q)${C_RESET}"
  say "  1) $(t mode_docker)"
  say "  2) $(t mode_native)"
  say "  ${C_DIM}$(t mode_hint)${C_RESET}"
  ask "1 / 2" 1
  case "$REPLY" in 2) MODE=native ;; *) MODE=docker ;; esac
}

port_in_use() { ss -ltnH 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$"; }

choose_port() {
  [ -n "$PORT" ] && return
  # Keep whatever an existing install already uses.
  if [ -f "$BASE/panel.db" ] || [ -n "$(installed_mode)" ]; then return; fi
  if ! port_in_use 1123; then return; fi
  if ! have_tty; then PORT=11123; return; fi
  ask "$(t port_busy)" 11123
  PORT="$REPLY"
  case "$PORT" in ''|*[!0-9]*) PORT=11123 ;; esac
}

# Remove what a core that died without warning leaves behind: redirect rules
# that point at ports nobody listens on would cut this machine off the network.
# Runs with "stop on error" switched off: finding nothing to clean is the
# normal case and must never end the installer.
clean_leftovers() { ( set +e +o pipefail; _clean_leftovers ) || true; }
_clean_leftovers() {
  pgrep -x sing-box >/dev/null 2>&1 && return 0
  command -v nft >/dev/null 2>&1 && nft delete table inet sing-box 2>/dev/null || true
  ip link del edgenest-tun 2>/dev/null || true
  local fam pref tbl
  # The panel's own firewall chain (only the uninstall path gets here with
  # it still present).
  local ipt line
  for ipt in iptables ip6tables; do
    command -v $ipt >/dev/null 2>&1 || continue
    $ipt -w -S 2>/dev/null | grep -- '-j EDGENEST_PROXY' | sed 's/^-A /-D /' | while read -r line; do
      $ipt -w $line 2>/dev/null || true
    done
    $ipt -w -F EDGENEST_PROXY 2>/dev/null || true
    $ipt -w -X EDGENEST_PROXY 2>/dev/null || true
    # The LAN-forward allow the daemon keeps next to Docker; it puts it back
    # on its next start.
    $ipt -w -S DOCKER-USER 2>/dev/null | grep -- 'edgenest-router: LAN forward' | sed 's/^-A /-D /' | while read -r line; do
      eval "$ipt -w $line" 2>/dev/null || true
    done
  done
  for fam in -4 -6; do
    for pref in 9000 9001 9002; do
      while ip $fam rule del pref "$pref" 2>/dev/null; do :; done
    done
    # Rules the core marks with its own packet marks.
    ip $fam rule show 2>/dev/null | grep -E 'fwmark 0x202[34]' | sed -n 's/^\([0-9][0-9]*\):.*/\1/p' | sort -u | while read -r pref; do
      while ip $fam rule del pref "$pref" 2>/dev/null; do :; done
    done
    # Its auto-route tables: once the tunnel is gone they are empty or hold
    # only loopback entries. Drop them together with the rules that point at
    # them.
    ip $fam rule show pref 1 2>/dev/null | sed -n 's/.*lookup \([0-9][0-9]*\)$/\1/p' | while read -r tbl; do
      if [ -z "$(ip $fam route show table "$tbl" 2>/dev/null | grep -vE '^local (127\.0\.0\.1|::1) ')" ]; then
        ip $fam rule del pref 1 lookup "$tbl" 2>/dev/null || true
        ip $fam route flush table "$tbl" 2>/dev/null || true
      fi
    done
  done
  # The system resolver gave up on its servers while the network was cut
  # off; tell it to try again now instead of leaving names unresolved for a
  # while.
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl reset-server-features >/dev/null 2>&1
    resolvectl flush-caches >/dev/null 2>&1
  fi
}

stop_docker() {
  command -v docker >/dev/null 2>&1 || return 0
  docker info >/dev/null 2>&1 || return 0
  # Stop it the polite way first so it can put the network back by itself.
  docker stop -t 30 "$NAME" >/dev/null 2>&1 || true
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  clean_leftovers
}
stop_native() {
  [ -f /etc/systemd/system/$NAME.service ] || return 0
  systemctl disable --now "$NAME" >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/$NAME.service /usr/sbin/edgenest-routerd
  rm -rf /usr/lib/edgenest-router /etc/systemd/system/$NAME.service.d
  systemctl daemon-reload
  clean_leftovers
}

forwarding_on() {
  cat > /etc/sysctl.d/90-edgenest-router.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL
  sysctl -q --system >/dev/null 2>&1 || true
}

install_native() {
  local tmp; tmp="$(mktemp -d)"
  download "linux-$ARCH" "$tmp/bundle.tar.gz"
  tar -C "$tmp" -xzf "$tmp/bundle.tar.gz"
  if [ "$(installed_mode)" = docker ]; then step "$(t stop_other)"; stop_docker; fi
  step "$(t deps)"
  if [ -n "$PORT" ]; then
    mkdir -p /etc/systemd/system/$NAME.service.d
    printf '[Service]\nEnvironment=EDGENEST_PANEL_PORT=%s\n' "$PORT" > /etc/systemd/system/$NAME.service.d/port.conf
  fi
  step "$(t starting)"
  sh "$tmp/edgenest-router/install.sh" >/dev/null
  rm -rf "$tmp"
}

install_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    step "$(t docker_install)"
    apt-get update -qq >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io >/dev/null
  fi
  # Docker must actually answer before anything is loaded into it.
  if ! docker info >/dev/null 2>&1; then
    systemctl enable --now docker.socket >/dev/null 2>&1 || true
    systemctl reset-failed docker >/dev/null 2>&1 || true
    systemctl enable --now docker >/dev/null 2>&1 || true
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do docker info >/dev/null 2>&1 && break; sleep 1; done
    docker info >/dev/null 2>&1 || die "$(t docker_down)"
  fi
  local tmp; tmp="$(mktemp -d)"
  download "image-linux-$ARCH" "$tmp/image.tar.gz"
  step "$(t docker_load)"
  local loaded; loaded="$(gunzip -c "$tmp/image.tar.gz" | docker load | sed -n 's/^Loaded image: //p' | tail -1)"
  rm -rf "$tmp"
  [ -n "$loaded" ] || die "docker load failed"
  if [ "$(installed_mode)" = native ]; then step "$(t stop_other)"; stop_native; fi
  forwarding_on
  # Settings live in $BASE on the host in both ways of running, so switching
  # between them keeps everything.
  mkdir -p "$BASE"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  step "$(t starting)"
  local envs=()
  [ -n "$PORT" ] && envs+=(-e "EDGENEST_PANEL_PORT=$PORT")
  [ -n "${EDGENEST_UPGRADE_MANIFEST:-}" ] && envs+=(-e "EDGENEST_UPGRADE_MANIFEST=$EDGENEST_UPGRADE_MANIFEST")
  docker run -d --name "$NAME" --restart unless-stopped \
    --network host --cap-add NET_ADMIN --cap-add NET_RAW --device /dev/net/tun \
    -v "$BASE:/etc/edgenest-router" "${envs[@]}" "$loaded" >/dev/null
}

panel_port() {
  if [ -n "$PORT" ]; then echo "$PORT"; return; fi
  local p=""
  [ -f "$BASE/panel.db" ] && command -v python3 >/dev/null 2>&1 && p="$(python3 - "$BASE/panel.db" 2>/dev/null <<'PY' || true
import sqlite3,sys
try:
    r=sqlite3.connect("file:"+sys.argv[1]+"?mode=ro",uri=True).execute("select value from settings where key='panel_port'").fetchone()
    print(r[0] if r and r[0] else "")
except Exception:
    pass
PY
)"
  echo "${p:-1123}"
}

finish() {
  local port ip i ok=0
  port="$(panel_port)"
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1)"
  step "$(t wait_panel)"
  for i in $(seq 1 30); do
    if curl -fs -o /dev/null --max-time 2 "http://127.0.0.1:$port/"; then ok=1; break; fi
    sleep 1
  done
  say ""
  if [ "$ok" = 1 ]; then
    say "${C_GREEN}${C_BOLD}✔ $(t done)${C_RESET}  ${C_DIM}($REL_VERSION, $MODE)${C_RESET}"
  else
    warn "$(t panel_slow)"
    if [ "$MODE" = docker ]; then say "    docker logs $NAME"; else say "    journalctl -u $NAME -n 50"; fi
  fi
  say ""
  say "  $(t open)"
  say "      ${C_BOLD}http://${ip:-<this-machine>}:$port/${C_RESET}"
  if [ ! -s "$BASE/panel.db" ] || [ "${FRESH:-0}" = 1 ]; then
    say "  $(t login):  ${C_BOLD}EdgeNest / EdgeNest${C_RESET}  ${C_DIM}$(t login_hint)${C_RESET}"
  fi
  say ""
  say "  $(t next)"
  say "  ${C_DIM}$(t rerun)${C_RESET}"
  say ""
}

do_install() {
  FRESH=0; [ -s "$BASE/panel.db" ] || FRESH=1
  # A previous copy that was killed without warning may have left this
  # machine unable to resolve names; put that right before downloading.
  clean_leftovers
  fetch_manifest
  choose_port
  case "$MODE" in
    docker) install_docker ;;
    native) install_native ;;
  esac
  finish
}

do_uninstall() {
  local cur; cur="$(installed_mode)"
  # Even with nothing installed, a copy that was force-removed earlier may
  # have left this machine cut off: always put the network right.
  [ -n "$cur" ] || { clean_leftovers; say "$(t not_installed)"; exit 0; }
  # Hand the network back before the programs go away.
  if [ "$cur" = docker ]; then
    docker exec "$NAME" /usr/sbin/edgenest-routerd release >/dev/null 2>&1 || true
    stop_docker
    docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep '^edgenest-router:' | xargs -r docker rmi >/dev/null 2>&1 || true
  else
    stop_native
  fi
  rm -f /etc/sysctl.d/90-edgenest-router.conf
  say "${C_GREEN}✔${C_RESET} $(t removed) $BASE"
}

main() {
  ask_language
  check_host
  [ "$ACTION" = uninstall ] || fetch_manifest
  print_banner
  local cur; cur="$(installed_mode)"
  case "$ACTION" in
    uninstall) do_uninstall; exit 0 ;;
    update) [ -n "$cur" ] || die "$(t not_installed)"; MODE="${MODE:-$cur}"; do_install; exit 0 ;;
  esac
  if [ -n "$cur" ] && [ -z "$MODE" ]; then
    say "${C_BOLD}$(t found)${C_RESET} ${C_DIM}($cur)${C_RESET}"
    if have_tty; then
      say "  1) $(t menu_update)"
      say "  2) $(t menu_switch)"
      say "  3) $(t menu_remove)"
      say "  4) $(t menu_quit)"
      ask "$(t menu_q)" 1
      case "$REPLY" in
        2) if [ "$cur" = docker ]; then MODE=native; else MODE=docker; fi ;;
        3) do_uninstall; exit 0 ;;
        4) exit 0 ;;
        *) MODE="$cur" ;;
      esac
    else
      MODE="$cur"
    fi
  fi
  choose_mode
  do_install
}

main
