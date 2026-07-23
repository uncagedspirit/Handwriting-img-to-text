# Changelog

## 1.0.1

Bug fixes and performance improvements.

### Recognition
- Dramatically faster processing — a clear page is now read in seconds
  instead of minutes, and image enhancement only runs when a page actually
  needs it.
- More accurate results: text is rebuilt in proper reading order, and pages
  that read poorly are automatically retried with enhancement and rotation.
- A smooth, numerical progress indicator replaces the old spinner, with a
  live phase label and a cancel option.

### Editing and export
- Fixed the crop tool crashing the app.
- Brightness and contrast now preview live instead of appearing to do
  nothing.
- Undo, redo, select all, and find & replace now work reliably.
- Editing is no longer discarded when leaving the review screen without
  saving.
- Export and share now use your latest edits, handle documents with special
  characters in the title, and no longer overwrite earlier exports.
- Exported files reliably appear in your Downloads folder.

### History and storage
- Deleting a document now also removes its stored page images, and a new
  "Clear All History" option lets you reclaim space.
- Scans are given distinct, time-stamped names so they're easy to tell
  apart.

### Other
- Faster, lighter document lists (thumbnails no longer load full-size
  images).
- Added an anonymous usage-data setting so you can opt out at any time.
- New app icon.

## 1.0.0

Initial release.

### Overview

The first release of Handwriting to Text: a fully offline handwriting
recognition app. Capture a handwritten page, convert it into editable text
on-device, and export it — with no account, no cloud, and no internet
connection required at any step.

### Features

**Capture**
- Camera capture and gallery import, including multi-image batch selection.
- Multiple pages can be staged together before processing.

**Image Preparation**
- Crop, straighten, and rotate each page.
- Manual brightness and contrast adjustment.
- Automatic contrast and sharpness enhancement (toggleable in Settings).

**Recognition**
- On-device handwriting recognition supporting Latin, Chinese, Devanagari,
  Japanese, and Korean scripts.
- Multi-page recognition with paragraph structure preserved.
- Graceful, plain-language error messages when a page can't be read.

**Review & Edit**
- Side-by-side and toggled comparison between the original image and the
  recognized text.
- Text editing with undo/redo, find & replace, and select-all.

**Export**
- Export to TXT, PDF, or DOCX.
- Copy to clipboard or share directly to another app.
- Optional copy of exports saved to the Downloads folder.

**History**
- Automatic (optional) saving of every conversion.
- Search, favorite, rename, and delete past conversions.
- Batch multi-select delete.

**Settings**
- Recognition language, default export format, image enhancement toggle,
  keep-original-image toggle, auto-save history toggle, export destination,
  and light/dark/system theme.

**Other**
- First-launch onboarding walkthrough.
- Light and dark themes with full support for system font scaling.
- In-app Privacy Policy and Terms & Conditions.
