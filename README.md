# Handwriting to Text

Convert handwritten notes, letters, and whiteboards into clean, editable
digital text — entirely on your phone, with no internet connection and no
account required.

## What it does

- **Capture** a handwritten page with your camera, or import one or more
  images from your gallery.
- **Prepare** the page: crop, straighten, rotate, and adjust brightness or
  contrast. The app also automatically enhances contrast and sharpness to
  make handwriting easier to read.
- **Recognize** the handwriting into text, right on your device. Nothing is
  ever uploaded anywhere.
- **Review** the recognized text next to the original photo, so you can
  quickly spot and fix anything that wasn't read correctly.
- **Edit** the text with undo/redo, find & replace, and select-all/copy —
  without the clutter of a full document editor.
- **Export** as a plain text file, a PDF, or a Word document, or copy it to
  the clipboard, or share it directly to another app.
- **Revisit** anything you've converted before from History: search, mark
  favorites, rename, or delete.

## Everyday use

1. Open the app and tap **Take Photo** or **Import from Gallery**.
2. Capture as many pages as you need — they're staged together so you can
   add more, remove one, or continue when ready.
3. On the preparation screen, crop or rotate each page and adjust
   brightness/contrast if needed, then tap **Recognize Text**.
4. Once recognition finishes, review the text against the original image,
   make any corrections, and tap **Save**.
5. Tap **Export** to save the result as TXT, PDF, or DOCX, copy it, or share
   it to another app.

Multiple pages captured at once can either be merged into a single document
or kept as separate entries in History — you're asked which you'd prefer.

## Settings

- **Recognition Language** — choose the handwriting script to recognize
  (Latin, Chinese, Devanagari, Japanese, or Korean).
- **Image Enhancement** — automatically improve contrast and sharpness
  before recognition.
- **Default Export Format** — the format pre-selected when exporting.
- **Save Exports to Downloads** — also keep a copy of exported files in your
  phone's Downloads folder.
- **Share as Plain Text by Default** — prefer sharing raw text over a file.
- **Keep Original Image** — store the captured page alongside its
  recognized text so you can compare them later.
- **Auto-save History** — automatically save every conversion to History.
- **Theme** — light, dark, or match your system setting.

## Privacy

Handwriting recognition happens entirely on your device. Images and text are
never uploaded or sent anywhere. See the in-app Privacy Policy (Settings →
Privacy Policy) for full details.

## Building from source

This is a standard Flutter project.

```
flutter pub get
flutter build apk
```

The Android application ID and app name are each defined in a single place
for easy rebranding — see `android/app/build.gradle.kts` and
`android/app/src/main/res/values/strings.xml`.
