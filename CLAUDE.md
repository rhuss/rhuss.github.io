# Blog Project Notes

## Hugo Tag Display Names

Tags in Blowfish render from the slug by default (dashes preserved, each segment title-cased). To control the display name, create `content/tags/<slug>/_index.md` with a `title:` field.

Example: Tag `multi-agent` renders as "Multi-Agent" by default. With `content/tags/multi-agent/_index.md` containing `title: "Multi Agent"`, it renders as "Multi Agent".

Existing tag overrides:
- `content/tags/ai/_index.md` -> "AI"
- `content/tags/claude-code/_index.md` -> "Claude Code"
- `content/tags/context-engineering/_index.md` -> "Context Engineering"
- `content/tags/multi-agent/_index.md` -> "Multi Agent"
- `content/tags/the-flock/_index.md` -> "The Flock"

When adding a new tag with dashes or unconventional casing, always create the `_index.md` file.
