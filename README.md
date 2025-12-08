# Colist

**Real-time collaborative lists for everyone.**

A minimalist, ephemeral todo list app where multiple people can collaborate simultaneously. Create a list, share the link, and work together in real-time.

[**Try it live →**](https://colist.live)

## Features

- **Real-time collaboration** — Changes sync instantly across all connected users
- **Presence awareness** — See who's currently viewing and editing the list
- **Drag-and-drop reordering** — Organize items with intuitive drag-and-drop
- **Ephemeral by design** — Lists auto-expire after 7 days (no clutter, no maintenance)
- **Multilingual** — English and Brazilian Portuguese with automatic locale detection
- **Rate-limited** — Protected against abuse while remaining generous for normal use
- **No sign-up required** — Just create and share

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Elixir, Phoenix 1.8, Phoenix LiveView 1.1 |
| Database | PostgreSQL with Ecto |
| Real-time | Phoenix PubSub + Presence |
| Frontend | Tailwind CSS 4, DaisyUI, SortableJS |
| Deployment | Docker, Fly.io |

## Getting Started

### Prerequisites

- Elixir 1.15+
- PostgreSQL
- Node.js or Bun (for asset building)

### Setup

```bash
# Install dependencies and set up the database
mix setup

# Start the server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000) to see it running.

### Running Tests

```bash
mix test
```

## Architecture Highlights

**LiveView-powered UI** — The entire frontend is server-rendered with Phoenix LiveView, eliminating the need for a separate JavaScript framework while maintaining full interactivity.

**Presence Tracking** — Uses Phoenix Presence to track connected users and broadcast join/leave events, built on top of CRDTs for conflict-free distributed state.

**Background Workers** — A GenServer-based worker automatically cleans up expired lists, demonstrating OTP patterns for background job processing.

**Smart Locale Detection** — Detects user language from URL path first, then falls back to parsing Accept-Language headers with quality factor support.

## License

MIT

---

Built with Phoenix LiveView
