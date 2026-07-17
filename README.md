Why myDiary?

Many diary applications store data in proprietary cloud services.
myDiary stores everything locally and allows the entire diary to be exported as an open Diary Package.

Your diary remains yours, independent of any online platform.

# myDiary

This is a screenshot showing the app I’ve just created (which, of course, works offline) displaying a post I made on Facebook at 16:37 on 9 June 2023.

![Timeline](docs/images/timeline.png)

A macOS diary application built with SwiftUI and SQLite.

myDiary is a personal diary application designed for long-term archiving and exploration of your life records.

Unlike social networking services, all diary data is stored locally and can be exported as an open **Diary Package**.

---

## Features

### 📝 Diary Editing

- Create, edit and delete diary entries
- Rich text body
- Multiple images per post
- Nested comments / replies
- Parent-child comment relationships
- Related posts
- Reorder related posts

---

### 🔍 Search

Search by

- Body text
- Date
- Database ID
- Comments
- Nested replies

Selecting a search result automatically

- opens the corresponding post
- scrolls to the matched comment or reply
- preserves existing navigation history

---

### 🖼 Image Management

Images are stored separately from the database.

```
Application Support/
    pictures/
        original/
        display/
        thumbnail/
```

Features

- Automatic thumbnail generation
- Original image viewer
- Image deletion
- Open original file

---

### 🔗 Related Posts

Posts can be linked manually.

Useful for

- continuation articles
- related topics
- revisions
- reference posts

Links can be

- added
- removed
- reordered

---

### 💬 Threaded Comments

Supports unlimited nested comments.

```
Post

    Comment

        Reply

            Reply

                ...
```

Each level is automatically

- indented
- scaled
- recursively displayed

---

### 📦 Diary Package

The entire diary can be exported as a portable package.

Contents include

- diary data
- images
- related-post links
- comment hierarchy

The package can later be imported into another myDiary database.

---

## Architecture

```
SwiftUI
      │
      ▼
TimelineViewModel
      │
      ▼
PostRepository
      │
      ▼
GRDB / SQLite
```

Images are managed independently from SQLite.

---

## Project Structure

```
myDiary/

    Database/
    Export/
    Import/
    Models/
    Services/
    ViewModels/

    Views/
        Root/
        Timeline/
        Editor/
        Images/
        Search/
```

---

## Technologies

- SwiftUI
- GRDB
- SQLite
- UniformTypeIdentifiers

---

## Roadmap

### Version 1.0

- [x] Timeline
- [x] Threaded comments
- [x] Related posts
- [x] Search
- [x] Image management
- [x] Diary Package Import
- [x] Diary Package Export
- [ ] TeX export
- [ ] PDF export
- [ ] Search history
- [ ] Search result navigation
- [ ] App Icon
- [ ] About screen
- [ ] App Store release

---

## Philosophy

myDiary is **not** intended to be another social networking application.

Its goal is to provide a long-term personal archive that is

- local-first
- searchable
- portable
- independent of any online service

The Diary Package format allows users to preserve their diary independently of Facebook or any other platform.

---

## License

MIT License
