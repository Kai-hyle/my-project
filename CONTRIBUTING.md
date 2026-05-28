# Contributing

Thanks for helping improve Better Norch.

## Development

1. Open `NotchShelf.xcodeproj` in Xcode.
2. Build and run the `NotchShelf` scheme.
3. Keep changes focused and native to the current SwiftUI/AppKit structure.
4. Test `Trans` drop, `Copy` drop, drag out, open, quick delete, clear shelf, and menu bar actions before opening a pull request.

## Style

- Prefer small, readable Swift types.
- Keep AppKit bridging isolated to `Views`, `Windows`, or `Services`.
- Keep file operations in `ShelfStorageService` or `ShelfStore`.
- Avoid adding external dependencies unless they clearly simplify core behavior.

## Pull Requests

Please include:

- What changed.
- How it was tested.
- Any known limitations or follow-up work.
