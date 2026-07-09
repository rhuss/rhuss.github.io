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

## AAIF Ambassador Program

Roland is a 2026 [Agentic AI Foundation](https://aaif.io/) Ambassador (started 2026-06-23). Blog posts that tie to AAIF projects (MCP, AGENTS.md, Goose, agentgateway) can be submitted to `https://github.com/aaif/ambassadors` using the Ambassador Contribution Submission issue template.

**Eligibility criteria:**
- Must tie directly to an AAIF project
- Must help developers understand, try, use, or contribute to that project
- Must be published after the ambassador start date (2026-06-23)
- Artifact date in the submission is checked against `started_on`

**When writing or editing posts:** Look for natural connections to AAIF projects. If the post covers MCP auth, AGENTS.md usage, or agent infrastructure patterns, note it as a potential AAIF submission. Don't force the connection, but don't miss it either.

**Existing submissions:**
- [#40](https://github.com/aaif/ambassadors/issues/40) - What Goes in AGENTS.md (AGENTS.md)
