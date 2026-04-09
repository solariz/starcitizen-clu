#!/usr/bin/env bash

# SC.CLU - Star Citizen Component Language Updater (bash port)

set -euo pipefail

VER="2026-04-09"
GAME="Star Citizen"
PACK="Custom Language Pack"

MINLINES=6000
MINSIZE=6291456

RESET=$'\e[0m'
BOLD=$'\e[1m'
CYAN=$'\e[96m'   # bright cyan
GREEN=$'\e[92m'  # bright green
YELLOW=$'\e[93m' # bright yellow
RED=$'\e[91m'    # bright red
GRAY=$'\e[37m'   # light gray
WHITE=$'\e[97m'  # bright white

LIVE_DIR=""
ENGLISH_DIR=""
TARGET_DIR=""
SC_VERSION="unknown"
URL_BELTAKODA=""
BELTAKODA_SOURCE=""
EXOAE_REMIX_STATUS=""
EXOAE_LONG_STATUS=""
BELTAKODA_TAG=""
BELTAKODA_STATUS=""
URL=""
PACK_NAME=""
TARGET=""

TMPFILE="$(mktemp /tmp/global_XXXXXX.ini)"

# cleanup removes the temporary file when the script exits.
cleanup() {
  rm -f "$TMPFILE"
}

trap cleanup EXIT

# check_dependencies verifies that all required external tools are installed.
check_dependencies() {
  local missing=()

  for cmd in curl stat wc cmp grep sed; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo -e "${RED}${BOLD}Missing required tools: ${missing[*]}${RESET}"
    echo -e "${YELLOW}Install them and try again.${RESET}"
    exit 1
  fi
}

# is_live_dir checks whether the given directory looks like a valid LIVE folder.
is_live_dir() {
  local dir="$1"
  local datap4k=""
  local exe=""

  for name in Data.p4k data.p4k DATA.P4K; do
    if [ -f "$dir/$name" ]; then
      datap4k="yes"
      break
    fi
  done

  for name in Bin64/StarCitizen.exe bin64/StarCitizen.exe BIN64/StarCitizen.exe; do
    if [ -f "$dir/$name" ]; then
      exe="yes"
      break
    fi
  done

  [ -n "$datap4k" ] && [ -n "$exe" ]
}

# check_url_status returns the HTTP status code for a HEAD request to the given URL.
check_url_status() {
  local url="$1"

  curl -s -L -o /dev/null -w "%{http_code}" --head "$url" 2>/dev/null || echo "000"
}

# debug_dump prints diagnostic information after a failure.
debug_dump() {
  local last_status="$1"

  echo
  echo -e "${RED}${BOLD}--- DEBUG INFORMATION ---${RESET}"
  echo -e "${GRAY}Temp file   : ${TMPFILE}${RESET}"
  echo -e "${GRAY}Target file : ${TARGET:-<unset>}${RESET}"
  echo -e "${GRAY}URL used    : ${URL:-<unset>}${RESET}"

  if [ -f "$TMPFILE" ]; then
    local size

    size="$(stat -c%s "$TMPFILE" 2>/dev/null || echo "?")"
    echo -e "${GRAY}Temp size   : ${size} bytes${RESET}"
    echo -e "${GRAY}Showing first 20 lines:${RESET}"
    head -n 20 "$TMPFILE" || true
  else
    echo -e "${RED}Temp file does NOT exist.${RESET}"
  fi

  echo -e "${GRAY}Last status : ${last_status}${RESET}"
  echo -e "${RED}${BOLD}--------------------------${RESET}"
}

# show_header prints the ASCII banner and introduction.
show_header() {
  clear || true
  echo ""
  echo -e "${CYAN}"
  echo ' _____ _____  _____  _     _   _ '
  echo '/  ___/  __ \/  __ \| |   | | | |'
  echo '\ `--.| /  \/| /  \/| |   | | | |'
  echo ' `--. \ |    | |    | |   | | | |'
  echo '/\__/ / \__/\| \__/\| |___| |_| |'
  echo '\____/ \____(_)____/\_____/\___/ '
  echo -e "${RESET}${BOLD}SC.CLU ${VER}${RESET}  Component Lang Updater"
  echo -e "${GRAY}github.com/solariz/starcitizen-clu${RESET}"
  echo
  echo -e "${GRAY}This tool downloads community language packs that rename${RESET}"
  echo -e "${GRAY}component names to better human-readable formats.${RESET}"
  echo
  echo -e "${GRAY}Language Pack Credits:${RESET}"
  echo -e "  ${CYAN}ExoAE${RESET}    - github.com/ExoAE/ScCompLangPack"
  echo -e "  ${CYAN}BeltaKoda${RESET} - github.com/BeltaKoda/ScCompLangPackRemix"
  echo -e "${GRAY}============================================================${RESET}"
  echo
}

# detect_live_dir determines the LIVE and English localization directories.
detect_live_dir() {
  local check_live

  check_live="$(cd "../../.." 2>/dev/null && pwd)" || check_live=""
  if [ -n "$check_live" ] && is_live_dir "$check_live"; then
    LIVE_DIR="$check_live"
    ENGLISH_DIR="$(pwd)"
    TARGET_DIR="$ENGLISH_DIR"
  fi

  if [ -z "${LIVE_DIR:-}" ] && is_live_dir "$(pwd)"; then
    LIVE_DIR="$(pwd)"
    ENGLISH_DIR="$LIVE_DIR/data/Localization/english"
    TARGET_DIR="$ENGLISH_DIR"
  fi

  if [ -z "${LIVE_DIR:-}" ]; then
    local check_dir
    local parent

    check_dir="$(pwd)"
    while true; do
      if is_live_dir "$check_dir"; then
        LIVE_DIR="$check_dir"
        ENGLISH_DIR="$check_dir/data/Localization/english"
        TARGET_DIR="$ENGLISH_DIR"
        break
      fi

      parent="$(dirname "$check_dir")"
      if [ "$parent" = "$check_dir" ]; then
        break
      fi

      check_dir="$parent"
    done
  fi

  if [ -z "${LIVE_DIR:-}" ]; then
    echo -e "${RED}${BOLD}ERROR: INVALID LOCATION${RESET}"
    echo
    echo -e "${YELLOW}This script must be placed inside the LIVE folder of your${RESET}"
    echo -e "${YELLOW}Star Citizen installation.${RESET}"
    echo
    echo -e "${GRAY}Example location (Wine/Proton):${RESET}"
    echo -e "  /home/.../Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen/LIVE/"
    echo
    echo -e "${GRAY}The LIVE folder must contain:${RESET}"
    echo -e "  ${GRAY}- Data.p4k${RESET}"
    echo -e "  ${GRAY}- Bin64/StarCitizen.exe${RESET}"
    echo
    exit 1
  fi

  mkdir -p "$TARGET_DIR"
}

# extract_game_version reads build_manifest.id and extracts the game version.
extract_game_version() {
  local manifest_file
  local branch_raw
  local full_version

  SC_VERSION="unknown"
  manifest_file="$LIVE_DIR/build_manifest.id"

  if [ -f "$manifest_file" ]; then
    branch_raw="$(grep -i '"Branch"' "$manifest_file" | head -n 1 \
      | sed 's/.*"Branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
      | tr -d '[:space:]' || true)"

    if [ -n "$branch_raw" ]; then
      SC_VERSION="$(printf "%s" "$branch_raw" | cut -d'-' -f3)"
      if [ -z "$SC_VERSION" ]; then
        SC_VERSION="unknown"
      fi
    fi

    full_version="$(grep -i '"Version"' "$manifest_file" | head -n 1 \
      | sed 's/.*"Version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
      | tr -d '[:space:]' || true)"
  fi

  echo -e "${GRAY}============================================================${RESET}"
  echo -e " Detected Game Version: ${GREEN}${BOLD}${SC_VERSION}${RESET}\t${GRAY}(${full_version:-unknown})${RESET}"
  echo -e " Installation Path: ${GRAY}${LIVE_DIR}${RESET}"
  echo -e "${GRAY}============================================================${RESET}"
  echo
}

# probe_beltakoda queries the GitHub releases API for the latest BeltaKoda tag and
# constructs the download URL from it, avoiding any reliance on local version detection.
probe_beltakoda() {
  URL_BELTAKODA=""
  BELTAKODA_SOURCE=""
  BELTAKODA_TAG=""

  local api_url="https://api.github.com/repos/BeltaKoda/ScCompLangPackRemix/releases/latest"
  local tag_name

  tag_name="$(curl -sf "$api_url" \
    | grep '"tag_name"' \
    | head -n 1 \
    | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
    | tr -d '[:space:]')" || tag_name=""

  if [ -n "$tag_name" ]; then
    local probe_url
    local env_suffix

    if [[ "$tag_name" == *"-LIVE" ]]; then
      env_suffix="LIVE"
    elif [[ "$tag_name" == *"-PTU" ]]; then
      env_suffix="PTU"
    else
      env_suffix=""
    fi

    if [ -n "$env_suffix" ]; then
      probe_url="${URL_BELTAKODA_BASE}/${tag_name}/${env_suffix}/data/Localization/english/global.ini"
      local code
      code="$(check_url_status "$probe_url")"
      if [ "$code" = "200" ]; then
        URL_BELTAKODA="$probe_url"
        BELTAKODA_SOURCE="$env_suffix"
        BELTAKODA_TAG="$tag_name"
      fi
    fi
  fi
}

# check_availability probes all language pack URLs and builds status strings.
check_availability() {
  echo -e "${CYAN}Checking language pack availability...${RESET}"
  echo

  local code

  EXOAE_REMIX_STATUS="${RED}UNAVAILABLE${RESET}"
  code="$(check_url_status "$URL_EXOAE_REMIX")"
  if [ "$code" = "200" ]; then
    EXOAE_REMIX_STATUS="${GREEN}Available${RESET}"
  fi

  EXOAE_LONG_STATUS="${RED}UNAVAILABLE${RESET}"
  code="$(check_url_status "$URL_EXOAE_LONG")"
  if [ "$code" = "200" ]; then
    EXOAE_LONG_STATUS="${GREEN}Available${RESET}"
  fi

  BELTAKODA_STATUS="${RED}UNAVAILABLE (no matching release found)${RESET}"
  if [ -n "${URL_BELTAKODA:-}" ]; then
    BELTAKODA_STATUS="${GREEN}Available (${BELTAKODA_SOURCE} - ${BELTAKODA_TAG})${RESET}"
  fi
}

# first_time_setup handles the one-time user.cfg update when no global.ini exists.
first_time_setup() {
  if [ ! -f "$TARGET_DIR/global.ini" ]; then
    clear || true
    echo -e "${YELLOW}${BOLD}"
    echo "============================================================"
    echo "         NO PREVIOUS INSTALLATION DETECTED"
    echo "============================================================"
    echo -e "${RESET}${GRAY}"
    echo "We did not find a previous language pack installation."
    echo
    echo "Do you want to download the ${WHITE}${PACK_NAME}${GRAY} language pack"
    echo "and let us set everything up for you?"
    echo -e "${RESET}"
    echo

    local setup_choice

    read -rp "Download and setup language pack? (Y/N): " setup_choice
    if [ "${setup_choice^^}" != "Y" ]; then
      echo
      echo -e "${GRAY}Setup cancelled.${RESET}"
      exit 0
    fi

    local usercfg
    local has_language_line

    usercfg="$LIVE_DIR/user.cfg"
    has_language_line=0

    if [ -f "$usercfg" ]; then
      if grep -qi "g_language" "$usercfg"; then
        has_language_line=1
      fi
    fi

    if [ "$has_language_line" -eq 0 ]; then
      echo -e "${CYAN}Updating user.cfg...${RESET}"
      if [ ! -f "$usercfg" ]; then
        echo "g_language = english" >"$usercfg"
      else
        echo "" >>"$usercfg"
        echo "g_language = english" >>"$usercfg"
      fi
      echo -e "${GREEN}user.cfg updated.${RESET}"
      echo
    fi

    echo
  fi
}

# show_update_header prints the summary before download and installation.
show_update_header() {
  clear || true
  echo -e "${CYAN}${BOLD}"
  echo "============================================================"
  echo "       STAR CITIZEN - CUSTOM LANGUAGE UPDATE"
  echo "============================================================"
  echo -e "${RESET}${GRAY}"
  echo " Game       : ${GAME}"
  echo " Version    : ${SC_VERSION}"
  echo " Pack       : ${PACK_NAME}"
  echo " Location   : ${TARGET_DIR}"
  echo "============================================================"
  echo -e "${RESET}"
  echo
}

# download_and_validate runs the download and validation pipeline and installs the file.
download_and_validate() {
  TARGET="${TARGET_DIR}/global.ini"

  echo -e "${CYAN}[1/4] Fetching latest language data...${RESET}"
  echo

  if ! curl --fail --location --show-error --progress-bar \
    --connect-timeout 15 --max-time 120 "$URL" -o "$TMPFILE"; then
    local status="$?"

    echo
    echo -e "${RED}Download failed or timed out.${RESET}"
    debug_dump "$status"
    exit 1
  fi

  if [ ! -f "$TMPFILE" ]; then
    echo -e "${RED}Temp file not created.${RESET}"
    debug_dump "temp-missing"
    exit 1
  fi

  echo -e "${GREEN}Download completed.${RESET}"
  echo

  echo -e "${CYAN}[2/4] Verifying file size...${RESET}"

  local filesize

  filesize="$(stat -c%s "$TMPFILE")"
  echo -e "${GRAY}    Size detected: ${filesize} bytes${RESET}"

  if [ "$filesize" -lt "$MINSIZE" ]; then
    echo -e "${RED}File too small (needs > 6 MB).${RESET}"
    debug_dump "size-check"
    exit 1
  fi

  echo -e "${GREEN}Size check passed.${RESET}"
  echo

  echo -e "${CYAN}[3/4] Counting translation entries...${RESET}"
  printf "%s" "${GRAY}    Processing... "

  local linecount

  linecount="$(wc -l <"$TMPFILE")"
  echo -e "done${RESET}"
  echo -e "${GRAY}    Lines detected: ${linecount}${RESET}"

  if [ -z "$linecount" ] || ! printf "%s" "$linecount" | grep -Eq '^[0-9]+$'; then
    echo -e "${RED}Failed to determine line count.${RESET}"
    debug_dump "line-count"
    exit 1
  fi

  if [ "$linecount" -lt "$MINLINES" ]; then
    echo -e "${RED}Not enough entries (needs at least ${MINLINES}).${RESET}"
    debug_dump "line-count"
    exit 1
  fi

  echo -e "${GREEN}Content check passed.${RESET}"
  echo

  echo -e "${CYAN}[4/4] Checking existing installation...${RESET}"

  if [ -f "$TARGET" ]; then
    printf "%s" "${GRAY}    Comparing files... "
    if cmp -s "$TARGET" "$TMPFILE"; then
      echo -e "skipped${RESET}"
      echo -e "${YELLOW}Language pack already up to date. No changes made.${RESET}"
      exit 0
    fi
    echo -e "done${RESET}"
  fi

  echo -e "${GREEN}New version detected. Installing update...${RESET}"
  mkdir -p "$TARGET_DIR"
  cp -f "$TMPFILE" "$TARGET"

  echo
  echo -e "${GREEN}${BOLD}Update complete!${RESET}"
  echo -e "${GRAY}You are ready to launch Star Citizen.${RESET}"
}

# show_menu_loop presents the user with the pack selection menu.
show_menu_loop() {
  while true; do
    echo -e "${WHITE}${BOLD}  SELECT YOUR PREFERRED NAMING STYLE:${RESET}"
    echo -e "${GRAY}-------------------------------------------------------------${RESET}"
    echo
    echo -e "  ${CYAN}[1]${RESET} ExoAE Remix Version"
    echo -e "      ${GRAY}Example:${RESET} ${YELLOW}MIL-2A \"XL-1\"${RESET}"
    echo -e "      ${GRAY}Status:${RESET} ${EXOAE_REMIX_STATUS}"
    echo
    echo -e "  ${CYAN}[2]${RESET} ExoAE Long Version"
    echo -e "      ${GRAY}Example:${RESET} ${YELLOW}XL-1 Military A${RESET}"
    echo -e "      ${GRAY}Status:${RESET} ${EXOAE_LONG_STATUS}"
    echo
    echo -e "  ${CYAN}[3]${RESET} BeltaKoda Alternate Short Version"
    echo -e "      ${GRAY}Example:${RESET} ${YELLOW}M2A XL-1${RESET}"
    echo -e "      ${GRAY}Status:${RESET} ${BELTAKODA_STATUS}"
    echo
    echo -e "  ${CYAN}[Q]${RESET} ${GRAY}Quit${RESET}"
    echo
    echo -e "${GRAY}-------------------------------------------------------------${RESET}"
    echo

    local choice

    read -rp "  Enter your choice (1-3 or Q): " choice

    case "${choice,,}" in
      q)
        exit 0
        ;;
      1)
        URL="$URL_EXOAE_REMIX"
        PACK_NAME="ExoAE Remix"
        TARGET="${TARGET_DIR}/global.ini"
        first_time_setup
        show_update_header
        download_and_validate
        return
        ;;
      2)
        URL="$URL_EXOAE_LONG"
        PACK_NAME="ExoAE Long"
        TARGET="${TARGET_DIR}/global.ini"
        first_time_setup
        show_update_header
        download_and_validate
        return
        ;;
      3)
        if [ -z "${URL_BELTAKODA:-}" ]; then
          echo
          echo -e "${RED}BeltaKoda pack is not available for version ${SC_VERSION}${RESET}"
          echo -e "${YELLOW}Please select another option or wait for the author to update.${RESET}"
          echo
          read -rp "Press Enter to continue..." _
          continue
        fi

        URL="$URL_BELTAKODA"
        PACK_NAME="BeltaKoda Alternate"
        TARGET="${TARGET_DIR}/global.ini"
        first_time_setup
        show_update_header
        download_and_validate
        return
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 2
        ;;
    esac
  done
}

# main coordinates dependency checks, detection, probing, and user interaction.
main() {
  check_dependencies

  URL_EXOAE_REMIX="https://github.com/ExoAE/ScCompLangPack/raw/refs/heads/main/ScCompLangPackRemix2/data/Localization/english/global.ini"
  URL_EXOAE_LONG="https://github.com/ExoAE/ScCompLangPack/raw/refs/heads/main/ScCompLangPack/data/Localization/english/global.ini"
  URL_BELTAKODA_BASE="https://raw.githubusercontent.com/BeltaKoda/ScCompLangPackRemix/refs/tags"

  show_header
  detect_live_dir
  extract_game_version
  probe_beltakoda
  check_availability
  show_menu_loop

  echo
  read -rsp $'\nPress any key to exit...' -n1 || true
  echo
}

main "$@"
