# ro14nd.de

Personal blog of Roland Huß, built with [Hugo](https://gohugo.io/) and the [Blowfish](https://blowfish.page/) theme.

## Development

```bash
# Start dev server (includes drafts)
make dev

# Production build
make build

# Clean build output
make clean
```

The dev server runs at http://localhost:1313/ with live reload.

## Structure

```
content/posts/     Blog posts (Markdown)
brainstorm/        Blog post ideas and pipeline
.style/            Voice profiles and style config
static/images/     Static assets
config/_default/   Hugo configuration
```

## Writing

This blog uses the [cc-blog](https://github.com/rhuss/cc-blog) Claude Code plugin for managing the full content lifecycle:

```bash
/blog:brainstorm   # Create a new blog post idea
/blog:write        # Draft a post from a brainstorm doc
/blog:edit         # Run post-production editing
/blog:status       # View the content pipeline
/blog:publish      # Publish a post
/blog:announce     # Create social media teasers
```

## License

Blog content is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Code examples are under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
