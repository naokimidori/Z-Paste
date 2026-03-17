---
phase: 01-project-foundation
plan: 02
subsystem: Models
tags: [data-model, grdb, clipboard]
dependency_graph:
  requires: []
  provides:
    - "ClipboardItem data model"
    - "GRDB persistence layer"
  affects:
    - "Future plans will use ClipboardItem for database operations"
tech_stack:
  added:
    - "CryptoKit for SHA256 hashing"
    - "GRDB for SQLite persistence"
  patterns:
    - "Struct for value semantics"
    - "Protocol extensions for database mapping"
key_files:
  created:
    - path: "Z-Paste/Models/ClipboardItem.swift"
      purpose: "Data model definition"
    - path: "Z-Paste/Models/ClipboardItem+Database.swift"
      purpose: "GRDB protocol implementations"
  modified: []
decisions:
  - "Used CryptoKit.SHA256 instead of CommonCrypto for modern Swift API"
  - "Separated database extensions into separate file for clarity"
  - "Implemented contentHash for deduplication logic"
metrics:
  duration_seconds: 300
  files_created: 2
  files_modified: 0
  lines_added: 166
completed_at: "2026-03-17T13:30:00Z"
---

# Phase 01 Plan 02: ClipboardItem Data Model Summary

**One-liner:** Created ClipboardItem data model with ItemType enum (text/image/file/rtf) and GRDB persistence extensions for SQLite storage.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Define ClipboardItem model and ItemType enum | 7e48380 | Z-Paste/Models/ClipboardItem.swift |
| 2 | Implement GRDB protocol extensions | fb9d6db | Z-Paste/Models/ClipboardItem+Database.swift |

## Implementation Details

### ClipboardItem Structure

```swift
struct ClipboardItem: Codable, Identifiable, Equatable, Hashable {
    var id: Int64?
    var content: String
    var itemType: ItemType
    var sourceApp: String?
    var sourceAppIcon: Data?
    var createdAt: Date
    var isFavorite: Bool
    var data: Data?
}
```

### ItemType Enum

- `text` - 纯文本
- `image` - 图片
- `file` - 文件
- `rtf` - 富文本

### GRDB Protocol Implementation

- `TableRecord` - 表名映射和列定义
- `FetchableRecord` - 从数据库行解码
- `PersistableRecord` - 编码并保存到数据库

### Database Schema

```sql
CREATE TABLE clipboard_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    item_type TEXT NOT NULL,
    source_app TEXT,
    source_app_icon BLOB,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    data BLOB
);

CREATE INDEX idx_clipboard_items_created_at ON clipboard_items(created_at);
CREATE INDEX idx_clipboard_items_is_favorite ON clipboard_items(is_favorite);
CREATE INDEX idx_clipboard_items_item_type ON clipboard_items(item_type);
```

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

### Decisions Made

1. **CryptoKit over CommonCrypto**: Used modern Swift CryptoKit framework for SHA256 hashing instead of legacy CommonCrypto C API.

2. **Separate extension file**: Kept database-related code in `ClipboardItem+Database.swift` for separation of concerns.

3. **contentHash implementation**: Added SHA256-based content hashing for deduplication logic as specified in requirements FR-1.4.

## Verification Results

- [x] ClipboardItem.swift compiles without errors
- [x] ItemType enum covers all required types (text, image, file, rtf)
- [x] GRDB FetchableRecord implemented
- [x] GRDB PersistableRecord implemented
- [x] Table schema includes all fields
- [x] Indexes created for performance (created_at, is_favorite, item_type)

## Next Steps

Plan 03 will build on this foundation to implement the DatabaseService for CRUD operations.

## Self-Check: PASSED

- [x] Files created: ClipboardItem.swift, ClipboardItem+Database.swift
- [x] Commits exist: 7e48380, fb9d6db
- [x] SUMMARY.md created in correct location
- [x] All verification criteria met
