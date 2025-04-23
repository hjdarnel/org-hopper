## org-hopper

`org-hopper` is an [`oh-my-zsh`](https://github.com/ohmyzsh/ohmyzsh/wiki/Customization#overriding-and-adding-plugins) plugin which wraps the GitHub CLI with fzf. It allows you to quickly jump between repositories a given GitHub organization, cloning it to a predefined location if the local copy doesn't already exist.

### Requirements

Installed and on PATH:

- `gh` - [docs](https://cli.github.com/) -  used to fetch repositories and clone them, must be configured already to be able to browse the organization
- `fzf` - [docs](https://github.com/junegunn/fzf#installation) -  used to browse known repositories and quickly jump to them
- Copy `org-hopper.plugin.zsh` to your `$ZSH_CUSTOM/plugins` folder, `~/.oh-my-zsh/custom` by default
- Append `org-hopper` to your existing plugins list in `~/.zshrc`, like `plugins=(org-hopper)`

Finally, start a new terminal session to make the plugin available.

### Usage
 
Calling `orghop` with no options will open an fzf fuzzy finder with the organization's repositories as its contents.

Selecting one will either clone it using `gh repo clone` or `cd` into it if a local copy already exists. The repository will be placed at `$ORG_HOPPER_DIRECTORY/<repository-name>`, which is `$HOME/$ORG_HOPPER_ORG/<repository-name>` by default.

The plugin maintains a cache of results at `$ORG_HOPPER_CACHE_LOCATION/.org_hopper.cache`, which is by default in the home directory. As needed, you can run `orghop refresh` to refetch the cache. Currently this is not done automatically so as to not inconvenience.

> [!IMPORTANT]  
> It's required to set the `$ORG_HOPPER_ORG` variable in your shell settings (like `~/.zshrc`) before calling the plugin.

### Commands
```
orghop          -- Open fuzzy finder for current repository cache
orghop refresh  -- Refresh repository cache (do this occasionally, as needed)
orghop age      -- Check the age of the current repo cache

Potentially:
ORG_HOPPER_ORG=react orghop  -- overwride the ORG_HOPPER_ORG for this call only. This will ignore and overwrite the cache.
```

### Config

In `~/.zshrc` (or similar)

```zsh
# Required
export ORG_HOPPER_ORG=<desired-organization>

# Optional, with the below defaults
export ORG_HOPPER_CACHE_LOCATION=$HOME
export ORG_HOPPER_DIRECTORY=$HOME/$ORG_HOPPER_ORG
export ORG_HOPPER_COLOR_RECENT=cyan
export ORG_HOPPER_COLOR_OUTDATED=red
```

### Tips
You can [configure fzf using environment variables](https://github.com/junegunn/fzf#environment-variables) if desired.
