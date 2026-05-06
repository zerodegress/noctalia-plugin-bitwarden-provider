# Noctalia Bitwarden Provider

Launcher provider for Noctalia that searches Bitwarden through `rbw`.

## Features

- `>bw` command in the Noctalia launcher.
- Uses `rbw list` and `rbw get --clipboard` instead of the official Bitwarden CLI.
- Does not call `rbw` during provider initialization, so unlocking is deferred until the provider is used.
- Checks `rbw unlocked` before listing entries. If locked, it closes the launcher before running `rbw unlock` so pinentry is not hidden under Noctalia.
- Optional `RBW_PROFILE` support.
- Optional custom `base_url`, `identity_url`, email, pinentry, lock timeout, and sync interval.
- Category tabs copy password, username, TOTP, or notes.
- `>bw sync` runs `rbw sync`; `>bw lock` runs `rbw lock`.

## Requirements

- Noctalia with plugin launcher provider support.
- `rbw` installed and configured enough to login.
- A working `pinentry` program so `rbw` can prompt for the master password.

## Usage

Install or symlink this directory as a Noctalia plugin, enable it, then open the launcher and type:

```text
>bw github
```

The first search runs `rbw unlocked`. If the vault is unlocked, the provider then runs `rbw list --fields id,name,user,folder,type`. If the vault is locked, select the "Unlock Bitwarden" result; the launcher closes before `rbw unlock` starts, and the unlock command is detached from the launcher process so pinentry can complete normally.

Selecting an entry runs `rbw get --clipboard <entry-id>` by default. Use the category tabs to copy `username`, `totp`, or `notes` instead.

## Custom Endpoints

In the plugin settings, enable "Apply rbw config on use" and set:

- email
- base URL, for example `https://vault.example.com/`
- identity URL, if your server requires a non-default identity endpoint
- optional profile name

The provider applies non-empty settings with `rbw config set ...` immediately before `rbw list`, `rbw get`, `rbw sync`, or `rbw lock`.
