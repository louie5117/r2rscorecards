# Project Documentation

This directory is the single source of truth for project documentation.

## Structure

- `setup/`: local setup, environment, and integration quick starts
- `architecture/`: system architecture and technical implementation details
- `features/`: stable feature behavior and product-facing capabilities
- `testing/`: unit test planning and test coverage backlog
- `runbooks/`: troubleshooting and operational guidance
- `roadmap/`: forward-looking checklists and planned work
- `changelog/`: dated changes and migration notes
- `archive/ai-sessions/`: historical AI-generated planning and status files

## Canonical Entry Points

- Setup: `setup/backend-setup.md`
- Architecture: `architecture/developer-guide.md`
- API contract (Swagger/OpenAPI): `architecture/api-openapi.yaml`
- Unit test TODO backlog: `testing/unit-test-todo.md`
- Troubleshooting: `runbooks/troubleshooting.md`
- Boxing API behavior: `features/boxing-api.md`
- UI behavior: `features/ui.md`
- Password reset behavior: `features/password-reset.md`

## Ownership

- Product/feature docs: app maintainers
- Backend docs: backend maintainers
- Runbooks/changelog: release owner for each change

Update canonical docs first. Archive transient implementation logs instead of adding new root-level status files.
