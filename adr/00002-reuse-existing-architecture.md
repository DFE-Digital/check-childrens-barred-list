# 2. Reuse existing architecture

Date: 2023-06-13

## Status

Accepted

## Context

Check the Children's Barred List is a monolithic Rails application and should
use a similar architecture to other monoliths, like
[Find a lost TRN](https://github.com/DFE-Digital/find-a-lost-trn).

## Decision

We adopt the following ADRs wholesale from Find a Lost TRN, and agree to follow
their decisions:

- [3. Use a Ruby on Rails monolith](https://github.com/DFE-Digital/find-a-lost-trn/blob/main/adr/00003-use-rails.md)
- [4. Use Postgres](https://github.com/DFE-Digital/find-a-lost-trn/blob/main/adr/00004-use-postgres-state.md)
- [5. Use automated tooling to check for security vulnerabilities](https://github.com/DFE-Digital/find-a-lost-trn/blob/main/adr/00005-use-gemsurance-and-.md)

## Consequences

- We don't have to justify the same decisions
- We can still make adjustments by creating new ADRs down the line
- Knowledge transfer between teams is simpler
- Sharing code and modules is simpler
