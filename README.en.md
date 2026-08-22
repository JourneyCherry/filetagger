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
- A **tag queue** lets an external app (a browser extension, a download script)
  attach tags at the moment it saves a file — see "External app integration" below

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

### The tag queue

This is the doorway through which an external app can **attach tags at the moment
it saves a file**, or add, change, and remove tags on files that are already
indexed. It is not an HTTP server or a plugin runtime but **a folder you drop
request files into**, so the app does not have to be running and all the external
app needs is the ability to write one JSON file. Leave a request in the queue and
the app applies it and clears it away the next time it opens that folder — or right
away, if it is already running.

#### The flow

1. The external app **saves the file inside the managed folder first**.
2. It puts a **request file** into `<managed folder>/.filetagger/queue/`. The name
   is yours to choose, but the **extension must be `.json`** — only that extension
   is read as a request. **Rename it to `.json` once it is fully written**: write
   `a1b2c3.json.tmp` and move it to `a1b2c3.json`, and it can never be read
   mid-write.
3. The app reads and applies the queue **when a folder is opened (right after the
   scan)** and **whenever the queue changes while it is running**. The scan comes
   first so that adding a file and tagging it land together.
4. Successful entries **leave the queue**; failed ones **stay where they are with
   the reason written in**. When every entry in a file succeeds, the file itself is
   deleted. The external app can simply read back the path it created to learn the
   outcome.

The app creates the `queue` folder itself when the managed folder is opened. Files
that are not `.json` are never read as requests, so an image a request refers to can
sit in the same folder (see `image` below). Such files are tidied up on the same
schedule as failed entries once they get old.

#### Several requests in one file

Write an **array** at the top level to put several requests in one file. Results are
recorded **per entry**, not per file — successful entries drop out, failed ones
stay with their reason attached, and entries not yet processed stay as they are.
When all of them succeed the file is deleted.

```json
[
  { "path": "new/01.png", "tag": "read" },
  { "path": "new/02.png", "tag": "artist", "value": "Jane Doe" }
]
```

**Write an array file once and do not append to it.** The app rewrites the file to
record what happened, so anything appended in between can be lost. An external app
that pushes requests as they come should keep writing **one file per entry**, as
before; the two forms can share a folder.

#### Request file format

| Field | Required | Value |
| --- | --- | --- |
| `path` | ✔ | The target's **path relative to the managed folder root** (or the keyword **name** when `nodeType: keyword`) |
| `tag` | ✔ | The tag **name** |
| `op` | | `add` (default) · `replace` · `remove` |
| `value` | | The tag value (a string; numbers and booleans are accepted and read as strings) |
| `missing` | | When no tag of that name exists: `fail` (default) · `create` |
| `valueType` | | `label` · `text` · `number` · `date` · `link` · `image` |
| `allowMultiple` | | Whether the tag being created may carry several values (default false) |
| `color` | | The display color of the tag being created (ARGB integer) |
| `nodeType` | | How to read `path`: `file` (default) · `directory` · `keyword` |
| `valueNodeType` | | How to read a `link` value (same three, default `file`) |
| `missingKeyword` | | When the named keyword does not exist: `fail` (default) · `create` |
| `missingLink` | | When the target of a `link` value cannot be found: `fail` (default) · `keep` |

- `op`
  - `add` — attaches the value. On a multi-value tag the existing values stay and
    one more is added.
  - `replace` — removes every existing assignment of that tag and leaves this one
    value.
  - `remove` — with `value`, removes just that assignment; without it, detaches the
    tag entirely.
- `missing: create` **requires `valueType`** — with a default, a single typo would
  conjure a phantom tag. `allowMultiple` and `color` are **used as written** and,
  when absent, the tag is created single-valued and without a color. For a tag meant
  to carry several values, be sure to write `allowMultiple: true`: on a single-value
  tag, assigning again is an **update**, so only the last value survives.
- If the tag **already exists**, only a differing `valueType` fails;
  `allowMultiple` and `color` are ignored, because an outside request does not get
  to change the nature of an existing tag.
- An **unknown name** in `op`, `missing`, `valueType`, `nodeType`, `valueNodeType`,
  `missingKeyword`, or `missingLink` is treated as a format error rather than
  falling back to the default — so a misspelled `remove` never quietly becomes an
  assignment.
- Keys the app does not interpret (a request id of your own, say) may be included.
  They are preserved when the entry comes back as a failure.

#### What goes in `value`, by value type

| Type | What `value` holds |
| --- | --- |
| `label` | Nothing (a tag without a value) |
| `text` | The string as-is |
| `number` | A string that reads as a number |
| `date` | An ISO-8601 string (only the date part is stored) |
| `link` | **The target item's path relative to the managed folder** (the app converts it to an internal identifier) |
| `image` | **The path of an image file** — an absolute path points at that file; a **relative path is resolved against the queue folder** — and it is registered in the cache |

An external app cannot address `link` or `image` by internal identifier or cache
key: those are internal representations and are not exposed. That is why **removing
an `image` always removes the whole tag** — there is no way to name the value to
remove, and passing one would register a new image instead.

#### Links whose target is not there yet (`missingLink`)

When the item a `link` value points at is not in the managed folder, the default is
**failure**, so that a misspelled path never quietly hardens into a value.

Pass `missingLink: keep` and, instead of failing, the app **keeps the text you sent
as the value and marks it as an unresolved link**. It attaches the system tag
**`Unresolved link`** to that item, so you can gather them with a filter and either
double-click the link chip to reconnect it or remove it.

The setting exists for moving a body of tags to another managed folder: even if the
link targets could not come along, the value is not thrown away and can be
reattached later.

```json
{ "path": "new/01.png", "tag": "artist",
  "value": "Jane Doe", "valueNodeType": "keyword", "missingLink": "keep" }
```

It does not overlap with `missingKeyword`. For a keyword link, **creation is decided
first** (`missingKeyword: create` creates it and links it); only after deciding not
to create does this setting decide whether to keep the value anyway. A file link has
no creation option, so only this setting applies.

#### Pointing at a keyword

A **keyword** is an item that lives only in the tag store, with no file on disk. **A
name is all it has**; anything further, such as an artist's nationality or account,
is attached to the keyword **as tags**, so that it takes part in search and
filtering. Because it is addressed by name rather than by file, a discriminating
field goes alongside so it is not confused with a path.

- `nodeType: keyword` — reads `path` as a **keyword name**. A file with the same
  name does not collide with it; they live in different key spaces.
- `valueNodeType: keyword` — reads the `link` value as a keyword name. It is kept
  **separate from `nodeType`** because the two usually differ: the main use is
  linking an artist **keyword** from a picture **file**.
- The app does not distinguish `file` from `directory` — both are looked up by
  path. Choose one when you want to record the intent.
- A keyword name **cannot contain a path separator.** A value like `a/artist` is
  not folded into a path but comes back as a format error.
- If the named keyword does not exist, the request **fails immediately**. Unlike
  files there is no waiting, because a keyword only exists once the app creates it,
  so waiting will not make it appear.
- Pass `missingKeyword: create` and the app creates a keyword of that name and
  proceeds. A name is all there is, so there is nothing more to supply. The setting
  applies to **both** `path` and the `link` value.
- **A keyword's system tags cannot be changed either** — in particular, opening up
  the name tag would turn the queue into a way of renaming keywords, for the same
  reason the rename path is closed for files.

```json
{ "path": "new/01.png", "tag": "artist",
  "value": "Jane Doe", "valueNodeType": "keyword", "missingKeyword": "create" }
```

```json
{ "path": "Jane Doe", "nodeType": "keyword", "tag": "nationality", "value": "Korea" }
```

Send both and the picture gets a link to the artist, and that artist keyword gets a
nationality.

#### Example: tagging a downloaded image

The managed folder is `D:\comics`, and an external app has just downloaded `01.png`
into `D:\comics\new\`.

**1) Save the file first.**

```
D:\comics\
├─ .filetagger\            ← created by the app
│  ├─ filetagger.sqlite
│  ├─ view.json
│  └─ queue\               ← where requests go
└─ new\
   └─ 01.png               ← the file just saved
```

**2) Write the request file and move it to `.json` once it is complete.**

```
D:\comics\.filetagger\queue\a1b2c3.json.tmp ← write here
D:\comics\.filetagger\queue\a1b2c3.json     ← move to this name when done
```

The name is yours as long as it is unique within the queue. Only the **`.json`**
extension is read as a request, so a temporary file being written is safe to keep in
the same folder.

**3) The contents** are a single UTF-8 JSON object. `path` is the **path relative to
the managed folder root** (everything after `D:\comics`), and either `/` or `\`
works as the separator.

```json
{
  "path": "new/01.png",
  "tag": "artist",
  "value": "Jane Doe",
  "missing": "create",
  "valueType": "text"
}
```

**4) What the app does**

- If the app is **running with `D:\comics` open**, it notices the file appear and
  processes it right away. **If it was closed**, it processes the queue the next
  time that folder is opened, right after the scan.
- It finds `new/01.png` in the index, creates the `artist` tag as a text tag since
  it does not exist, and attaches the value `Jane Doe`.
- The request succeeded, so `queue\a1b2c3.json` is **deleted**. An empty queue
  leaves no trace behind.
- The desktop status bar quietly shows "Applied 1" — no dialog, no notification.

**If it failed**, the file is not deleted; it stays where it is with a `failure`
appended to its contents. For instance, if `missing` was omitted so the `artist` tag
could not be created:

```json
{
  "path": "new/01.png",
  "tag": "artist",
  "value": "Jane Doe",
  "failure": {
    "reason": "tagMissing",
    "at": "2026-08-01T12:34:56.000",
    "message": "그 이름의 태그가 없습니다."
  }
}
```

The external app can read back the path it created (`queue\a1b2c3.json`) to learn
the outcome. **No file means success; a file means either not yet processed, or a
`failure` with the reason written in.** Branch on `reason`, which is a fixed
machine-readable token; `message` is human-readable detail and is written in the
app's authoring language.

#### Other request examples

Attaching a label tag that already exists (no value):

```json
{ "path": "new/01.png", "tag": "read" }
```

Clearing every existing value and leaving just this one:

```json
{ "path": "new/01.png", "tag": "rating", "op": "replace", "value": 5 }
```

Removing one value from a multi-value tag (omit `value` to detach the tag entirely):

```json
{ "path": "new/01.png", "tag": "genre", "op": "remove", "value": "fantasy" }
```

Setting an image file as a folder's cover thumbnail:

```json
{
  "path": "new",
  "tag": "cover",
  "value": "C:/Downloads/cover.jpg",
  "missing": "create",
  "valueType": "image"
}
```

When the image sits **next to the request file**, point at it with a relative path,
resolved against the queue folder. This exists so that moving a handful of files is
all a migration takes.

```json
{ "path": "new", "tag": "cover", "value": "cover.jpg",
  "missing": "create", "valueType": "image" }
```

Pointing at another item **inside** the managed folder (the value is its relative
path):

```json
{ "path": "new/01.png", "tag": "next chapter", "value": "new/02.png" }
```

#### Failure reasons and retrying

A failure mark **leaves what you wrote untouched** and appends only `failure`. Keys
the app does not interpret (your request id, say) are still there, so you can tell
which request the result belongs to. `reason` is there to branch on mechanically;
`message` is human-readable detail.

| `reason` | Meaning |
| --- | --- |
| `malformed` | Could not be read as a request (not JSON, a required field missing, an unknown name) |
| `targetMissing` | `path` is not on disk |
| `targetNotManaged` | On disk, but outside the managed scope, so it is not indexed |
| `systemTag` | System tags cannot be changed from outside |
| `tagMissing` | No tag of that name, and `missing: create` was not given |
| `valueTypeMissing` | The tag has to be created but `valueType` is absent |
| `valueTypeMismatch` | The existing tag has a different value type |
| `invalidValue` | The value could not be read as that type (number or date format, a missing image file, a missing link target) |

- **Entries carrying a `failure` are skipped on later passes**, so the same failure
  is not repeated every time the app starts. **To retry, overwrite the same file
  without `failure`.**
- Failed entries are tidied up once they get old or pile up too high. Entries not
  yet processed (with no mark) are never removed on age alone.
- On desktop, the status bar quietly shows how many entries were applied and how
  many failed on the last pass.

#### Rules worth knowing

- **Targets are addressed by path only.** There is no size or hash to cross-check
  against, so if a new file of the same name appears where a deleted one was, the
  tags land on that file.
- **Write the file to disk before putting the request in the queue.** That order is
  assumed: if the target is not on disk, the app does not wait but records a failure
  at once. If it is on disk and the app simply has not scanned it yet, no failure is
  recorded and the entry moves to the next pass.
- **System tags** (size, modification time, file name, and so on) are not valid
  targets.
- **Sending the same command again gives the same result** — a retry does not pile
  duplicates onto a multi-value tag.
- When a subfolder has a `.filetagger/` of its own, **its queue is processed when
  that folder is opened in the app.** Absorbing it into the parent moves only the
  pending entries into the parent queue.
- **The app holds no rules about which file should get which tag.** Deciding that
  and building the request is the external app's job.

### Exporting tags

The app **also exports in the same format**. Select items in the list and choose
File → Export Tags… (or use the context menu), and the tags of the selected items
are saved as **one** request file.

The receiving side has **no separate import feature** — drop the exported file into
that managed folder's `.filetagger/queue/` and the queue reads and applies it.

- Only the tags the selected items actually carry are offered, and all of them are
  selected by default.
- Turning off **Include tag values** attaches the tags with their values left empty.
- Turning on **Include image files** writes the custom thumbnail images **next to**
  the request file. Both files have to travel together for the images to attach, as
  the queue resolves relative paths against its own folder.
- Value type, multi-value permission, and color travel along so the tags can be
  created if missing.
- Link values are unwound into the target's path (a keyword's name) and carry
  `missingLink: keep` — **the value survives even if the target did not travel
  along**, waiting on the receiving side as an unresolved link.
- System tags are not included; they are derived automatically, and the queue
  refuses them.

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
  core/          shared utilities and constants
  l10n/          ARB translation files and the code generated from them
```

## License

[MIT](LICENSE)
