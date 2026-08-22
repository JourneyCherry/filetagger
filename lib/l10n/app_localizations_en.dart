// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuLanguage => 'Language';

  @override
  String get languageSystem => 'System setting';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get cmdOpenFolder => 'Open Folder';

  @override
  String get cmdCloseFolder => 'Close Folder';

  @override
  String get cmdRescan => 'Rescan';

  @override
  String get cmdSelectAll => 'Select All';

  @override
  String get cmdClearSelection => 'Clear Selection';

  @override
  String get cmdOpenNode => 'Open';

  @override
  String get cmdToggleExpand => 'Expand / Collapse';

  @override
  String get cmdAssignTags => 'Assign Tags';

  @override
  String get cmdReconnect => 'Find Original File';

  @override
  String get cmdRevealInFileManager => 'Show in File Manager';

  @override
  String get cmdExportSelection => 'Export Tags…';

  @override
  String get cmdManageTags => 'Manage Tags';

  @override
  String get cmdManageThumbnailTags => 'Thumbnail Tags…';

  @override
  String get cmdManageNameTags => 'Name Tags…';

  @override
  String get cmdManageSubtitleTags => 'Subtitle Tags…';

  @override
  String get cmdCreateKeyword => 'New Keyword…';

  @override
  String get cmdEditKeyword => 'Edit Keyword…';

  @override
  String get cmdDeleteKeyword => 'Delete Keyword';

  @override
  String get cmdHelp => 'Help';

  @override
  String get cmdCheckForUpdates => 'Check for Updates';

  @override
  String get cmdAbout => 'About';

  @override
  String get cmdExitApp => 'Exit';

  @override
  String get cmdTagDisplayOrder => 'Tag Display Order';

  @override
  String get cmdToggleFilterBar => 'Show Filter Conditions';

  @override
  String get cmdToggleSortBar => 'Show Sort Conditions';

  @override
  String get cmdToggleListEdit => 'Enable Editing in List';

  @override
  String get cmdToggleGrouping => 'Show Grouping';

  @override
  String get cmdTogglePresetBar => 'Show Presets';

  @override
  String get cmdTogglePreview => 'Show Preview';

  @override
  String get cmdMoveCursorUp => 'Cursor Up';

  @override
  String get cmdMoveCursorDown => 'Cursor Down';

  @override
  String get cmdExtendSelectionUp => 'Extend Selection Up';

  @override
  String get cmdExtendSelectionDown => 'Extend Selection Down';

  @override
  String get cmdMoveCursorUpNoSelect => 'Cursor Up Only';

  @override
  String get cmdMoveCursorDownNoSelect => 'Cursor Down Only';

  @override
  String get cmdCursorLeft => 'Collapse · Parent / Tag Left';

  @override
  String get cmdCursorRight => 'Expand / Tag Right';

  @override
  String get cmdToggleTagFocus => 'Enter / Leave Tag Column';

  @override
  String get cmdConfirmCursor => 'Confirm / Open';

  @override
  String get cmdToggleCursorSelection => 'Toggle Cursor Selection';

  @override
  String get cmdDeleteFocusedTag => 'Remove Tag';

  @override
  String get cmdEditFocusedTag => 'Edit Tag Value';

  @override
  String get cmdViewModeList => 'View Mode: List';

  @override
  String get cmdViewModeIcon => 'View Mode: Icons';

  @override
  String get cmdViewModeDetail => 'View Mode: Details';

  @override
  String get mobileFilterSort => 'Filter · Sort';

  @override
  String mobileSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get mobileMore => 'More';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonName => 'Name';

  @override
  String get commonNone => 'None';

  @override
  String get commonTag => 'Tags';

  @override
  String get commonAddTag => 'Add Tag';

  @override
  String get commonTagToAdd => 'Tag to Add';

  @override
  String get commonNewTag => 'New Tag';

  @override
  String get commonRemoveFromList => 'Remove from List';

  @override
  String get aboutChannelPortable => 'Portable';

  @override
  String get aboutChannelPackage => 'Installed';

  @override
  String get aboutVersionUnknown => 'Version unknown';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutVersionLine(String version, String channel) {
    return '$version · $channel';
  }

  @override
  String get aboutOpenBrowserFailed => 'Could not open a web browser.';

  @override
  String get aboutSummary =>
      'An app for organizing and finding files with tags. Tags are stored inside the managed folder, so they travel with it.';

  @override
  String get aboutSourceRepository => 'Source Repository';

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get updateOpenReleasePage => 'Open Release Page';

  @override
  String get updateOpenStore => 'Open in Store';

  @override
  String get updateOpenStoreFailed => 'Could not open the store app.';

  @override
  String get updateChecking => 'Checking…';

  @override
  String get updateAvailableHeadline => 'An update is available.';

  @override
  String updateAvailableDetail(String current, String latest) {
    return 'Current $current · Latest $latest';
  }

  @override
  String get updateUpToDateHeadline => 'You are up to date.';

  @override
  String updateUpToDateDetail(String current) {
    return 'Current $current';
  }

  @override
  String get updateUnknownVersionHeadline => 'Version unknown.';

  @override
  String get updateUnknownVersionDetail =>
      'The version of this build cannot be determined, so it cannot be compared with released builds.';

  @override
  String get updateManagedByStoreHeadline => 'The store manages updates.';

  @override
  String get updateManagedByStoreDetail =>
      'This build is updated through the store, so the app does not download and install updates itself.';

  @override
  String get updateFailedHeadline => 'Could not check for updates.';

  @override
  String get updateFailedDetail =>
      'Check your network connection and try again.';

  @override
  String get helpTabHowTo => 'How To';

  @override
  String get helpTabTips => 'Tips';

  @override
  String get helpTabShortcuts => 'Features & Shortcuts';

  @override
  String get helpTabSystemTags => 'System Tags';

  @override
  String get helpTopicTagsTitle => 'Tags and Tag Values';

  @override
  String get helpTopicTagsBody =>
      'You define a kind of tag once and then assign it to files and folders. A \"label\" tag carries no value and only records whether it is attached, while text, number, and date tags carry a value as well. A \"link\" tag holds another item in the workspace, and an \"image\" tag holds an image file brought in from outside. The value type decides how sorting compares values (alphabetical, numeric, chronological).';

  @override
  String get helpTopicStorageTitle => 'Where Tags Are Stored';

  @override
  String get helpTopicStorageBody =>
      'Tags are stored in a hidden folder inside the managed folder. Move or copy that folder and the tags travel with it. Only machine-wide settings, such as the list of recently opened folders, stay in the OS application data folder.';

  @override
  String get helpTopicManageModeTitle => 'Per-Folder Management Mode';

  @override
  String get helpTopicManageModeBody =>
      'Every folder is handled in one of three ways: \"folder only\" (treated as a single item with its contents hidden), \"manage contents\" (direct children only), or \"manage recursively\" (all the way down). A folder with no choice of its own inherits the one above it. Change the mode to keep the contents of a large folder out of the index.';

  @override
  String get helpTopicQueryRowsTitle => 'The Filter, Sort, and Group Rows';

  @override
  String get helpTopicQueryRowsBody =>
      'The three rows in the toolbar share one syntax and differ only in meaning: the filter row holds conditions, the sort row holds steps, and the group row holds the key to bundle by. In any row you can drag a chip to reorder it, or click an empty spot to type the condition directly. A row remembers the tag itself rather than its name, so renaming a tag later does not break it. Clicking a sort capsule cycles through ascending, descending, and random; random shuffles only the order within that tag value and leaves items with equal values untouched, so later sort steps still hold. Picking random again reshuffles.';

  @override
  String get helpTopicPresetsTitle => 'Query Presets';

  @override
  String get helpTopicPresetsBody =>
      'A preset gives a name to one set of filter, sort, and group conditions along with the name, subtitle, and thumbnail tags. Choosing a preset clears everything currently applied and swaps in that set; it does not add to what is already there. The five travel together because the work you are doing changes not only what you look for but also what you want to see in the name column and the thumbnail. Hover a capsule to see what it holds. A preset that matches exactly what is applied right now is highlighted, so you can tell what you are looking at. Right-click a preset (long-press on mobile) to rename or overwrite it, and drag to reorder. Like tags, presets live inside the managed folder and travel with it. Column-header sorting in the details view, the view mode, and the zoom level are not search conditions and are not stored in a preset.';

  @override
  String get helpTopicPresetSourcesTitle =>
      'Name, Subtitle, and Thumbnail Tags Belong to a Preset';

  @override
  String get helpTopicPresetSourcesBody =>
      'The name, subtitle, and thumbnail tags look like settings you fix once, but they are stored in presets too. Loading a preset therefore changes not only the filter, sort, and group rows but also what the name column, the line beneath it, and the thumbnail show. A preset saved without any of the three falls back to the file name, the path, and the default thumbnail when loaded, and so do presets made before this feature existed. Set things up the way you want and overwrite that preset, and they come back together from then on.';

  @override
  String get helpTopicNestedTitle =>
      'When One Managed Folder Sits Inside Another';

  @override
  String get helpTopicNestedBody =>
      'When a folder that already had tags of its own turns up inside another managed folder, the app asks what to do. Absorbing merges the inner tags into the outer folder, leaving it independent touches nothing, and ignoring skips it just this once. Absorbing is blocked when the inner folder was saved in a newer format.';

  @override
  String get helpTopicKeywordTitle => 'Keywords: Items With Nothing on Disk';

  @override
  String get helpTopicKeywordBody =>
      'A keyword is an item that exists only in the tag store, with no file or folder on disk. A name is all it has; anything further, such as the nationality or account of an artist, is attached to the keyword as tags, so that it takes part in filtering, sorting, and grouping like any other item. A file points at a keyword through a link tag. Keywords are never scanned, so folder management modes and file moves do not affect them, and they sit at the top level of the list.';

  @override
  String get helpTopicTypeAheadTitle => 'Jump to an Item by Typing';

  @override
  String get helpTopicTypeAheadBody =>
      'With the list focused, typing letters jumps the cursor to the item that starts with them. Matching follows the name shown in the name column, so a name swapped in by a name tag is the one that gets matched. Keep typing to narrow the search, or press the same letter repeatedly to cycle through the items that start with it. Pause for a moment and the search term clears, so the next letter starts fresh. This moves the cursor rather than shrinking the list, so it works with a filter applied. It also finds items hidden inside a collapsed group or folder: anything the filter did not remove is a candidate, and only the groups and folders leading to the match are expanded. All three view modes support it, and the icon view searches within the level you have drilled into.';

  @override
  String get helpTopicDisconnectedTitle => 'Disconnected Items';

  @override
  String get helpTopicDisconnectedBody =>
      'Moving or deleting a file outside the app leaves the item marked disconnected, with its tags preserved. If a file with the same content turns up again it is reattached automatically, and if not, Find Original File lets you point at it yourself and bring the tags back.';

  @override
  String get helpGroupFolder => 'Folder';

  @override
  String get helpGroupSelectionTags => 'Selection and Tags';

  @override
  String get helpGroupKeyword => 'Keywords';

  @override
  String get helpGroupKeywordNote =>
      'Edit and Delete apply when exactly one keyword is selected.';

  @override
  String get helpGroupView => 'View';

  @override
  String get helpGroupKeyboardNav => 'Keyboard Navigation';

  @override
  String get helpGroupKeyboardNavNote =>
      'These apply in the list view while the list has focus. The icon and details views have their own arrow-key movement.';

  @override
  String get helpGroupHelp => 'Help';

  @override
  String get helpShortcutsIntro =>
      'Everything you can invoke from a menu or button, with its shortcut where there is one. Actions that are unavailable right now, such as assigning tags with nothing selected, are listed as well.';

  @override
  String helpTipRelatedCommand(String command) {
    return 'Related action: $command';
  }

  @override
  String get helpSystemTagOverview =>
      'The tags below are attached automatically, with values drawn from the files themselves. You cannot create or delete them and they are never stored, but they work in filters, sorts, and groups exactly like the tags you make. Tag management only decides whether each one is shown in the list. When an item has no value, the size of a folder for instance, the tag counts as not attached to that item.';

  @override
  String get helpSystemTagFileSize =>
      'The size of the file in bytes. It is never attached to folders, so filtering on this tag with \"exists\" leaves only files.';

  @override
  String get helpSystemTagModifiedTime =>
      'The last modification time recorded by the file system. It sorts and compares chronologically.';

  @override
  String get helpSystemTagExtension =>
      'Holds the extension in lower case, without the dot. It is not attached to folders or to files with no extension, and a name that merely begins with a dot does not count as having one. Group by this value to see how many files of each kind there are.';

  @override
  String get helpSystemTagImageWidth =>
      'The width of the image in pixels. It is attached only to images whose dimensions can be read, so filtering on it with \"exists\" gathers just the images. Being a number, it can sort largest first or filter with \"at least\".';

  @override
  String get helpSystemTagImageHeight =>
      'The height of the image in pixels. It stands apart from the width, which is always attached together with it or not at all, so width and height can each serve as a sort key or a condition.';

  @override
  String get helpSystemTagFileName =>
      'The name of the item. It is the only system tag whose value can be edited, and editing it renames the file on disk. A keyword has nothing on disk, so only the keyword name changes.';

  @override
  String get helpSystemTagChildFileCount =>
      'How many files the folder holds directly. Subfolders and the files inside them are not counted. It is attached only to folders, so it doubles as a folder marker: filter with \"exists\" to keep only folders, or exclude it to keep only files. An empty folder still gets a count of zero. Folders whose contents are hidden carry it too, so you can gauge how much is inside without opening them, or sort by the count.';

  @override
  String get helpSystemTagKeyword =>
      'A marker attached only to keywords, with no value. Exclude this tag in the filter to keep keywords out of the list.';

  @override
  String get helpSystemTagUnresolvedLink =>
      'A valueless marker attached to any item holding at least one link tag whose target cannot be found. It appears when the target was deleted, or when a link imported from another tagger points at something that is not in this folder yet. Filter with \"exists\" to gather them, then double-click each link chip to reconnect it or press x to remove it.';

  @override
  String get tipHideFilesTitle => 'Hiding Files From the List';

  @override
  String get tipHideFilesBody =>
      'There is no dedicated hide feature. Instead, make a tag of your own, something like \"hidden\", assign it to the items you want out of the way, and keep that tag excluded in the filter row. The tag stays attached, so lifting the exclusion brings them back.';

  @override
  String get tipHideFolderTitle => 'Taking a Whole Folder Out of the List';

  @override
  String get tipHideFolderBody =>
      'The absence of a separate \"ignore\" management mode has the same reason. Attach a \"hidden\" tag to the folder and exclude it in the filter, and that folder together with everything under it drops out of the list.';

  @override
  String get tipFolderGroupTitle =>
      'No Need to Propagate a Folder Tag Downward';

  @override
  String get tipFolderGroupBody =>
      'You do not have to copy a folder tag onto every file beneath it. Put \"folder hierarchy\" in the group row, where it sits by default, and the files gather under that folder header, which achieves what propagating the tag would. Use it when you want to manage tags per folder.';

  @override
  String get tipGroupByValueTitle => 'Grouping by Tag Value';

  @override
  String get tipGroupByValueBody =>
      'Put a tag name in the group row and items are bundled by that tag value, the way SQL GROUP BY works, with the count for each value in the header. Several steps nest from the outside in, and mixing in \"folder hierarchy\" lets you split the inside of a folder by value again.';

  @override
  String get tipFilterTextTitle => 'Typing Filters as Text';

  @override
  String get tipFilterTextBody =>
      'Click an empty spot in the filter row to type conditions as text. Pick tag names and operators from the autocomplete, and press space to fold the condition into a capsule. A folded capsule behaves like a single character, so deleting and moving it works just like ordinary text.';

  @override
  String get tipSortTextTitle => 'Reordering Sort Priority by Cut and Paste';

  @override
  String get tipSortTextBody =>
      'The sort row works the same way when you click an empty spot. Left-to-right order is exactly the sort priority, so cutting and pasting a capsule reorders faster than dragging. A prefix before the name makes it descending or random.';

  @override
  String get tipPresetSwitchTitle =>
      'Switching Conditions and Display Together';

  @override
  String get tipPresetSwitchBody =>
      'What you want to see while picking something to read differs from what you want while tidying up. Arrange the filter, sort, and group rows together with the name and thumbnail tags, save that as a preset, and from then on one capsule brings the whole combination back. Keep one preset that leaves only \"unread\", puts the title tag in the name column, and shows covers as thumbnails, and another that finds items with no tags and shows the real file names.';

  @override
  String get tipThumbnailSourceTitle =>
      'Using the Image You Want as a Thumbnail';

  @override
  String get tipThumbnailSourceBody =>
      'Make a tag with the \"link\" value type and assign it to a file, choosing a target inside the workspace, and the image of that target becomes the thumbnail. To use an image from outside the workspace, make an \"image\" type tag and pick the file. Which tags act as thumbnail sources, and in what order, is set in Thumbnail Tags.';

  @override
  String get tipKeywordEntityTitle =>
      'Turning Hard-to-Store Information Into a Keyword';

  @override
  String get tipKeywordEntityBody =>
      'Something like an artist, which carries several pieces of information of its own such as nationality and account, leaves nowhere to put them once written as a tag value string. Create a keyword, attach those details to it as tags, and point at that keyword from the picture file with a link tag. Double-clicking a keyword capsule jumps straight to it, and the tags on the keyword can be used to find the pictures in turn.';

  @override
  String get tipLinkNextTitle => 'Chaining to the Next Item With a Link Tag';

  @override
  String get tipLinkNextBody =>
      'Link tags are good for more than thumbnails. Double-clicking a link capsule (double-tap on mobile) jumps straight to the item it points at, so you can chain a reading order through tags, such as the next volume of a comic.';

  @override
  String get tipNameTagTitle => 'Showing a Tag Value Instead of the File Name';

  @override
  String get tipNameTagBody =>
      'An unreadable downloaded file name is no reason to touch the file. Designate a text tag such as the title as a name tag, and its value appears in the name column instead. Order several of them and the first one found is used; items without that tag keep their original file name.';

  @override
  String get tipSubtitleTagTitle =>
      'Showing Something Other Than the Path Below the Name';

  @override
  String get tipSubtitleTagBody =>
      'The line below the name shows the path by default. While browsing by tag you may care more about another axis, such as artist or year; designate a subtitle tag and that value appears instead. It works like name tags, so you can order several, and items without the tag keep showing the path.';

  @override
  String get tipExportTagsTitle => 'Moving Tags to Another Folder';

  @override
  String get tipExportTagsBody =>
      'There is no separate import feature. Select items and export, and a file in queue format comes out; drop that file into .filetagger/queue/ of the receiving folder and it is applied as is. Tags that are missing there are created with their value type and color intact.';

  @override
  String get tipUnresolvedLinksTitle => 'Gathering Broken Links to Fix';

  @override
  String get tipUnresolvedLinksBody =>
      'When the item a link pointed at was deleted, or the target of a link brought from another folder is not there yet, the link capsule gets a marker. Filter the \"unresolved link\" tag with \"exists\" to gather just those items, then double-click a capsule to reconnect it or press x to remove it.';

  @override
  String homeScanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String homeNoAppForFile(String name) {
    return 'No app is available to open this file: $name';
  }

  @override
  String homeRevealFailed(String error) {
    return 'Could not show it in the file manager: $error';
  }

  @override
  String get homeRecentFolders => 'Recent Folders';

  @override
  String homeSettingsLoadFailed(String error) {
    return 'Could not load settings: $error';
  }

  @override
  String get homeNoRecentFolders => 'No folder has been opened yet.';

  @override
  String get menuKeyword => 'Keywords';

  @override
  String get menuFolderManageOptions => 'Folder Management';

  @override
  String get tooltipFolderManageMode => 'Folder management mode';

  @override
  String get keywordCreateTitle => 'New Keyword';

  @override
  String get keywordCreateConfirm => 'Create';

  @override
  String get keywordEditTitle => 'Edit Keyword';

  @override
  String get exportNothingToExport => 'There are no tag assignments to export.';

  @override
  String get exportFileTypeLabel => 'Queue file';

  @override
  String exportDone(int count) {
    return 'Exported $count tags.';
  }

  @override
  String exportDoneWithImages(int count, int images) {
    return 'Exported $count tags ($images images included).';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get assignTitleSingleFile => 'One file';

  @override
  String assignTitleFiles(int count) {
    return '$count files';
  }

  @override
  String get renameTitle => 'Rename';

  @override
  String get renameNewName => 'New name';

  @override
  String get renameConfirm => 'Rename';

  @override
  String get renamePathSeparator =>
      'A name cannot contain a path separator (/ \\).';

  @override
  String renameFailed(String error) {
    return 'Rename failed: $error';
  }

  @override
  String get scopeRootFolder => 'the root folder';

  @override
  String get scopeReductionTitle => 'Narrowing the Managed Scope';

  @override
  String scopeReductionTarget(String target) {
    return 'This narrows the managed scope of $target.';
  }

  @override
  String scopeReductionWarning(int count) {
    return 'The tags on $count items that fall outside the scope are removed as well, and this cannot be undone.';
  }

  @override
  String get scopeReductionConfirm => 'Narrow Scope';

  @override
  String get nestedTitle => 'Nested Tag Folder Found';

  @override
  String get nestedPrompt =>
      'A subfolder has tag data of its own. Choose how to handle it.';

  @override
  String get nestedAbsorb => 'Absorb';

  @override
  String get nestedAbsorbDetail =>
      'Brings its tags and listing into the current workspace and manages them here.';

  @override
  String get nestedAbsorbBlocked =>
      'The inner tagger uses a newer version, so it cannot be absorbed.';

  @override
  String get nestedIndependent => 'Independent';

  @override
  String get nestedIndependentDetail =>
      'Keeps it as a single item whose contents stay closed, leaving the inner tagger untouched.';

  @override
  String get nestedIgnore => 'Ignore';

  @override
  String get nestedIgnoreDetail =>
      'Ignores the inner tagger and indexes the files inside it under the current rules.';

  @override
  String get nestedRemoveSource =>
      'Remove the inner tag folder after absorbing';

  @override
  String get nestedRemoveSourceOn =>
      'The inner .filetagger folder is deleted. This cannot be undone.';

  @override
  String get nestedRemoveSourceOff =>
      'The inner tagger is kept and treated as ignored from then on.';

  @override
  String get nestedLater => 'Later';

  @override
  String get nestedApply => 'Apply';

  @override
  String get commonOk => 'OK';

  @override
  String get menuFile => 'File';

  @override
  String get menuRecentFolders => 'Open Recent';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuRootManageMode => 'Root Folder Management';

  @override
  String get menuView => 'View';

  @override
  String get menuViewMode => 'View Mode';

  @override
  String get menuTheme => 'Theme';

  @override
  String get menuTag => 'Tags';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuHelpTopics => 'By Topic';

  @override
  String get themeSystem => 'System setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get rootManageDirectOnly => 'Manage direct items only';

  @override
  String get rootManageRecursive => 'Manage everything recursively';

  @override
  String get viewModeList => 'List';

  @override
  String get viewModeIcon => 'Icons';

  @override
  String get viewModeDetail => 'Details';

  @override
  String get folderManageOpaque => 'Folder only (contents hidden)';

  @override
  String get folderManageManaged => 'Manage contents';

  @override
  String get folderManageRecursive => 'Manage recursively';

  @override
  String get chipCustomImage => 'Custom image';

  @override
  String get chipLinkNoTarget => '(none)';

  @override
  String get chipUnresolvedHint =>
      'The target could not be found. Double-click to reconnect it, or press x to remove it.';

  @override
  String get chipDeletedTag => '(deleted tag)';

  @override
  String get colorPickerTitle => 'Pick a Color';

  @override
  String get tagPickerLabel => 'Tag';

  @override
  String get tagPickerSearchHint => 'Search tag names';

  @override
  String get pickerImageTypeLabel => 'Images';

  @override
  String get thumbnailRegisterFailed => 'Could not register the image.';

  @override
  String get groupFolderHierarchyDesc => 'Path hierarchy';

  @override
  String get queryEmpty => 'None';

  @override
  String get valueTypeLabel => 'Label';

  @override
  String get valueTypeText => 'Text';

  @override
  String get valueTypeNumber => 'Number';

  @override
  String get valueTypeDate => 'Date';

  @override
  String get valueTypeLink => 'Link';

  @override
  String get valueTypeImage => 'Image';

  @override
  String get filterOpExists => 'has';

  @override
  String get filterOpContains => 'contains';

  @override
  String get filterOpNotContains => 'excludes';

  @override
  String get filterOpMenuExists => 'has (exists)';

  @override
  String get filterOpMenuEquals => '= equals';

  @override
  String get filterOpMenuNotEquals => '≠ not equal';

  @override
  String get filterOpMenuLessThan => '< less than';

  @override
  String get filterOpMenuLessOrEqual => '≤ at most';

  @override
  String get filterOpMenuGreaterThan => '> greater than';

  @override
  String get filterOpMenuGreaterOrEqual => '≥ at least';

  @override
  String get filterOpMenuContains => 'contains';

  @override
  String get filterOpMenuNotContains => 'excludes';

  @override
  String get commonEdit => 'Edit';

  @override
  String get tagVisibilityHide => 'Hide from the list';

  @override
  String get tagVisibilityShow => 'Show in the list';

  @override
  String get tagMergeIntoThis => 'Merge another tag into this one';

  @override
  String get tagMergeNoCandidates =>
      'There is no tag that can be merged into this one';

  @override
  String get tagDeleteTitle => 'Delete Tag';

  @override
  String tagDeleteTarget(String name) {
    return 'This deletes the tag $name.';
  }

  @override
  String tagDeleteWarning(int count) {
    return 'Every value of this tag on $count files is removed as well, and this cannot be undone.';
  }

  @override
  String tagMergeTitle(String name) {
    return 'Merge Into $name';
  }

  @override
  String tagMergeDescription(String name) {
    return 'The assignments of the tags selected below move to $name, and those tags are removed. The name and color of $name are kept.';
  }

  @override
  String tagMergeSingleValueNote(String name) {
    return 'When both tags are on the same file, the value of $name is kept and the value from the merged tag is discarded.';
  }

  @override
  String get tagMergeConfirm => 'Merge';

  @override
  String tagMergeFailed(String error) {
    return 'Merge failed: $error';
  }

  @override
  String get tagNameRequired => 'Enter a name.';

  @override
  String get tagSaveFailed => 'Could not save. The name may already be taken.';

  @override
  String get tagEditTitle => 'Edit Tag';

  @override
  String get tagValueTypeField => 'Value type';

  @override
  String get tagColorField => 'Color';

  @override
  String get tagAllowMultiple => 'Allow multiple assignments';

  @override
  String get tagAllowMultipleDetail =>
      'Lets this tag be attached to one file more than once.';

  @override
  String get tagColorCustom => 'Pick a color';

  @override
  String get tagManageTitle => 'Manage Tags';

  @override
  String get tagManageOrderNote =>
      'The higher a tag sits here, the earlier it appears in a list row. System tags are derived from the files themselves, so only their visibility can be toggled; they sit after your own tags by default, but can be dragged anywhere you like.';

  @override
  String get tagBadgeMultiple => 'Multiple';

  @override
  String get tagBadgeEditable => 'Editable';

  @override
  String tagBadgeEditableWithType(String type) {
    return 'Editable · $type';
  }

  @override
  String get tagOrderTitle => 'Tag Display Order';

  @override
  String get tagOrderNote =>
      'The higher a tag sits here, the earlier it appears in a list row. System tags sit after your own tags by default, but can be dragged anywhere you like.';

  @override
  String get thumbnailTagTitle => 'Thumbnail Tags';

  @override
  String get tagManageOpenFolderFirst => 'Open a folder first.';

  @override
  String tagManageLoadFailed(String error) {
    return 'Could not load tags: $error';
  }

  @override
  String get tagManageEmpty => 'No tags have been created yet.';

  @override
  String get systemTagSection => 'System Tags';

  @override
  String get systemTagSectionNote =>
      'These tags are derived from the files themselves. Only their visibility can be toggled.';

  @override
  String get rowPresets => 'Presets';

  @override
  String get rowFilter => 'Filter';

  @override
  String get rowSort => 'Sort';

  @override
  String get rowGroup => 'Group';

  @override
  String get presetSaveTooltip => 'Save the current conditions as a preset';

  @override
  String get filterAddTooltip => 'Add a filter condition';

  @override
  String get filterClearTooltip => 'Clear all filter conditions';

  @override
  String get sortAddTooltip => 'Add a sort step';

  @override
  String get sortClearTooltip => 'Clear all sort steps';

  @override
  String get groupAddTooltip => 'Add a grouping key';

  @override
  String get groupClearTooltip => 'Clear all grouping keys';

  @override
  String get filterDateRequired => 'Choose a date.';

  @override
  String get filterNumberRequired => 'Enter a number.';

  @override
  String get filterConditionAddTitle => 'Add Filter Condition';

  @override
  String get filterConditionEditTitle => 'Edit Filter Condition';

  @override
  String get filterIncludeSegment => 'Include';

  @override
  String get filterExcludeSegment => 'Exclude';

  @override
  String get filterOperatorField => 'Operator';

  @override
  String get filterPickDate => 'Choose a date';

  @override
  String get filterPickDateButton => 'Choose';

  @override
  String get filterValueField => 'Value';

  @override
  String get sortKeyAddTitle => 'Add Sort Step';

  @override
  String get sortLabelNote =>
      'A label tag sorts items that carry it to the top, whatever the direction.';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get sortRandom => 'Random';

  @override
  String get sortRandomNote =>
      'Shuffles instead of ordering by value. Items with equal values are left undisturbed, so later sort steps still apply.';

  @override
  String get groupKeyAddTitle => 'Add Grouping Key';

  @override
  String get commonAdd => 'Add';

  @override
  String presetAppliedWithDropped(int count) {
    return '$count items that point at missing tags were left out.';
  }

  @override
  String get presetRenameTitle => 'Rename Preset';

  @override
  String get presetDeleteTitle => 'Delete Preset';

  @override
  String presetDeleteBody(String name) {
    return 'This deletes the preset $name. The conditions applied right now are left as they are.';
  }

  @override
  String get presetMenuRename => 'Rename…';

  @override
  String get presetMenuOverwrite => 'Overwrite With Current Conditions';

  @override
  String presetSummaryFilter(String value) {
    return 'Filter: $value';
  }

  @override
  String presetSummarySort(String value) {
    return 'Sort: $value';
  }

  @override
  String presetSummaryGroup(String value) {
    return 'Group: $value';
  }

  @override
  String presetSummaryName(String value) {
    return 'Name: $value';
  }

  @override
  String presetSummarySubtitle(String value) {
    return 'Subtitle: $value';
  }

  @override
  String presetSummaryThumbnail(String value) {
    return 'Thumbnail: $value';
  }

  @override
  String get sortDefaultByName => 'Default (by name)';

  @override
  String get groupNotGrouped => 'Not grouped';

  @override
  String get sourceDefaultName => 'File name';

  @override
  String get sourceDefaultSubtitle => 'Path';

  @override
  String get sourceDefaultThumbnail => 'Default';

  @override
  String get presetSaveTitle => 'Save Current Conditions as a Preset';

  @override
  String get presetOverwriteHelper =>
      'A preset with this name will be overwritten.';

  @override
  String get presetSaveOverwrite => 'Overwrite';

  @override
  String get rowSubtitle => 'Subtitle';

  @override
  String get rowThumbnail => 'Thumbnail';

  @override
  String sourceMissingTag(int tagId) {
    return '(missing tag $tagId)';
  }

  @override
  String get nameTagTitle => 'Name Tags';

  @override
  String get nameTagNote =>
      'The priority of what appears in the name column. The list is read from top to bottom and the value of the first tag that yields text is used. If none do, the file name is used. This setting is stored in query presets, so loading a preset changes it too.';

  @override
  String get nameTagEmpty =>
      'No tag has been chosen. Add one below.\n(Left empty, the file name is used as is.)';

  @override
  String get subtitleTagTitle => 'Subtitle Tags';

  @override
  String get subtitleTagNote =>
      'The priority of what appears on the line below the name. The list is read from top to bottom and the value of the first tag that yields text is used. If none do, the path is used. This setting is stored in query presets, so loading a preset changes it too.';

  @override
  String get subtitleTagEmpty =>
      'No tag has been chosen. Add one below.\n(Left empty, the path is used as is.)';

  @override
  String get thumbnailTagNote =>
      'The priority of thumbnail sources. The list is read from top to bottom and the first source that yields an image is used. If none do, the default thumbnail is used: the image itself, or a representative image for a folder. Link and image tags are created in tag management. This setting is stored in query presets, so loading a preset changes it too.';

  @override
  String get thumbnailTagEmpty =>
      'No source has been chosen. Add one below.\n(Left empty, only the default thumbnail is used.)';

  @override
  String get keywordDeleteTitle => 'Delete Keyword';

  @override
  String keywordDeleteBody(String name) {
    return 'This deletes the keyword $name together with its tags. It cannot be undone.';
  }

  @override
  String get linkTargetPickerTitle => 'Choose a Link Target';

  @override
  String get linkTargetSearchHint => 'Search by file name';

  @override
  String get linkTargetNoMatch => 'No file matches.';

  @override
  String get tagValueNumberRequired => 'Enter a number.';

  @override
  String tagValuePromptTitle(String name) {
    return 'Value for $name';
  }

  @override
  String get tagValueField => 'Value';

  @override
  String get tagValueNumberHelper =>
      'Left empty, a default value is filled in.';

  @override
  String get tagValueTextHelper => 'An empty value can be saved as well.';

  @override
  String get assignedTags => 'Assigned Tags';

  @override
  String get assignedTagsEmpty => 'No tags assigned yet.';

  @override
  String get assignNoDefinitions => 'Create a tag in tag management first.';

  @override
  String assignFileCount(int count, int total) {
    return '$count/$total files';
  }

  @override
  String get assignMixedValue => 'Mixed values';

  @override
  String get assignSetValueForAll => 'Set this value on all of them';

  @override
  String get assignUnassignAll => 'Unassign from all';

  @override
  String get assignConfirm => 'Assign';

  @override
  String get assignLinkNoTarget => 'No target chosen';

  @override
  String get assignLinkPick => 'Choose target';

  @override
  String get assignNoImage => 'No image';

  @override
  String get assignImagePick => 'Choose image';

  @override
  String get assignImageChange => 'Change image';

  @override
  String get assignDateToday => 'Today (not chosen)';

  @override
  String get assignLinkRequired => 'Choose a link target.';

  @override
  String get assignImageRequired => 'Choose an image.';

  @override
  String get scanning => 'Scanning…';

  @override
  String scanningSeen(int seen) {
    return 'Scanning… $seen entries seen';
  }

  @override
  String scanningSeenIndexed(int seen, int indexed) {
    return 'Scanning… $seen entries seen · $indexed files read';
  }

  @override
  String get statusNoFolder => 'No folder open';

  @override
  String get statusLoading => 'Loading the list…';

  @override
  String statusItemCount(int count) {
    return '$count items';
  }

  @override
  String statusSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get statusClearSelection => 'Clear';

  @override
  String statusFilterCount(int count) {
    return 'Filter $count';
  }

  @override
  String statusSortCount(int count) {
    return 'Sort $count';
  }

  @override
  String get statusDbConnected => 'DB connected';

  @override
  String get statusDbDisconnected => 'DB not connected';

  @override
  String get statusHidePreview => 'Hide the preview';

  @override
  String get statusShowPreview => 'Show the preview';

  @override
  String get statusUpdateHint => 'Click to open the release page.';

  @override
  String statusNewVersion(String version) {
    return 'New version $version';
  }

  @override
  String get statusSettingsUnsavedHint =>
      'The settings file cannot be written, so the theme and the recent folder list last only for this run.';

  @override
  String get statusSettingsUnsaved => 'Settings are not being saved';

  @override
  String get statusExternalHintWithFailures =>
      'Tag changes requested by an external app. The reason for each failure is recorded in the queue file.';

  @override
  String get statusExternalHint => 'Tag changes requested by an external app.';

  @override
  String statusExternalApplied(int count) {
    return 'Applied $count';
  }

  @override
  String statusExternalFailed(int count) {
    return 'Failed $count';
  }

  @override
  String listLoadFailed(String error) {
    return 'Could not load the list: $error';
  }

  @override
  String get listEmptyFiltered => 'No file matches the filter conditions.';

  @override
  String get listEmptyFolder => 'This folder has no files to show.';

  @override
  String get listEmptyGroup => 'This group has no items to show.';

  @override
  String get treeCollapse => 'Collapse';

  @override
  String get treeExpand => 'Expand';

  @override
  String get markMissing =>
      'Disconnected — find the original file to reattach the tags';

  @override
  String get markOpaqueFolder =>
      'Contents hidden — choose Manage contents in the menu to open it';

  @override
  String get subtitleKeyword => 'Keyword';

  @override
  String groupUnclassified(String name) {
    return '$name · (unclassified)';
  }

  @override
  String get detailColumnAdd => 'Add…';

  @override
  String get detailColumnRemove => 'Remove';

  @override
  String get iconViewAll => 'All';

  @override
  String get iconViewUp => 'Up';

  @override
  String previewSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get previewEmpty => 'Select an item to see a preview';

  @override
  String get sheetFolderManageTitle => 'Folder Management Mode';

  @override
  String get sheetFolderOpaque => 'Folder only';

  @override
  String get sheetFolderOpaqueDetail =>
      'Treats it as a single item and hides what is inside.';

  @override
  String get sheetFolderManagedDetail => 'Indexes only its direct contents.';

  @override
  String get sheetFolderRecursiveDetail =>
      'Indexes subfolders all the way down as well.';

  @override
  String get reconnectTitle => 'Find the Original File';

  @override
  String reconnectPrompt(String name) {
    return 'Choose the original file to move the tags of $name onto. Candidates with similar names come first. If the original is gone, \"Stop preserving\" removes the tags instead.';
  }

  @override
  String get reconnectSearchHint => 'Search by path';

  @override
  String get reconnectNoCandidates =>
      'There is no candidate to connect to. Candidates are items with no tags yet.';

  @override
  String get reconnectNoMatch => 'No search result.';

  @override
  String get reconnectRemove => 'Stop preserving (remove)';

  @override
  String get exportTitle => 'Export Tags';

  @override
  String exportPrompt(int count) {
    return 'Exports the tags of $count items into one queue file. The receiving side only has to drop that file into the queue of its own folder.';
  }

  @override
  String get exportTagsToSend => 'Tags to Export';

  @override
  String get exportSelectAll => 'All';

  @override
  String get exportSelectNone => 'None';

  @override
  String get exportNoCandidates => 'The selected items carry no tags.';

  @override
  String get exportIncludeValues => 'Include tag values';

  @override
  String get exportIncludeValuesDetail =>
      'Turned off, only the tags are attached and their values go empty.';

  @override
  String get exportIncludeImages => 'Include image files';

  @override
  String get exportIncludeImagesDetail =>
      'Writes the custom thumbnail images alongside the queue file.';

  @override
  String get exportConfirm => 'Export…';

  @override
  String get systemTagFileSize => 'Size';

  @override
  String get systemTagModifiedTime => 'Modified';

  @override
  String get systemTagExtension => 'Extension';

  @override
  String get systemTagImageWidth => 'Image width';

  @override
  String get systemTagImageHeight => 'Image height';

  @override
  String get systemTagFileName => 'File name';

  @override
  String get systemTagChildFileCount => 'Files inside';

  @override
  String get systemTagKeyword => 'Keyword';

  @override
  String get systemTagUnresolvedLink => 'Unresolved link';

  @override
  String get groupFolderHierarchy => 'Folder hierarchy';

  @override
  String get keywordNameEmpty => 'Enter a keyword name.';

  @override
  String get keywordNameSeparator =>
      'A name cannot contain a path separator (/ \\).';

  @override
  String get keywordNameDuplicate => 'A keyword with that name already exists.';

  @override
  String get renameTargetExists => 'An item with that name already exists.';

  @override
  String get revealUnsupported =>
      'Opening a file manager is not supported on this platform.';
}
