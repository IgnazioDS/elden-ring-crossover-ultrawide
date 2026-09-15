# Elden Ring CrossOver Ultrawide

A small, fail-closed launcher that removes Elden Ring's 16:9 black bars when
the Windows Steam release is played through CrossOver on an ultrawide Mac.
It was cold-start tested at 3440×1440 on CrossOver 26.3 and Apple silicon.

The project does **not** modify the installed Steam executable. Each launch
checks a version-specific byte signature, makes a temporary copy, changes one
branch byte in that copy, launches it, and deletes it after the game exits.

> [!IMPORTANT]
> This is an offline-only setup. It starts the game without Easy Anti-Cheat,
> so online multiplayer is unavailable. Do not attempt to use the temporary
> executable with EAC or online play.

## Supported configuration

- Elden Ring Steam build 1.17.1
- Clean `eldenring.exe` SHA-256:
  `1a3547101327f65d0c76da2f9190ac0aa66871ea42bae2aecc61e11a8b597891`
- Standard Steam game location inside a CrossOver bottle
- CrossOver 26.x on macOS/Apple silicon (the installer is intentionally
  conservative and may work on earlier releases)

Unknown or modified executables are rejected without being changed. A future
game update may therefore require a new reviewed patch profile.

## Install

1. Install Elden Ring through Steam in its CrossOver bottle and launch it once.
2. Set the desired native ultrawide resolution in the game's graphics menu,
   then close Elden Ring.
3. Clone or download this repository.
4. In Terminal, run:

   ```sh
   chmod +x scripts/*.command scripts/*.sh
   ./scripts/install.command
   ```

The installer searches the standard CrossOver bottle directory and
`/Volumes/*/CrossOver/Bottles`. For a custom or ambiguous installation:

```sh
./scripts/install.command --bottle "/full/path/to/Elden Ring bottle"
```

It verifies both the clean game executable and the bundled launcher, backs up
the original Windows URL/menu records inside the bottle, registers a private
`eldenring-ultrawide:` protocol, and redirects the existing CrossOver Elden
Ring icon through the safe launcher.

After installation, start the game from its normal CrossOver icon. No
Flawless Widescreen, ModEngine, Python runtime, companion process, or special
manual launch order is required.

## What happens on launch

1. The original six-byte signature is validated at offset `0x19ED05E`.
2. Clean `eldenring.exe` is copied to `eldenring_ultrawide_tmp.exe`.
3. Only the branch byte at that offset changes from `74` to `EB`.
4. The temporary executable runs while the launcher waits.
5. The temporary and staging files are removed when the game closes.

A named Windows mutex prevents two patch sessions from running concurrently.
If validation or copying fails, the launcher records the error and leaves the
installed executable alone.

## Steam saves and achievements

The game remains associated with Steam AppID `1245620`, so local saves, Steam
Cloud, playtime, overlay, and achievements continue to operate. Steam must be
running and signed in inside the bottle. The launcher never reads credentials
or touches save files.

## Diagnose or remove

```sh
./scripts/diagnose.command
./scripts/uninstall.command
```

Both commands accept the same optional `--bottle` argument. Uninstall restores
the installer-created backup and removes the private URL protocol. Backups are
kept under `drive_c/EldenRingTools/backups` for manual recovery.

The launcher log is stored inside the bottle at:

```text
C:\EldenRingTools\elden-ring-ultrawide.log
```

## Building from source

The launcher is a dependency-free .NET Framework 4.8 Windows GUI executable.
GitHub Actions builds `src/EldenRingUltrawideLauncher.csproj` on Windows. The
checked-in binary is the exact 8.7 KB artifact used for the documented cold
launch, with SHA-256:

```text
1506f0c7d661915bf859b1694364d56c825775d7c229f8b6b982f38cc3527543
```

## Privacy, copyright, and trademarks

No FromSoftware/Bandai Namco binaries, game assets, credentials, saves, or
CrossOver bottle data are included. Users must own Elden Ring and provide
their own legitimate Steam installation.

Elden Ring is a trademark of its respective owners. CrossOver is a trademark
of CodeWeavers. This independent community project is not affiliated with or
endorsed by FromSoftware, Bandai Namco, Valve, or CodeWeavers.

Released under the [MIT License](LICENSE).

