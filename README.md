# `git-fuzzy`

A CLI interface to git that relies heavily on [`fzf`](https://github.com/junegunn/fzf) (version `0.21.0` or higher).

You can run `git add` and `git reset` by selecting or cursoring. You can commit interactively.

![status manager](gifs/status.gif)

You can search the diff from the query bar and the RHS diff will be highlighted accordingly.

![diff viewer](gifs/diff.gif)

Search the log and corresponding diff at once. Notice that when you use `|` the left hand side is sent to `log` while the right hand side is sent to `diff`.

![log viewer](gifs/log.gif)

## Installing

`fzf` is **required**:
```bash
brew install fzf
```

### Bash
```bash
git clone https://github.com/bigH/git-fuzzy.git

# add the executable to your path
echo "export PATH=\"$(pwd)/git-fuzzy/bin:\$PATH\"" >> ~/.bashrc
```

### Zsh
```bash
git clone https://github.com/bigH/git-fuzzy.git

# add the executable to your path
echo "export PATH=\"$(pwd)/git-fuzzy/bin:\$PATH\"" >> ~/.zshrc
```

Alternatively, you can use a plugin manager:

#### Antibody
Update your `.zshrc` file with the following line:
```
antibody bundle bigH/git-fuzzy path:bin kind:path
```

#### Znap
Run the following on the command line:
```
znap install bigH/git-fuzzy
```

#### zplug
```
zplug "bigH/git-fuzzy", as:command, use:"bin/git-fuzzy"
```

#### zinit
```
zinit ice as"program" pick"bin/git-fuzzy"
zinit light bigH/git-fuzzy
```

### Fish
```
git clone https://github.com/bigH/git-fuzzy.git

# add the executable to your path
echo "set -x PATH (pwd)\"/git-fuzzy/bin:\$PATH\"" >> ~/.config/fish/config.fish
```

## Usage

Simply install and run `git fuzzy` and you can begin using the menu.

**Supported sub-commands**:

- `git fuzzy status` (or `git fuzzy` -> `status`)

    Interact with staged and unstaged changes.

- `git fuzzy branch` (or `git fuzzy` -> `branch`)

    Search for, checkout and look at branches.

- `git fuzzy log` (or `git fuzzy` -> `log`)

    Look for commits in `git log`. Typing in the search simply filters in the usual `fzf` style.

- `git fuzzy reflog` (or `git fuzzy` -> `reflog`)

    Look for entries in `git reflog`. Typing in the search simply filters in the usual `fzf` style.

- `git fuzzy stash` (or `git fuzzy` -> `stash`)

    Look for entries in `git stash`. Typing in the search simply filters in the usual `fzf` style.

- `git fuzzy diff` (or `git fuzzy` -> `diff`)

    Interactively select diff subjects. Drilling down enables searching through diff contents in a diff browser.

- `git fuzzy pr` (or `git fuzzy` -> `pr`)

    Interactively select and open/diff GitHub pull requests.

## Useful Information

All items from the menu can be accessed via the CLI by running `git fuzzy <command>`. Many of the commands simply pass on additional CLI args to the underlying commands. (e.g. `git fuzzy diff a b -- XYZ` uses the args you provided in the listing and preview)

Any time `git` command output is used in preview or listing, there is a header with the command run (useful for copy-pasting or just knowing what's happening). You can optionally [enable debugging switches](#stability--hacking) to see other commands being run in the background or how commands are routed.

## Customizing

For the ideal experience, install the following optional tools to your `PATH`:

- [`delta`](https://github.com/dandavison/delta) or [`diff-so-fancy`](https://github.com/so-fancy/diff-so-fancy) for nicer looking diffs
- [`bat`](https://github.com/sharkdp/bat) for a colorized alternative to `cat`
- [`eza`](https://github.com/eza-community/eza) for a `git`-enabled, and better colorized alternative to `ls`

`git fuzzy diff` uses `grep` to highlight your search term. The default may clash with `diff` formatting or just not be to your liking. You can configure `git fuzzy` without affecting the global setting.

```bash
export GF_GREP_COLOR='1;30;48;5;15'
```

If provided, `GF_PREFERRED_PAGER` is used as a way to decorate diffs. Otherwise, `diff-so-fancy`, then `delta` are tried before using raw diffs. **Remember to adequately quote this value as it's subject to string splitting.**

```bash
export GF_PREFERRED_PAGER="delta --theme=gruvbox --highlight-removed -w __WIDTH__"
```

If present, `bat` is used for highlighting. You can choose different defaults in `git fuzzy` if you so desire.

```bash
# set them for `git fuzzy` only
export GF_BAT_STYLE=changes
export GF_BAT_THEME=zenburn

# OR set these globally for all `bat` instances
export BAT_STYLE=changes
export BAT_THEME=zenburn
```

You may often want to use a different branch and remote to use as your "merge-base" in `git fuzzy`. _The default is `origin/main`._

```bash
export GF_BASE_REMOTE=upstream
export GF_BASE_BRANCH=trunk
```

**FOOTGUN**: If you work in a repository that's changed it's default `HEAD` (e.g. from `master` to `main`) since your initial `clone`, you may need to run `git remote set-head <remote name> <branch name>`. Use `git symbolic-ref -q "refs/remotes/<remote name>/HEAD"` to check what the current value is.

For some repos, it can be useful to turn off the remote branch listing in `git fuzzy branch`. _By default, `git fuzzy` displays remote branches._

```bash
# any non-empty value will result in skipping remotes (including 'no')
export GF_BRANCH_SKIP_REMOTE_BRANCHES="yes"
```

You may want the diff search to behave differently in `git fuzzy diff` (this doesn't apply to `log` or any other command that uses `diff`). The query will be quoted by `fzf` and provided as the next argument. In the default case, that means `-G <query>`. _The default is `-G`._

```bash
export GF_DIFF_SEARCH_DEFAULTS="--pickaxe-regex -S"
```

You may want custom formats for your `log` and/or `reflog` experience. This is hidden from the command headers to save room and enable freedom in formatting parameters. **Remember to adequately quote this value as it's subject to string splitting.** If you have trouble quoting formats, you can use a pretty format alias (see `man git-config`) _The default is `--pretty=oneline --abbrev-commit`._

```bash
# for `git fuzzy log`
export GF_LOG_MENU_PARAMS='--pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --topo-order'

# for `git fuzzy reflog`
export GF_REFLOG_MENU_PARAMS='--pretty=fuzzyformat'
```

You can also configure various `git` commands' default args in various contexts. This is hidden from the command headers to save room and enable freedom in formatting parameters. **Remember to adequately quote this value as it's subject to string splitting.** _These are not set by default._

```bash
# when diffing with branches or commits for preview
export GF_DIFF_COMMIT_PREVIEW_DEFAULTS="--patch-with-stat"

# when diffing with branches or commits for preview
export GF_DIFF_COMMIT_RANGE_PREVIEW_DEFAULTS="--summary"

# when diffing individual files
export GF_DIFF_FILE_PREVIEW_DEFAULTS="--indent-heuristic"
```

If you use vertical terminals/windows often, you may want to configure the threshold for switching to a vertical view. This ratio is calculated by running `"__WIDTH__ / __HEIGHT__ > $GF_VERTICAL_THRESHOLD"`. This is calculated using GNU `bc`. _The default is `2.0`._

```bash
export GF_VERTICAL_THRESHOLD="1.7 * __HEIGHT__ / 80"
```

You can also configure how the size of the preview window is calculated. They're calculated using GNU `bc`. Try using [Desmos](https://www.desmos.com/calculator) to tweak the calculation. _The defaults are more complex than shown below._

```bash
# use __WIDTH__ for horizontal scenarios
export GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION='max(50, min(80, 100 - (7000 / __WIDTH__)))'

# use __HEIGHT__ for horizontal scenarios
export GF_VERTICAL_PREVIEW_PERCENT_CALCULATION='max(50, min(80, 100 - (5000 / __HEIGHT__)))'
```

In cases where you are using a particularly small terminal, you can configure the following calculations to determine when to hide extraneous things. Note that both defaults use `__HEIGHT__`, but `__WIDTH__` is also available.

```bash
# use __HEIGHT__ for horizontal scenarios
export GF_HORIZONTAL_SMALL_SCREEN_CALCULATION='__HEIGHT__ <= 30'

# use __HEIGHT__ for horizontal scenarios
export GF_VERTICAL_SMALL_SCREEN_CALCULATION='__HEIGHT__ <= 60'
```

You may want to customize the default keyboard shortcuts. There are [many configuration options available](https://github.com/bigH/git-fuzzy/pull/16/files). Here's an example:

```bash
export GIT_FUZZY_STATUS_ADD_KEY='Ctrl-A'
```

If you are using nano as your default editor, you need to pass `/dev/tty` as stdin otherwise you may receive an error similar to `Too many errors from stdintor to close the file...`:

```bash
git config --global core.editor 'nano < /dev/tty'
```

`git fuzzy` appends a static list of defaults to your `FZF_DEFAULT_OPTIONS`. If you want to use your own set of `git fuzzy`-specific fzf defaults, you can set `GIT_FUZZY_FZF_DEFAULT_OPTS` which will be used in place. Note that `FZF_DEFAULT_OPTS` is merged with this variable.

## Backups

`git fuzzy` takes a backup of your current sha, branch, index diff, unstaged diff and new files. This is helpful in case you take an action hastily (like discarding a file you meant to stage) or there is a bug. If you'd like snapshots, simply set the variable below. I have the following entry in my `.zshrc` (with corresponding `.gitignore_global`):

```bash
export GF_SNAPSHOT_DIRECTORY='.git-fuzzy-snapshots'
```

Alternatively, if you'd like to avoid having these files in your repo directory, you can simply set the snapshot location like so:

```bash
export GF_SNAPSHOT_DIRECTORY="$HOME/.git-fuzzy-snapshots"
```

## `bc` Usage

`bc` programs are all run with some useful functions defined (`min` and `max`). If you'd like to add any others, you can do so. _This is not set by default._

```bash
# defining your own function:
export GF_BC_LIB='my_favorite_variable = 3.14159;'
```

## Project-Specific Settings

`git fuzzy` sources `./git-fuzzy-config` if it's present. You can add the following to your `~/.gitignore_global` to avoid having to worry about `git` picking it up:

```gitignore
.git-fuzzy-config
```

This file is sourced at the end, so you can build on top of existing or default configurations:

```bash
# make the preview bigger, but keep the flexibility
export GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION='(80 + $GF_HORIZONTAL_PREVIEW_PERCENT_CALCULATION) / 2'
```

## Questions

**Why does the UI flash?**

`execute` from the `fzf` man page states that `fzf` switches to the alternate screen when executing a command. I've filed [this issue](https://github.com/junegunn/fzf/issues/2028), which should enable making the transitions smoother.

## Stability & Hacking

I built this for myself and it's working reasonably well.

That being said, I've gone through great pains to polish existing functionality to work pretty nicely. I've made it easy to develop or change features by using debug output to check behavior. All debug output goes to `/dev/stderr`, so you can hack on this while using it in pipes and in your `zsh` or `bash` readline shortcuts.

**These variables are considered `true` if they are non-empty.**

```bash
# debugging information
export GF_DEBUG_MODE="YES"

# commands run by the program (those without headers)
export GF_COMMAND_DEBUG_MODE="YES"

# fzf commands run by the program
export GF_COMMAND_FZF_DEBUG_MODE="YES"

# log output of commands run by `git fuzzy`
export GF_COMMAND_LOG_OUTPUT="YES"

# log internal commands (pretty noisy)
export GF_INTERNAL_COMMAND_DEBUG_MODE="YES"
```

Or, log everything:

```
GF_DEBUG_MODE="YES" GF_COMMAND_DEBUG_MODE="YES" GF_COMMAND_FZF_DEBUG_MODE="YES" GF_COMMAND_LOG_OUTPUT="YES" GF_INTERNAL_COMMAND_DEBUG_MODE="YES" git fuzzy
```
