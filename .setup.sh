#!/usr/bin/env bash
#
# setup.sh — bootstrap a fresh Fedora machine from this dotfiles repo.
#
# Restores the bare repo into $HOME and installs everything the tracked configs
# expect: the CLI stack from .bashrc/.zshrc, every Neovim runtime dependency
# (Mason toolchains, treesitter compilers, DAP adapters), and the language
# toolchains behind them.
#
# Safe to re-run: every phase checks before it acts.
#
#   ./setup.sh                 # run everything except the optional phase
#   ./setup.sh --list          # show phases
#   ./setup.sh --only rust,nvim-setup
#   ./setup.sh --skip optional,kde
#   ./setup.sh --with-optional # also flutter / android / flatpak / docker
#   ./setup.sh --dry-run       # print commands, change nothing
#
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Settings
# ─────────────────────────────────────────────────────────────────────────────
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/rajko-simic/conf.git}"
DOTFILES_GIT_DIR="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
NVIM_VERSION="${NVIM_VERSION:-latest}"   # "latest" or a tag such as v0.12.2
NVIM_PREFIX="/opt/nvim"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

ALL_PHASES=(preflight repos dnf neovim rust dotfiles python nvim-setup shell kde optional)
DEFAULT_PHASES=(preflight repos dnf neovim rust dotfiles python nvim-setup shell kde)

DRY_RUN=0
ASSUME_YES=0
PHASES=()

# ─────────────────────────────────────────────────────────────────────────────
# Output helpers
# ─────────────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'; C_BLUE=$'\e[34m'
else
  C_RESET=; C_BOLD=; C_DIM=; C_RED=; C_GREEN=; C_YELLOW=; C_BLUE=
fi

FAILED=()
phase_header() { printf '\n%s%s══ %s %s%s\n' "$C_BOLD" "$C_BLUE" "$1" "$(printf '═%.0s' $(seq 1 $((60 - ${#1}))))" "$C_RESET"; }
info()  { printf '%s  ▸%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s  ✔%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
skip()  { printf '%s  ·%s %s%s%s\n' "$C_DIM" "$C_RESET" "$C_DIM" "$*" "$C_RESET"; }
warn()  { printf '%s  ▲%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail()  { printf '%s  ✖%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; FAILED+=("$*"); }
die()   { printf '\n%s  ✖ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; exit 1; }

# Run a command, honouring --dry-run.
run() {
  if (( DRY_RUN )); then
    printf '%s  $ %s%s\n' "$C_DIM" "$*" "$C_RESET"
    return 0
  fi
  "$@"
}

have()  { command -v "$1" >/dev/null 2>&1; }
# rpm -q is much faster than dnf for an installed check.
rpm_has() { rpm -q "$1" >/dev/null 2>&1; }

confirm() {
  (( ASSUME_YES )) && return 0
  local reply
  read -r -p "  ? $1 [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${C_BOLD}setup.sh${C_RESET} — bootstrap Fedora from the dotfiles repo

  --list             list phases and exit
  --only  a,b,c      run only these phases
  --skip  a,b,c      run everything except these
  --with-optional    include the 'optional' phase (flutter, android, flatpak, docker)
  --dry-run          print what would run, change nothing
  --yes, -y          never prompt
  --help, -h         this text

Phases: ${ALL_PHASES[*]}
EOF
}

parse_args() {
  local only="" skipped="" with_optional=0
  while (( $# )); do
    case "$1" in
      --list)          printf '%s\n' "${ALL_PHASES[@]}"; exit 0 ;;
      --only)          only="$2"; shift 2 ;;
      --only=*)        only="${1#*=}"; shift ;;
      --skip)          skipped="$2"; shift 2 ;;
      --skip=*)        skipped="${1#*=}"; shift ;;
      --with-optional) with_optional=1; shift ;;
      --dry-run|-n)    DRY_RUN=1; shift ;;
      --yes|-y)        ASSUME_YES=1; shift ;;
      --help|-h)       usage; exit 0 ;;
      *)               die "unknown argument: $1 (try --help)" ;;
    esac
  done

  if [[ -n $only ]]; then
    IFS=, read -r -a PHASES <<<"$only"
    for p in "${PHASES[@]}"; do
      [[ " ${ALL_PHASES[*]} " == *" $p "* ]] || die "unknown phase: $p"
    done
    return
  fi

  PHASES=("${DEFAULT_PHASES[@]}")
  (( with_optional )) && PHASES+=(optional)

  if [[ -n $skipped ]]; then
    local keep=() s p drop
    IFS=, read -r -a s <<<"$skipped"
    for p in "${PHASES[@]}"; do
      drop=0
      for x in "${s[@]}"; do [[ $p == "$x" ]] && drop=1; done
      (( drop )) || keep+=("$p")
    done
    PHASES=("${keep[@]}")
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: preflight
# ─────────────────────────────────────────────────────────────────────────────
phase_preflight() {
  [[ $EUID -ne 0 ]] || die "do not run as root — the script sudo's only where needed"

  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    [[ ${ID:-} == fedora ]] || warn "expected Fedora, found ${PRETTY_NAME:-unknown} — dnf phases may not fit"
    info "target: ${PRETTY_NAME:-unknown}"
  fi

  have sudo || die "sudo is required"
  have curl || have wget || die "curl or wget is required to fetch repos and tarballs"

  if ! (( DRY_RUN )); then
    info "priming sudo"
    sudo -v || die "sudo authentication failed"
    # Keep the sudo timestamp alive for the whole run.
    ( while true; do sleep 60; sudo -n true 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE=$!
    trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT
  fi

  if ! curl -fsS --max-time 10 https://api.github.com/ >/dev/null 2>&1; then
    warn "github.com is unreachable — the neovim and rustup phases will fail"
  fi
  ok "preflight done"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: repos — third-party repositories the package set depends on
# ─────────────────────────────────────────────────────────────────────────────
copr_enable() {
  local project="$1" repofile
  repofile="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${project/\//:}.repo"
  if [[ -f $repofile ]]; then
    skip "copr $project already enabled"
  else
    info "enabling copr $project"
    run sudo dnf -y copr enable "$project" || fail "copr enable $project"
  fi
}

phase_repos() {
  # dnf5 moved copr into a plugin that is not always present.
  if ! dnf copr --help >/dev/null 2>&1; then
    info "installing dnf copr plugin"
    run sudo dnf -y install dnf-plugins-core || fail "dnf-plugins-core"
  fi

  # starship, lazygit and yazi have no package in the Fedora repos.
  copr_enable atim/starship
  copr_enable dejan/lazygit
  copr_enable lihaohong/yazi

  # RPM Fusion: multimedia codecs and the NVIDIA driver path.
  local ver; ver=$(rpm -E %fedora)
  if rpm_has rpmfusion-free-release; then
    skip "rpmfusion already enabled"
  else
    info "enabling rpmfusion free + nonfree"
    run sudo dnf -y install \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${ver}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${ver}.noarch.rpm" \
      || fail "rpmfusion"
  fi
  ok "repositories ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: dnf — every package the tracked configs reach for
# ─────────────────────────────────────────────────────────────────────────────
# Grouped so a failure names the group it came from.
PKGS_CORE=(git curl wget unzip tar gzip xz which findutils diffutils dbus-tools)
# diffutils: undotree shells out to `diff`. dbus-tools: nvim's system light/dark
# follower reads the XDG portal through dbus-monitor.

PKGS_BUILD=(gcc gcc-c++ make cmake pkgconf-pkg-config)
# Treesitter compiles every parser with cc; several Mason packages build from source.

PKGS_SHELL=(zsh bash-completion eza zoxide atuin fzf ripgrep fd-find jq btop
            git-delta wl-clipboard)
# Straight out of .bashrc/.zshrc: eza aliases, the zoxide `cd` wrapper, atuin
# history, fzf colors, delta for git/lazygit. wl-clipboard gives nvim a Wayland
# clipboard under KDE.

PKGS_COPR=(starship lazygit yazi)

# Fedora 44 dropped the unversioned nodejs/npm names for versioned streams.
NODE_STREAM="${NODE_STREAM:-22}"
PKGS_LANG=(golang golang-bin "nodejs${NODE_STREAM}" "nodejs${NODE_STREAM}-npm"
           python3 python3-pip python3-devel pipx
           java-latest-openjdk-devel dotnet-sdk-9.0)
# go: .bashrc calls `go env GOPATH` on every shell start, and gopls/delve need it.
# node+npm: Mason installs 20+ servers through npm. java: kotlin and gradle
# language servers plus their debug adapter. dotnet: easy-dotnet's Roslyn LSP,
# netcoredbg and powershell-editor-services.

PKGS_DEVOPS=(ansible-core python3-ansible-lint podman)
# ansible-language-server shells out to ansible and ansible-lint; Mason ships
# neither, so they come from dnf and match what CI uses.

PKGS_DESKTOP=(konsole)

phase_dnf() {
  local missing=() pkgs=(
    "${PKGS_CORE[@]}" "${PKGS_BUILD[@]}" "${PKGS_SHELL[@]}" "${PKGS_COPR[@]}"
    "${PKGS_LANG[@]}" "${PKGS_DEVOPS[@]}" "${PKGS_DESKTOP[@]}"
  )

  for p in "${pkgs[@]}"; do
    rpm_has "$p" || missing+=("$p")
  done

  if (( ${#missing[@]} == 0 )); then
    skip "all ${#pkgs[@]} packages already installed"
  else
    info "installing ${#missing[@]} of ${#pkgs[@]} packages"
    printf '%s    %s%s\n' "$C_DIM" "${missing[*]}" "$C_RESET"
    # --skip-unavailable keeps one renamed package from aborting the batch.
    run sudo dnf -y install --skip-unavailable "${missing[@]}" || fail "dnf install"
  fi

  # The gh CLI is handy but not required by any config.
  if ! have gh && confirm "install the GitHub CLI (gh)?"; then
    run sudo dnf -y install gh || fail "gh"
  fi
  ok "packages done"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: neovim — official tarball into /opt/nvim
# ─────────────────────────────────────────────────────────────────────────────
# Fedora's neovim lags behind, and this config needs 0.11+ for vim.lsp.config /
# vim.lsp.enable and vim.fs.relpath. The upstream tarball is what the current
# machine runs, so the script reproduces it rather than using dnf.
phase_neovim() {
  local want="$NVIM_VERSION" have_ver=""
  if [[ $want == latest ]]; then
    want=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null \
           | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
    [[ -n $want ]] || { want="v0.12.2"; warn "could not reach the GitHub API, pinning $want"; }
  fi

  [[ -x $NVIM_PREFIX/bin/nvim ]] && have_ver="v$("$NVIM_PREFIX/bin/nvim" --version | sed -n '1s/^NVIM v//p')"
  if [[ -n $have_ver && $have_ver == "$want" ]]; then
    skip "neovim $have_ver already installed at $NVIM_PREFIX"
    return
  fi
  # Re-running the script should not silently move a working editor.
  if [[ -n $have_ver ]] && ! confirm "replace neovim $have_ver with $want?"; then
    skip "keeping neovim $have_ver"
    return
  fi

  info "installing neovim $want into $NVIM_PREFIX"
  local tmp tarball url
  tmp=$(mktemp -d); tarball="$tmp/nvim.tar.gz"
  url="https://github.com/neovim/neovim/releases/download/${want}/nvim-linux-x86_64.tar.gz"

  if (( DRY_RUN )); then
    printf '%s  $ curl -fsSL %s | sudo tar -xz -C /opt%s\n' "$C_DIM" "$url" "$C_RESET"
  else
    if ! curl -fsSL -o "$tarball" "$url"; then
      rm -rf "$tmp"; fail "download neovim $want"; return
    fi
    sudo rm -rf "$NVIM_PREFIX"
    sudo mkdir -p "$NVIM_PREFIX"
    sudo tar -xzf "$tarball" -C "$NVIM_PREFIX" --strip-components=1
    sudo ln -sfn "$NVIM_PREFIX/bin/nvim" /usr/local/bin/nvim
    rm -rf "$tmp"
  fi
  ok "neovim $want ready (/usr/local/bin/nvim -> $NVIM_PREFIX/bin/nvim)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: rust — rustup toolchain + the treesitter CLI
# ─────────────────────────────────────────────────────────────────────────────
# This has to land before the restored .bashrc is ever sourced: line 29 runs
# `. "$HOME/.cargo/env"` unconditionally and every new shell errors without it.
phase_rust() {
  if [[ -x $HOME/.cargo/bin/rustup ]]; then
    skip "rustup already installed"
  else
    info "installing rustup (stable toolchain)"
    if (( DRY_RUN )); then
      printf '%s  $ curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y%s\n' "$C_DIM" "$C_RESET"
    else
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path \
        || { fail "rustup install"; return; }
    fi
  fi

  # shellcheck disable=SC1091
  [[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"

  # nvim-treesitter's main branch generates some parsers with the tree-sitter CLI.
  if have tree-sitter; then
    skip "tree-sitter CLI already installed"
  else
    info "cargo install tree-sitter-cli (a few minutes)"
    run cargo install tree-sitter-cli || fail "tree-sitter-cli"
  fi
  ok "rust toolchain ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: dotfiles — bare clone and checkout into $HOME
# ─────────────────────────────────────────────────────────────────────────────
dotfiles_git() { git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$HOME" "$@"; }

phase_dotfiles() {
  if [[ -d $DOTFILES_GIT_DIR ]]; then
    skip "bare repo already at $DOTFILES_GIT_DIR"
  else
    info "cloning $DOTFILES_REPO"
    run git clone --bare "$DOTFILES_REPO" "$DOTFILES_GIT_DIR" || { fail "clone dotfiles"; return; }
  fi

  if (( DRY_RUN )); then
    printf '%s  $ dotfiles checkout  (backing up collisions to %s)%s\n' "$C_DIM" "$BACKUP_DIR" "$C_RESET"
    return
  fi

  # Fedora ships its own .bashrc/.bash_profile and the repo tracks .bashrc,
  # .zshrc and .gitconfig — move anything in the way rather than clobbering it.
  if ! dotfiles_git checkout 2>/dev/null; then
    info "backing up colliding files to $BACKUP_DIR"
    local f
    while IFS= read -r f; do
      [[ -n $f && -e $HOME/$f ]] || continue
      mkdir -p "$BACKUP_DIR/$(dirname "$f")"
      mv "$HOME/$f" "$BACKUP_DIR/$f"
      printf '%s      moved %s%s\n' "$C_DIM" "$f" "$C_RESET"
    done < <(dotfiles_git checkout 2>&1 | sed -n 's/^[[:space:]]\{1,\}\([^[:space:]].*\)$/\1/p')

    dotfiles_git checkout || { fail "dotfiles checkout"; return; }
  fi

  dotfiles_git config --local status.showUntrackedFiles no
  ok "dotfiles checked out ($(dotfiles_git ls-files | wc -l) files tracked)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: python — the two things Mason deliberately does not provide
# ─────────────────────────────────────────────────────────────────────────────
phase_python() {
  # cmake-language-server: Mason pins python <3.14 and Fedora ships 3.14, so it
  # is installed through pipx instead. pygls must stay on v1 — the server
  # imports pygls.server.LanguageServer, which pygls 2 removed.
  if have cmake-language-server; then
    skip "cmake-language-server already installed"
  else
    info "pipx install cmake-language-server"
    if run pipx install cmake-language-server; then
      run pipx inject cmake-language-server "pygls<2" || fail "pipx inject pygls<2"
    else
      fail "cmake-language-server"
    fi
  fi

  # ansibug is the DAP adapter for yaml.ansible; lua/configs/dap.lua only wires
  # it up when it is on PATH. Not in Mason, and it imports the dnf ansible-core.
  if have ansibug; then
    skip "ansibug already installed"
  else
    info "pip install --user ansibug"
    run python3 -m pip install --user --upgrade ansibug || fail "ansibug"
  fi
  ok "python tooling ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: nvim-setup — plugins, Mason packages, treesitter parsers
# ─────────────────────────────────────────────────────────────────────────────
phase_nvim_setup() {
  [[ -f $HOME/.config/nvim/init.lua ]] || { fail "no ~/.config/nvim/init.lua — run the dotfiles phase first"; return; }
  have nvim || { fail "nvim is not on PATH"; return; }

  # shellcheck disable=SC1091
  [[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
  export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

  info "syncing lazy.nvim plugins (pinned by lazy-lock.json)"
  run nvim --headless "+Lazy! restore" +qa 2>&1 | tail -3

  info "installing treesitter parsers — 60+ grammars, this compiles"
  run nvim --headless -c 'lua require("configs.treesitter").build()' -c 'qa' 2>&1 | tail -3

  info "installing Mason packages — ~70 servers, linters and debug adapters"
  # MasonEnsure kicks off async installs; give them room and then report.
  run nvim --headless -c 'MasonEnsure' -c 'lua vim.wait(900000, function() local r = require("mason-registry") for _, p in ipairs(r.get_all_packages()) do if p:is_installing() then return false end end return true end, 2000)' -c 'qa' 2>&1 | tail -3

  ok "neovim provisioned — open nvim and run :checkhealth to confirm"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: shell — bash-preexec, zsh availability, default shell
# ─────────────────────────────────────────────────────────────────────────────
phase_shell() {
  # .bashrc sources this and self-downloads when absent; fetching it here keeps
  # the first interactive shell from doing network I/O.
  if [[ -f $HOME/.bash-preexec.sh ]]; then
    skip "bash-preexec already present"
  else
    info "fetching bash-preexec"
    run curl -fsSL -o "$HOME/.bash-preexec.sh" \
      https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh \
      || fail "bash-preexec"
  fi

  # Referenced by .bashrc's PATH block; harmless if it stays empty.
  run mkdir -p "$HOME/bin" "$HOME/.local/bin"

  # yazi plugins are tracked in the repo, so a checkout already restores them.
  # This only pulls them forward to the revisions in package.toml.
  if have ya && [[ -f $HOME/.config/yazi/package.toml ]]; then
    info "syncing yazi plugins"
    run ya pkg install >/dev/null 2>&1 || warn "ya pkg install reported an issue (plugins are tracked, so this is non-fatal)"
  fi

  if have zsh && [[ ${SHELL:-} != *zsh && ${SHELL:-} != *bash ]]; then
    warn "login shell is ${SHELL:-unset}; the repo configures bash and zsh"
  fi
  ok "shell environment ready"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: kde — Konsole profiles and colour schemes
# ─────────────────────────────────────────────────────────────────────────────
# The profiles and .colors files arrive with the checkout under
# ~/.local/share/{konsole,color-schemes}. KDE reads them at next login; the rc
# files under ~/.config apply the same way.
phase_kde() {
  local n
  n=$(ls "$HOME/.local/share/konsole/"*.profile 2>/dev/null | wc -l)
  if (( n > 0 )); then
    ok "$n Konsole profile(s) in place — pick one in Settings ▸ Manage Profiles"
  else
    warn "no Konsole profiles found; did the dotfiles phase run?"
  fi

  if have konsole; then
    info "Konsole follows the desktop light/dark switch via SyncProfileWithSystemTheme in ~/.config/konsolerc"
  fi
  # Panel Colorizer preset and the custom Plasma themes are not tracked in this
  # repo and have to be re-applied by hand after login.
  warn "not covered here: the Panel Colorizer preset and the Rajko-Light Plasma theme"
  ok "KDE assets restored (log out and back in to apply)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase: optional — big toolchains only some machines need
# ─────────────────────────────────────────────────────────────────────────────
phase_optional() {
  # Flutter: a git clone under ~/.flutter, exactly what .bashrc puts on PATH.
  if [[ -d $HOME/.flutter/flutter ]]; then
    skip "flutter already cloned"
  elif confirm "install Flutter into ~/.flutter/flutter?"; then
    run git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/.flutter/flutter" \
      && run "$HOME/.flutter/flutter/bin/flutter" --version || fail "flutter"
  fi

  # Android SDK: .bashrc exports ANDROID_HOME and adds emulator/platform-tools.
  if [[ -d $HOME/Android/Sdk ]]; then
    skip "android sdk already present"
  elif confirm "install the Android command-line tools into ~/Android/Sdk?"; then
    warn "install Android Studio or the cmdline-tools zip, then run: sdkmanager 'platform-tools' 'emulator'"
  fi

  # Docker CE: the machine this was built from has the docker-ce repo enabled.
  if have docker; then
    skip "docker already installed"
  elif confirm "add the Docker CE repo and install docker?"; then
    run sudo dnf -y config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
      || run sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    run sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
      && run sudo systemctl enable --now docker \
      && run sudo usermod -aG docker "$USER" \
      && warn "log out and back in for the docker group to take effect"
  fi

  # Flatpak apps. Flathub is where the GUI stack on the reference machine lives.
  if have flatpak && confirm "add Flathub and install the desktop app set?"; then
    run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    local apps=(
      com.bitwarden.desktop app.zen_browser.zen com.brave.Browser com.google.Chrome
      com.slack.Slack com.github.IsmaelMartinez.teams_for_linux com.rustdesk.RustDesk
      com.getpostman.Postman com.usebruno.Bruno com.jgraph.drawio.desktop
      com.microsoft.AzureStorageExplorer com.unity.UnityHub com.usebottles.bottles
    )
    run flatpak install -y --noninteractive flathub "${apps[@]}" || fail "flatpak apps"
  fi
  ok "optional phase done"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"

  printf '%s%s\n  Fedora dotfiles bootstrap%s\n' "$C_BOLD" "$C_BLUE" "$C_RESET"
  printf '  repo    %s\n' "$DOTFILES_REPO"
  printf '  phases  %s\n' "${PHASES[*]}"
  (( DRY_RUN )) && printf '  %sdry run — nothing will change%s\n' "$C_YELLOW" "$C_RESET"

  local start=$SECONDS phase fn
  for phase in "${PHASES[@]}"; do
    phase_header "$phase"
    fn="phase_${phase//-/_}"
    "$fn"
  done

  phase_header "summary"
  if (( ${#FAILED[@]} )); then
    printf '  %s%d step(s) failed:%s\n' "$C_RED" "${#FAILED[@]}" "$C_RESET"
    printf '    · %s\n' "${FAILED[@]}"
  else
    ok "every phase completed in $((SECONDS - start))s"
  fi

  cat <<EOF

  ${C_BOLD}Next${C_RESET}
    1. Open a new shell so the restored .bashrc takes effect.
    2. Run ${C_BOLD}nvim${C_RESET} and check ${C_BOLD}:checkhealth${C_RESET}, then ${C_BOLD}:Mason${C_RESET} for anything still missing.
    3. Log out and back in for the KDE rc files and Konsole profiles.
    4. ${C_BOLD}atuin login${C_RESET} if you sync shell history; it is not configured by the repo.
EOF
  (( ${#FAILED[@]} )) && exit 1
  exit 0
}

main "$@"
