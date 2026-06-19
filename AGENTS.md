# AGENTS.md — git-fuzzy mental model

## Self-Maintenance Directive

This file is the project's working memory — how the system *thinks*, not what files exist. Update it **in the same change/commit** whenever you: alter dispatch or sourcing flow; add/rename/remove a module or helper; change the config/knob contract; change an fzf-binding pattern (`--bind` / `--preview` / `reload` / `change:`); or discover a new gotcha. Keep it conceptual — prune file-listings, line numbers, counts, and rotted claims on sight. If it drifts toward a `tree` dump, it has already failed. State current truth only; this is not a changelog.

## What This Is

git-fuzzy is a **thin bash orchestration layer over `fzf`**: every command builds an fzf menu whose **list, preview, and actions are all `git` commands**. It owns no real state of its own — it is a TUI skin over git. Read it as a dispatcher and a pile of menu-builders, nothing more.

## Execution / Dispatch Model

This is the spine. Get this and the rest follows.

**Two-process model.** Two kinds of process run, and the distinction governs every perf decision:
- **PARENT** = the interactive `gf_<cmd>` function. It builds and owns the fzf TUI, runs **once**, and does all the heavy setup: validation, invariants, color, geometry.
- **HELPER** = `git fuzzy helper <name>` subprocesses that fzf spawns on **every keystroke / preview / action** via `--bind` and `--preview`. This is the **HOT PATH**: a fresh `bin/git-fuzzy` process fires per binding event.

**All perf design exists to keep helper spawns cheap.** When optimizing, that is the lens.

**Entry & flow.** `bin/git-fuzzy` is the ONLY executable; everything else is a sourced lib. Boot order:
1. Resolve the real script dir (symlink-aware — it follows `readlink`).
2. Source CORE.
3. Selectively source the needed module(s) (helpers source exactly one file; top-level commands may also pull transitive deps).
4. Run the invariant block — **parent only**.
5. Call `git_fuzzy "$@"`.

CORE source order is **load-bearing**: `load-configs → utils → debug → core`. Do not reorder it.

`git_fuzzy`: no args → `gf_menu`; args → `gf_run`. **`gf_run` lives only in `bin/git-fuzzy`**, not in any lib.

**Routing (inside `gf_run`).**
- `helper <sub>` → `gf_helper_<sub>`.
- `interactive <cmd>` → forces `gf_<cmd>` (skips the direct variant).
- plain `<cmd>` → **prefers `gf_<cmd>_direct`, else `gf_<cmd>`**.

It resolves by `type`-checking that the function exists, then forwards params via `quote_params` + `eval`.

**Helper fast path — why it skips validation.** The invariant block is guarded so helpers skip it (`[ "$1" != helper ]`). WHY: a helper always runs inside an already-validated, in-repo parent with `GH_AVAILABLE` exported — re-running git / fzf / repo / gh checks would be pure forking waste on every keystroke. This is **deliberate, not an oversight. Do not "fix" it by re-adding checks to the helper path.**

**Implicit helper allowlist.** There is NO allowlist array. The "allowlist" is simply the set of `gf_helper_*` functions that got sourced. An unknown helper name sources nothing → the function does not exist → `gf_run` errors. (This is the *implicit* allowlist; the *explicit* debounce allowlists in the security section are a different mechanism that happens to share the word.)

## Conceptual Directory Roles

Roles and relationships, not a tree. What each part is *for*:

- **`bin/git-fuzzy`** — the only executable. Home of entry, dispatch (`gf_run`), selective sourcing (`gf_source_for` / `gf_source_helper`), and the invariant block.
- **`lib/modules/<cmd>.sh`** — the interactive UI shell, ONE per user command. Owns the fzf invocation (PARENT side).
- **`lib/modules/helpers/<cmd>.sh`** — pure stdout-producing helper functions, no fzf (HELPER side / hot path).
- **CORE libs** `lib/core.sh`, `lib/utils.sh`, `lib/debug.sh` — sourced first; order is load-bearing (see Dispatch Model).
- **`lib/load-configs.sh`** — knob defaults plus per-repo override layering (see Config Contract).
- **`lib/modules/main.sh`** — builds the top-level menu (the `gf_menu` surface).
- **`lib/modules/helpers/generic.sh`** — cross-module helper infra (debounce / reload machinery).
- **GitHub-PR integration** mirrors the module/helper split — a role, not an enumeration.

**Selective sourcing ties roles to perf.** `gf_source_for` sources a single module (helpers source exactly one file; top-level commands may also pull transitive deps), **mirroring `gf_run` routing**. Helpers route through `gf_source_helper`, a `case` on the **name prefix** that sources exactly ONE helper file. **Prefix order is load-bearing — specific before general** (e.g. `diff_checkout_*` before `diff_*`). WHY: bulk-sourcing every module would dominate hot-path cost; selective sourcing avoids it.

## Core Patterns / Idioms

This is where the design actually lives. Spend the words here.

**The three roles.** Three roles repeat across every command:
- **module** = interactive UI shell (owns fzf).
- **helper** = pure stdout producer (no fzf).
- **`*_menu_content`** = the fzf list builder; its sibling **`*_preview_content`** builds the preview pane for the focused row.

**Modules NEVER call helpers in-process.** They **re-enter the binary as a subprocess**: `git fuzzy helper <cmd>_<sub> ARGS`. It is a process boundary, not a function call. `{1}` / `{q}` / `{+2..}` are fzf field/query placeholders (focused field, query string, selected rows) that fzf substitutes into the helper command line.

**`gf_<cmd>` is a pipeline:** emit list | `gf_fzf_<cmd>` | interpret selection.

**`*_menu_content`** prints exactly what fzf displays: a styled header plus color-forced git output. The universal loop:

```
list → fzf → interpret → action → reload → list
```

**Action mutates git → reload re-runs `menu_content` → the list refreshes from ground truth.** There is no client-side list mutation; the list is always re-derived from git.

**Naming routes behavior.**
- `gf_<name>` = interactive / top-level.
- `gf_<cmd>_direct` = non-interactive variant, preferred by `gf_run`.
- `gf_helper_<cmd>_<sub>` = reachable only via `git fuzzy helper`.

The `<cmd>_` segment is **load-bearing twice**: it routes `gf_run` dispatch AND drives the `gf_source_helper` selective-source `case`. A `gf_helper_*` with no `<cmd>` segment is cross-module infra.

**fzf wrappers.** `gf_fzf` / `gf_fzf_one` (`lib/core.sh`) — the wrapper that all fzf UI launches route through (bypass only with reason): standardize flags (`--ansi --no-sort --no-info`), multi-vs-single, preview geometry; both build a string and `eval` it.

**`quote_params` (`lib/utils.sh`, `printf '%q '`) is the sacred parent→helper boundary.** It is anti-injection AND anti-word-split. Every value crossing into an eval'd cross-process string goes through it. Never bypass it.

**The `--multi` / `--track` / `--id-nth` trio.**
- `--multi` = select many.
- `--track` = pin the cursor to the same logical item across reloads.
- `--id-nth` (`N..`) = declares which columns ARE the item's identity, so `track` can re-match after a reload. These are **identity columns, not sort/display columns.**

## ⚠️ The 4 Debounce Security Guards

**Do not relax these. Each one is a guard against injection or a stale-fire race on the hot path. Keep them strict.**

**Mechanism.** `gf_helper_debounced_reload` (`helpers/generic.sh`) is bound on fzf's `change` event and **backgrounded per keystroke**. It writes a unique token to a per-port / per-kind token file, sleeps the interval, then fires the reload **only if its token is still current**. Later keystrokes overwrite the token, so earlier (stale) invocations self-abort — they still run, then no-op. This is **not a cancelled timer**; the stale process wakes up and decides it is obsolete. Delivery is a `curl POST localhost:$FZF_PORT` against fzf `--listen`.

**The guards are factored into shared functions and enforced at every reload entry — each is load-bearing; do not strip one as a "duplicate cleanup." The 4 guards:**

1. **fzf-port validation** — `gf_helper_valid_fzf_port` rejects an empty or non-digit `$FZF_PORT` before any curl.
2. **`*_menu_content` allowlist** — `menu_helper` must be `[a-z0-9_]`-only AND end in `_menu_content`; otherwise `return 1`.
3. **action-prefix allowlist** — `action_prefix` must be **exactly** `track-current+reload` (literal equality, not a prefix or pattern); otherwise `return 1`.
4. **token "is-current" staleness check** — gates BOTH firing the reload AND cleaning up the token file.

**Crucial distinction.** These are the **explicit** debounce allowlists — literal regex / literal string checks. They are **distinct from the implicit helper allowlist** (the set of sourced `gf_helper_*` fns, see Dispatch Model). Same word, different mechanism. Do not conflate or merge them.

## Config / Override Contract

**Override idiom.** `if [ -z "$X" ]; then export X=default; fi` (or `${X:-default}`) — the default fills **only when unset**, so env and per-repo config **always win**. The inverse, `if [ -n "$X" ]`, means "act only when the user opted in."

**Overridable vs computed.** A guarded `-z` / `-n` assignment is an **overridable knob**. A **bare unconditional assignment inside a function** (`GF_*_HEADER`, `GF_IS_VERTICAL`, `GF_SMALL_SCREEN`) is **internal computed state, intentionally NOT overridable** — correct by design. Do NOT add a guard to "fix" it.

**Per-repo layering.** `lib/load-configs.sh` sources `./.git-fuzzy-config` (a **shell file in cwd**) **after the defaults, so it overrides and extends them**. It is sourced shell — NOT git-config keys, NOT a `key=value` dotfile. Note: it is not literally the last thing sourced — one knob's default (`GF_RELOAD_DEBOUNCE`) is assigned after that source — so describe it as "after the defaults (overrides them)," not "the last thing sourced."

**Knob categories** (categories with a few examples, not an inventory):
- **FZF layout / sizing** — window dimensions, preview geometry.
- **External-tool styling** — `GF_BAT_*`, `GF_GREP_COLOR`, `GF_PREFERRED_PAGER`.
- **git-cmd params** — `GF_LOG_MENU_PARAMS`, `GF_REFLOG_MENU_PARAMS`, `GF_DIFF_*_DEFAULTS`, `GF_GH_PR_FORMAT`, `GF_BASE_REMOTE` / `GF_BASE_BRANCH`.
- **Behavior toggles** — `GF_STATUS_WATCH`, `GF_RELOAD_DEBOUNCE`, `GF_SNAPSHOT_DIRECTORY`.
- **Debug.**

## Gotchas

The real ones, ordered most-likely-to-be-wrongly-optimized first.

**The reload tradeoff (the big one).** `reload-sync` **blocks** input until the git stream completes (typing lag on large repos) but **preserves `--multi`** across the reload (via `--id-nth` re-matching). Async `reload` **unblocks early** (no lag) but does **not** preserve `--multi`. The split: the 5 live-filter commands use the async path; action-driven commands (`status`, `stash`, `branch`, `diff`) use `reload-sync`; `status`/`stash`/`branch` pair it with `+clear-multi`.

**Accepted regression (do not "fix").** On the 5 live-filter commands, typing after selecting **clears the selection**. This is deliberately accepted: lag was the dominant cost, and these are filter-to-one-then-act flows. Do not switch them to `reload-sync` to "preserve selection."

**Live-filter ≠ fuzzy filter.** For the 5 live-filter commands, the typed `{q}` is passed as **real git args into `*_menu_content`, which RE-RUNS git server-side**; fzf's own matcher is **bypassed** for these 5. Every other module does plain client-side fzf fuzzy over a static list.

**The `change:` marker.** The live-filter set is **exactly `{log, reflog, show, diff-direct, diff-checkout}`** — the only 5 with a `change:` binding. `click-header:` / `backward-eof:` are immediate sync reloads that appear in the 5 AND in `status` / `diff` / `stash` / `branch`; **alone they do not make a live-filter — only `change:` does.** Mechanism precision: a `change:` binding fires `execute-silent(...debounced_reload...&)`, and the POST happens *inside* the debounce via curl. Only the action-driven commands carry a literal `reload-sync(...)+clear-multi` binding.

**bc / math forks.** `bc -l` (via `run_bc_program`, `core.sh`) is the **only** math fork. Geometry predicates `is_vertical` / `particularly_small_screen` memoize into `__GF_*` sentinels. **Source-time bc forks are gone; bc still forks once lazily at runtime.** Never write "forks eliminated" — that is false.

**status_watch is a different paradigm.** `gf_helper_status_watch` (`helpers/status.sh`) is an fs-watch loop (`fswatch` / `inotifywait`), launched once via fzf `start:`. It POSTs `reload-sync` on file change, self-terminates on fzf exit, and is disabled via `GF_STATUS_WATCH=0`. It is **NOT keystroke-driven** — do not lump it in with debounce / live-filter.

**Two hand-synced `case`s.** `gf_source_for` (source) vs `gf_source_helper` (dispatch). Miss one and the command **silently fails to dispatch** — no error message. (See the Add-a-Command recipe.)

## House Style

- `#!/usr/bin/env bash` on every file.
- `local` for ALL function vars.
- `printf`, not `echo`, for colored output.
- Colors via `tput`-derived vars (`utils.sh`), never raw escapes.
- git color is **forced** via `gf_git_command()` = `git -c color.ui=always "$@"` — output is captured/piped, so it must be forced.
- Errors via `gf_log_error` / `gf_log_warning` / `gf_log_debug` → a temp logfile flushed to stderr on the EXIT trap.
- **Invariant validation runs ONCE in the parent only** — never in helper / dispatch hot paths.

## Add-a-Command Recipe

**Add-a-command `<cmd>` — the 6 required touch-points (ordered checklist):**
1. `lib/modules/<cmd>.sh` — `gf_fzf_<cmd>` + `gf_<cmd>`.
2. `lib/modules/helpers/<cmd>.sh` — the list builder `gf_helper_<cmd>_menu_content`, the preview builder `gf_helper_<cmd>_preview_content`, an inspect/interpret helper, plus the git-action helpers.
3. `bin/git-fuzzy` `gf_source_for()` case.
4. `bin/git-fuzzy` `gf_source_helper()` case — **specific prefixes before broad** (`diff_checkout_*` before `diff_*`).
5. `lib/modules/helpers.sh` full-source manifest line.
6. `lib/modules/main.sh` `gf_menu_content()` `gf_menu_item`.

**Touch-points 3 and 4 are the two hand-synced `case`s — miss either and the command silently fails to dispatch** (see Gotchas).

**Verify:** `git fuzzy <cmd>` opens the menu and `git fuzzy helper <cmd>_<sub> ARGS` prints to stdout; a silent no-op means you missed touch-point 3 or 4.

## What NOT To Do

**Hard rules:**
- No source-time forks.
- Never bypass `quote_params` before an eval'd / cross-process string.
- Don't add validation to the helper hot path.
- Don't `reload-sync` large / slow lists.
- Don't re-source the whole `helpers.sh` in dispatch.
- Don't reorder CORE sourcing.
