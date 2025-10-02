autoload colors && colors || {
  echo "Error: Unable to load colors. Please check your Zsh configuration."
  return 1
}

: "${ORG_HOPPER_CACHE_LOCATION:=$HOME}"
: "${ORG_HOPPER_REPO_DIRECTORY:=$HOME/$ORG_HOPPER_ORG}"
: "${ORG_HOPPER_COLOR_RECENT:=cyan}"
: "${ORG_HOPPER_COLOR_OUTDATED:=red}"
: "${ORG_HOPPER_TOPIC:=}"

ORG_HOPPER_CACHE_FILE="${ORG_HOPPER_CACHE_LOCATION}/.org_hopper.cache"

function __orgHopperGetLastUpdated {
  echo $(sed -n '1p' "$ORG_HOPPER_CACHE_FILE")
}
function __orgHopperGetAgeSeconds {
  local last_updated_time=$(__orgHopperGetLastUpdated)
  local current_time=$(date +%s)
  local age_seconds=$((current_time - last_updated_time))

  echo "$age_seconds"
}

function __orgHopperEchoLastUpdated {
  if [ ! -f "$ORG_HOPPER_CACHE_FILE" ]; then
    echo "$fg[red]Cache file does not exist. Please refresh the cache.$reset_color"
    return 1
  fi

  local age_seconds=$(__orgHopperGetAgeSeconds)

  local color="$ORG_HOPPER_COLOR_RECENT"
  if ((age_seconds > 60 * 60 * 24 * 14)); then
    color="$ORG_HOPPER_COLOR_OUTDATED"
  fi
  echo "$fg[$color]Cache last updated on $(date -r "$(__orgHopperGetLastUpdated)")$reset_color"

  local days=$((age_seconds / 86400))
  local hours=$((age_seconds % 86400 / 3600))
  local minutes=$((age_seconds % 3600 / 60))
  echo "$fg[$color]$days days, $hours hours, $minutes minutes ago$reset_color"

  if [ "$color" = "$ORG_HOPPER_COLOR_OUTDATED" ]; then
    echo "$fg[green]Run 'orghop refresh' to update.$reset_color"
  fi
}

function __orgHopperFuzzyFind {
  local age_seconds=$(__orgHopperGetAgeSeconds)

  if [ ! -f "$ORG_HOPPER_CACHE_FILE" ]; then
    __orgHopperRefresh
  elif ! grep -iqE "^$ORG_HOPPER_ORG" "$ORG_HOPPER_CACHE_FILE"; then
    echo "$fg[yellow]Cache found but is for a different organization. Refreshing...$reset_color"
    __orgHopperRefresh
  elif ((age_seconds > 60 * 60 * 24 * 60)); then
    echo "$fg[yellow]Cache is outdated. Refreshing...$reset_color"
    __orgHopperRefresh
  else
    __orgHopperEchoLastUpdated
  fi

  local selection=$(sed '1d' "$ORG_HOPPER_CACHE_FILE" | fzf)
  if [ -z "$selection" ]; then
    echo "$fg[red]No selection made. Aborting.$reset_color"
    return 0
  fi

  local repo_name=$(cut -d "/" -f2 <<< "$selection")
  local repo_directory="${REPO_DIRECTORY:-$ORG_HOPPER_REPO_DIRECTORY}/$repo_name"

  if [ -d "$repo_directory" ]; then
    cd "$repo_directory" || return 1
  else
    echo "$fg[blue]Cloning $selection into $repo_directory...$reset_color"
    gh repo clone "$selection" "$repo_directory" && cd "$repo_directory" || {
      echo "$fg[red]Failed to clone repository. Please check your network or GitHub credentials.$reset_color"
      return 1
    }
  fi
}

function __orgHopperRefresh {
  echo "$fg[blue]Refreshing repositories for '$ORG_HOPPER_ORG'...$reset_color"
  local results
  local gh_command="gh repo list \"$ORG_HOPPER_ORG\" -L 300 --no-archived"

  if [ -n "$ORG_HOPPER_TOPIC" ]; then
    gh_command="$gh_command --topic \"$ORG_HOPPER_TOPIC\""
    echo "$fg[blue]Filtering by topic: '$ORG_HOPPER_TOPIC'$reset_color"
  fi

  gh_command="$gh_command --json nameWithOwner -q '.[].nameWithOwner'"

  if ! results=$(eval "$gh_command"); then
    echo "$fg[red]Failed to fetch repository list. Please check your GitHub credentials.$reset_color"
    return 1
  fi

  mkdir -p "$ORG_HOPPER_CACHE_LOCATION"
  date +%s > "$ORG_HOPPER_CACHE_FILE"
  echo "$results" >> "$ORG_HOPPER_CACHE_FILE"
  echo "$fg[blue]Updated $(echo "$results" | wc -l | xargs) repositories for '$ORG_HOPPER_ORG'.$reset_color"
}

function __orgHopperEchoInfo {
  echo "$fg[blue]org-hopper
Fuzzy find GitHub repositories in an organization.

Available commands:
$fg[green]<none>$reset_color     Open fuzzy finder for current repository cache
$fg[green]refresh$reset_color    Refresh repository cache
$fg[green]age$reset_color        Check the age of the current repository cache

Current configuration:
$fg[yellow]ORG_HOPPER_ORG:$reset_color $fg[green]${ORG_HOPPER_ORG:-Not set}$reset_color
$fg[yellow]ORG_HOPPER_TOPIC:$reset_color $fg[green]${ORG_HOPPER_TOPIC:-Not set}$reset_color
$fg[yellow]ORG_HOPPER_REPO_DIRECTORY:$reset_color $fg[green]$ORG_HOPPER_REPO_DIRECTORY$reset_color
$fg[yellow]ORG_HOPPER_CACHE_LOCATION:$reset_color $fg[green]$ORG_HOPPER_CACHE_LOCATION$reset_color
$fg[yellow]ORG_HOPPER_CACHE_FILE:$reset_color $fg[green]$ORG_HOPPER_CACHE_FILE$reset_color"
}

function orghop {
  if [ -z "$ORG_HOPPER_ORG" ]; then
    echo "$fg[red]Unable to start org-hopper: Missing environment variable ORG_HOPPER_ORG. Please set it in your ~/.zshrc.$reset_color"
    return 1
  fi

  case "$1" in
    "") __orgHopperFuzzyFind ;;
    "refresh") __orgHopperRefresh ;;
    "age") __orgHopperEchoLastUpdated ;;
    *) __orgHopperEchoInfo ;;
  esac
}
