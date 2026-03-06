# Contributing

## Repository conventions

### Source code placement

- App source belongs under `r2rscorecards/`.
- Use these folders:
  - `r2rscorecards/Models`
  - `r2rscorecards/Views`
  - `r2rscorecards/Services`
  - `r2rscorecards/Managers`
  - `r2rscorecards/Support`
- Keep file names stable and descriptive.
- Do not add duplicate-style names such as `* 2.swift`.

### Documentation placement

- Keep only high-level entry docs at repository root (`README.md`, `CONTRIBUTING.md`).
- Put active docs under `docs/` taxonomy:
  - `docs/setup`
  - `docs/architecture`
  - `docs/features`
  - `docs/runbooks`
  - `docs/roadmap`
  - `docs/changelog`
- Put transient implementation logs and AI-generated status files under `docs/archive/ai-sessions/`.
- Avoid new root-level files like `*_FINAL_STATUS.md`, `*_DONE.md`, or `CHANGES_APPLIED.md`.

### Xcode project hygiene

- Internal planning markdown should not be added to app bundle resources.
- Keep source references aligned with canonical folders.

## Pull request checklist

- [ ] New Swift files are under `r2rscorecards/` subfolders, not repo root.
- [ ] New docs are under `docs/`, not repo root.
- [ ] No filenames match `* 2.swift`.
- [ ] No new root markdown status/todo files were added.
- [ ] `r2rscorecards.xcodeproj/project.pbxproj` still reflects real source/resource membership.
