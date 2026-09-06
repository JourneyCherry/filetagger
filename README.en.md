<img src="assets/branding/app_icon.svg" alt="File Tagger icon" width="112" height="112">

# File Tagger

*English · [한국어](README.md)*

> This English text was translated from the Korean original with the help of AI.
> Where the two disagree, [README.md](README.md) is the source of truth.

A desktop application that reads every file and subdirectory under a chosen
directory, lets you attach **tags and tag values** of your own to them, and helps
you **sort, filter, and browse** by those tags.

## Features

**Scanning and tagging**

- Choose a root directory to manage, scan the files and folders under it, and set
  a management mode per folder (folder only / contents / recursive) to control how
  far indexing reaches
- Attach tags of the label / text / number / date / link / image value types to
  files and folders
- File size, modification time, image dimensions, and the like are attached
  automatically as **system tags**, and take part in filtering and sorting exactly
  like your own tags
- Move tracking keeps tags attached when a file is moved or renamed, with live
  file-system watching
- A **command-line tool** for scripts and external tools to read, add, modify, and
  remove tags, and **export / import** to carry tags between folders — see
  "External app integration" below

**Viewing and browsing**

- Three view modes — list, icons, details — each remembering its own zoom level
- **Filter** by a combination of tags, **sort** by tag value in several steps, and
  **group** by tag value or folder hierarchy — all three editable both as chips and
  as text with autocomplete
- A split preview, thumbnails, and full keyboard navigation for browsing the list
  and editing tags

**Custom thumbnails**

- A "link" tag points at another item in the workspace, and an "image" tag at an
  image file from outside; either becomes the thumbnail of a node. Order several
  tags as a priority list so each item picks the source that suits it

The in-app **Help** (F1) collects how-to guidance, usage tips, the feature and
shortcut table, and an explanation of every system tag. The Help menu opens it
directly on the tab you want.

## Tech stack

- **Flutter** (cross-platform GUI, desktop first: Windows / Linux)
- **Drift** (SQLite) — tag persistence
- **Riverpod** — state management

## Where tags are stored

Tag data lives in a SQLite database inside the `.filetagger/` folder at the root of
the managed directory. Move or copy that folder and the tags travel with it. Only
machine-wide settings — recently opened folders, the theme, the display language —
are kept outside the tag database, and where they go depends on how the app was
distributed.

- **Portable build** (unpacked from an archive): next to the executable. Move the
  folder and the settings come along.
- **Installed build**: the per-account OS application data folder.

Using both forms on the same PC gives you two separate sets of settings; that is
intended. If the app runs somewhere it cannot write its settings file — a portable
build on read-only media, or a folder you have no permission for — it still works,
but **settings last only for that run** and the status bar shows "Settings are not
being saved". The app never quietly writes them somewhere else instead.

## External app integration

### Exporting and importing tags

Select items in the list and choose File → Export Tags… (or use the context menu),
and the tags of the selected items are saved as **one** command file.

The receiving side takes it either way — **File → Import Tags…** in the app picks
that file, or `filetagger_cli import <file>` reads it. **The same code decides in
both cases, so the outcome never differs.** If images were exported along with it,
they have to travel next to the file to attach.

- Only the tags the selected items actually carry are offered, and all of them are
  selected by default.
- Turning off **Include tag values** attaches the tags with their values left empty.
- Turning on **Include image files** writes the custom thumbnail images **next to**
  the exported file. Both have to travel together for the images to attach (relative
  paths are resolved against the folder that file sits in).
- Value type, multi-value permission, and color travel along so the tags can be
  created if missing.
- Link values are unwound into the target's path (a keyword's name) and carry
  `missingLink: keep` — **the value survives even if the target did not travel
  along**, waiting on the receiving side as an unresolved link.
- System tags are not included; they are derived automatically, and the receiving
  side refuses them.

Importing expands **only the entries that did not apply**. A file the scan has not
picked up yet is a **hold** rather than a rejection, so importing the same file again
after a scan attaches it then — and nothing already attached is attached twice.

### The command-line tool (`filetagger_cli`)

Handles tags **in a single command**. It is meant for scripts and for the user
commands of a file manager, and it decides with the **same code** as the app, so the
outcome never differs.

The portable build carries it under `cli/bin/`. To build it yourself, run `dart build
cli` in the repository and it lands in `build/cli/<platform>/bundle/bin/`
(`dart compile exe` cannot produce it — the native sqlite has to be bundled along).

#### Commands

The surface splits into **nouns and verbs**. `tag` handles tag **definitions**,
`list` handles the **assignments** on files, and both take the same four verbs.

| Command | What it does |
| --- | --- |
| `tag add <name> <value type>` | Creates a tag definition. Leaves it alone if one of the same name and value type is already there |
| `tag modify <name>` | Changes the name, value type, multi-value permission, or color (only what you write changes) |
| `tag delete <name>` | Deletes a tag definition, and its assignments with it |
| `tag show [name]` | Lists the tag definitions **you created**. Give a name for just that one |
| `list add <target> <tag> [value]` | Assigns a tag. On a tag that allows multiple values, one more value is added |
| `list modify <target> <tag> [value]` | Clears that tag's existing assignments and leaves the one value given |
| `list delete <target> <tag> [value]` | Detaches an assignment. With a value, **only the assignments of that value**; without one, the whole tag |
| `list show <target>` | Lists the tags attached to the target |
| `list show --filter <condition>` | Lists the **targets** the condition catches (`--sort` and `--group` order and group them) |
| `scan` | Walks the managed folder and brings the index up to date |
| `import <file>` | Reads an exported command file and applies it as written |
| `image <image file>` | Registers an outside image in the cache and prints its cache key |
| `status` | Prints how many nodes, keywords, and tags the index holds |
| `systemtags` | Prints the **system tags** available to conditions and their properties (no managed folder needed) |
| `config show` | Prints the console settings in force and where the settings files sit (no managed folder needed) |
| `config set <key> <value>` | Writes one console setting |
| `config unset <key>` | Removes one console setting |

`<target>` is a **path relative to the managed folder** (a keyword name if
`--keyword` is given). Instead of naming targets one at a time, `--filter` names a
**set** — and then the positional arguments shift by one
(`list add --filter "<condition>" <tag> [value]`).

**`tag add` is the only way in for creating a tag.** `list` refuses a tag that does
not exist — writing "create it if missing" into every assignment would let the same
tag be born with different properties (value type, multi-value permission) depending
on where it was called from. `tag add` does nothing and succeeds when the same name
and value type are already there, so it can simply sit at the top of a script.

The value types are `label` `text` `number` `date` `link` `image`.

**System tags are not mixed into `tag show`.** They are a fixed list derived from the
file, so they can be neither created nor changed, and columns like the assignment
count carry no meaning for them. `systemtags` prints that list — the values are held
in code, so it answers from anywhere, **without opening a managed folder**.

#### Options

**Every command** takes these three (`--workspace` only on the ones that open a
managed folder).

| Option | Meaning |
| --- | --- |
| `-C, --workspace <path>` | The managed folder. Falls back to the `workspace` setting, then the current directory |
| `--json` | Output for machines to read rather than people |
| `--lang <language>` | The language the console prints in. Beats the settings |

**The commands that judge** (`list add`, `list modify`, `list delete`, `import`) can
scan on their own when the index does not know the target.

| Option | Meaning |
| --- | --- |
| `--auto-scan` | Scan once and judge again when the index does not know the target |

**The commands that print a table** (`tag show`, `list show <target>`, `systemtags`,
`config show`) name the columns on the first line. Machine output (`--json`) does not
get one — its keys already do that — and neither does `list show --filter`, whose
lines are meant to be the next command's arguments. Strip it in a pipe with
`tail -n +2`.

`tag add` · `tag modify`:

| Option | Meaning |
| --- | --- |
| `--multiple` | Lets the tag be assigned to one file more than once |
| `--color <#RRGGBB>` | The chip color |
| `--rename <new name>` | (modify) Renames the tag |
| `--type <value type>` | (modify) Changes the value type |
| `--clear-color` | (modify) Clears the chip color |

`list`:

| Option | Meaning |
| --- | --- |
| `--keyword` | Reads the target as a keyword name rather than a path |
| `--value-keyword` | Reads a link value as a keyword name rather than a path |
| `--create-keyword` | Creates the named keyword if it is missing and carries on |
| `--keep-link` | Keeps the text as an unresolved link when the link target cannot be found |
| `--filter <condition>` | Applies to every target the condition catches |
| `--auto-scan` | Scans once and judges again when the index does not know the target |
| `--sort <keys>` · `--group <keys>` | (show) Orders the output and groups it |
| `--system` / `--no-system` | (show) Whether to include the derived system tags |

**The querying commands** (`tag show`, `list show`, `systemtags`) can cap how much
they print.

| Option | Meaning |
| --- | --- |
| `--top <n>` | Only this many from the front |
| `--tail <n>` | Only this many from the back |
| `--range <start>:<end>` | From this position to that one (counting from 1, both ends included) |

Only **one** of the three can be used. Asking for more than there is, or for a range
that runs past the end, is not an error — as much as can be printed is printed. The
length of the list is something the caller cannot know in advance, and if failing to
guess it made the command fail, a script would always have to count first. Nothing is
printed when the start runs past the list or the end comes before the start. When the
output is grouped (`--group`), what gets counted is the **top-level rows**.

`--help` prints the full list.

#### Attaching without scanning first (`--auto-scan`)

The console never walks the folder unless told to, so tagging a file you just created
ends as a **hold** (exit code `75` — "run scan first"). With `--auto-scan` it walks
once at that point and judges the same command again.

```bash
# create a file and tag it right away (without calling scan separately)
filetagger_cli -C ~/pictures list add 2026/new.png source pixiv --auto-scan
```

- **It only fires on holds.** A rejection catches in the same place after a scan, and
  a condition that caught nothing is the condition's answer, not a reason to walk. The
  one exception is `--filter`, which walks **before** choosing — conditions stand on
  the index, so a later walk cannot recover what was never picked.
- **It judges again only once.** A second hold is not a race but a place a walk does
  not reach, so repeating would give the same answer.
- If another program is already walking, it is skipped and the earlier hold stands.

A full scan is expensive, so it is **not the default**. A script that touches many
files is far better off calling `scan` once and attaching the rest.

#### Console settings (`config`)

These hold the **defaults** for the values that are tedious to type on every command.

| Key | Meaning |
| --- | --- |
| `lang` | The language the console speaks. Used by runs that pass no `--lang` |
| `workspace` | The default managed folder. Opened by commands that pass no `-C` |

`config --help` and `config set --help` print that list with a description of each, so
there is nowhere else to look for what you may write.

The language is read before the command runs, so even the `--help` text comes out in
that language.

**The settings files sit next to the executable.** The tool is meant to sit on your
PATH, so there is nothing to gain from a place that differs per operating system and
is hard to find (the same rule as the portable GUI build, and the two do not share
what they store anyway).

**Each scope is its own file** — `cli.json` applies to everyone who calls this binary,
and `cli.<account>.json` applies to that account alone. The per-account value
overrides the global one.

```json
{ "lang": "ko", "workspace": "/home/you/pictures" }
```

The file itself is the scope, so only setting names and values go inside. They are
kept apart so that, once there is an installed build, the per-account file can simply
**move to a place it is allowed to write** — one combined file would have to be in two
places at once.

Each key has the same four steps, and **only the last one differs** — with nothing
written anywhere, the language falls back to the OS and the managed folder to wherever
the command was called from.

```
--lang  >  per-account settings  >  global settings  >  the OS language
-C      >  per-account settings  >  global settings  >  the current directory
```

```bash
# what is in force, and where the settings file sits
filetagger_cli config show

# write for this account only (where it goes without a scope)
filetagger_cli config set lang en

# stop typing -C on every command (a relative path is stored expanded)
filetagger_cli config set workspace ~/pictures

# write for everyone who calls this binary
filetagger_cli config set lang ko --global

# remove it — the next place down (the OS, or the current directory) takes over
filetagger_cli config unset lang
```

It is JSON you can open and edit by hand. The account is named by whatever name the
operating system reports, and `config show` prints that along with where both files
sit.

**Writing goes to the account by default** so that, on a machine several people share,
writing does not change everyone's settings. If the environment reports no account
name, the per-account write fails rather than quietly moving to the global scope.

**Nothing a machine reads follows the language.** The keys and values of `--json`,
the exit codes, the names of rejection reasons and their details, and value type
names are the same whatever the language is. What follows it is the wording people
read and the **system tag names** — and condition text is still understood with the
system tag names of any supported language.

#### Conditions — choosing, ordering, grouping

The condition grammar is **the same as the condition bar on screen.** Filter, sort,
and group text built in the toolbar can be pasted straight across.

| Option | How to write it |
| --- | --- |
| `--filter` | `artist==john -rating<3` — a tag name followed by `==` `!=` `<` `<=` `>` `>=` `~` (contains) `!~`. A bare name means "is attached", and a leading `-` excludes |
| `--sort` | `rating artist` — earlier keys win. A leading `-` on a name sorts descending, `?` randomly |
| `--group` | `artist "Folder hierarchy"` — buckets by tag value, and groups by folder hierarchy |

- **Quote a name that contains a space** (`"Image width">1000`). This is where the
  condition grammar's own quoting sits on top of the shell's.
- **A single fragment that cannot be read rejects the whole command** (exit code
  `64`). Dropping a typo silently would run the command over an inverted set — one
  `-` falling off `-rating<3` is enough.
- **When the condition catches nothing**, a writing command ends as a rejection
  (exit code `65`).

**System tags** (size, extension, modification time, image dimensions, and so on)
are not stored tags but values derived from the file, computed on the spot when they
are asked for. They are always available to conditions, and their names are read in
any supported language. `systemtags` shows the list and their properties.

#### Scanning only happens when you ask

`scan` is the **only place a full scan runs.** No other command sweeps the folder
behind your back — walking a whole folder is not what attaching one tag should cost,
and when to walk it is the caller's decision.

So a file **the index does not know yet** (one just created, say) does not get the
tag, and the answer is not a rejection but "not yet" (exit code `75`). Run `scan`
first, or wait for the scan the app runs when it opens the folder or notices a
file-system change, and it goes through.

A **lock is held** while a full scan runs. A scan decides that "a node not observed
is a node that is gone", so two overlapping scans would read the part one of them has
not reached yet as deleted. If something is already walking the folder, the command
does not queue up — it skips (exit code `69`).

#### The app may be running

**Just use it.** SQLite serializes several writers on the same database on its own,
and a running app notices changes that came from outside and redraws (it checks
periodically while its window is in front). What you type shows up in the list
shortly after.

#### Custom images

The stored value of an image tag is a **cache key** (a file name made from a hash of
the content) inside the managed folder's cache. A lone string in the value position
therefore cannot say whether it means "the path of an outside file" or "a key that is
already registered" — and the two are told apart **by the command name**.

- `list add <target> <image tag> <image file>` — takes the **path** of an outside
  file and registers it as well. A relative path is resolved against where the
  command was typed.
- `image <image file>` — only registers, and prints the cache key along with a path
  relative to the managed folder. Use it when **only the key is wanted**, as when
  writing a command file by hand.

#### Output

By default the output is shaped for reading in a console, with columns separated by
tabs (`cut` and `awk` can pick them out). `--json` prints JSON instead, shaped for an
external tool or an AI to take the result and act on it.

- `list show <target>` is **the same command list as an export**, so it can be
  carried straight over to another managed folder. System tags cannot be assigned
  from outside, so **they are left out of the machine-readable form** (the
  human-readable one shows them); `--system` flips that.
- `list show --filter …` prints **targets, not tags** — one line goes straight into
  the next command as an argument. `--group` makes an indented tree, but every line
  still carries the whole path.
- A write result is that command with `result` attached (and `failure` if it was
  rejected), and it is **an array even for a single entry** — so the receiving side
  never has to tell shapes apart by count.

#### Exit codes

`sysexits` conventions, so a script can branch on them.

| Code | Meaning |
| --- | --- |
| `0` | Done |
| `64` | The command was used wrongly |
| `65` | The command was rejected (no such tag, a value type mismatch, and so on — the reason comes with it) |
| `66` | Not a managed folder |
| `69` | Something else is already walking the folder, so the scan was skipped |
| `74` | A file could not be read or written |
| `75` | **Not yet** — the index does not know the target. `scan` has to run first |

In `import`, which handles many entries at once, **a rejection outranks a hold** — a
hold stands once it is fed back after a scan, while a rejection would catch on the
same spot again.

#### Examples

```bash
# Set the tags up (leaves them alone if they are already there)
filetagger_cli -C ~/pictures tag add source text
filetagger_cli -C ~/pictures tag add artist link

# Put a newly created file into the index and attach a tag
filetagger_cli -C ~/pictures scan
filetagger_cli -C ~/pictures list add 2026/new.png source pixiv

# Link it to an artist keyword (creating the keyword if it is missing)
filetagger_cli -C ~/pictures list add 2026/new.png artist john --value-keyword --create-keyword

# Read the attached tags back as a command list
filetagger_cli -C ~/pictures list show 2026/new.png --json

# Check the system tag names available to conditions (no folder needed)
filetagger_cli systemtags

# make the console speak English for this account
filetagger_cli config set lang en

# Look at just the five most recently modified
filetagger_cli -C ~/pictures list show --sort '-Modified' --top 5

# Look at what a condition catches (jpgs rated 4 or higher, highest first)
filetagger_cli -C ~/pictures list show --filter 'rating>=4 Extension==jpg' --sort '-rating'

# Attach a tag to everything the condition catches
filetagger_cli -C ~/pictures list add --filter 'artist==john' favorite

# Hand what the condition catches to another tool
filetagger_cli -C ~/pictures list show --filter 'Extension==png' | while read -r p; do echo "$p"; done

# Take in tags someone else exported
filetagger_cli -C ~/pictures import ~/received/filetagger-20260904.json
```

## Downloading / building

**Linux**: download the portable tar.gz from the releases page and unpack it.

**Windows executables are not shipped in releases.** An unsigned executable
downloaded from the web makes Windows raise a SmartScreen warning. Building it
yourself avoids that warning and produces the same portable build the release would
have, and the steps below are how. Microsoft Store distribution is being prepared
and will be the easier path once it exists.

> **CMake alone, without the Flutter SDK, cannot build this.**
> `windows/flutter/CMakeLists.txt` reads configuration files the Flutter tool
> generates and calls back into the Flutter tool during the build to compile the
> Dart code. Visual Studio, however, is only needed as **Build Tools, not the full
> IDE**.

### Building on Windows

**Step 1 — install the C++ build tools**

The full Visual Studio IDE is not needed. In an **elevated PowerShell**:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CMake.Project"
```

Picking them by hand in the installer means one workload and two components inside
it. The workload is **"Desktop development with C++"** in the Visual Studio IDE
installer, or **"C++ build tools"** in the Build Tools installer, and in the
component list on the right, **MSVC build tools** and **C++ CMake tools for
Windows** must be checked (they are by default).

**Step 2 — install the Flutter SDK**

Follow the [official Flutter install
guide](https://docs.flutter.dev/get-started/install/windows/desktop): download the
SDK archive, unpack it where you like, and add its `bin` folder to the `Path`
environment variable. **Open a new PowerShell window** and check with:

```powershell
flutter doctor
```

A check mark on the `Visual Studio - develop Windows apps` line means step 1 went
well. Warnings on the Android lines do not matter for building this app.

**Step 3 — build**

Clone the repository and, in that folder:

```powershell
flutter pub get
flutter build windows --release
```

**No extra arguments are needed.** Building this way produces the same portable form
as the release, keeping settings next to the executable. The version needs no
specifying either: the Flutter build stamps the version from `pubspec.yaml` into the
executable and the app reads it back, so it shows in the About window and the update
check compares it against the latest release.

**Step 4 — the output**

```
build\windows\x64\runner\Release\
```

That folder as a whole is one build. Taking `filetagger.exe` out on its own will not
run, so **move the whole folder** wherever you want it.

### Building on Linux

C++ tooling and the GTK development headers are needed (Debian/Ubuntu family shown).

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter pub get
flutter build linux --release
```

The output lands in `build/linux/x64/release/bundle/`.

### Running for development · code generation

```bash
flutter run -d windows        # or -d linux
```

A development run is treated as portable too, so **the global settings live inside
the build folder and disappear when you delete the build.** Delete that one file to
see the first-run state again.

Generated files (`*.g.dart`) are committed to the repository, so **there is nothing
to run before building.** Regenerate only after changing something that is generated
from, such as the database schema.

```bash
dart run build_runner build   # code generation (Drift)
```

Localization code is generated from the ARB files under `lib/l10n/` by the Flutter
tool itself, and `flutter pub get` regenerates it, so there is nothing extra to run
by hand.

## Display language

The app ships in Korean and English. It follows the operating system's language by
default, and View → Language switches it at any time; the choice is kept with the
other machine-wide settings.

The English strings were translated from the Korean originals with the help of AI.
If any of them reads oddly or gets a term wrong, an issue or a pull request is very
welcome.

## Project layout

```
lib/
  domain/        entities, repository interfaces, use cases (platform-independent)
  data/          the database (Drift), the file-system scanner, repository implementations
  presentation/  Riverpod providers, screens, widgets
  cli/           the console command surface (runs without Flutter)
  core/          shared utilities and constants
  l10n/          ARB translation files and the code generated from them
```

## License

[MIT](LICENSE)
