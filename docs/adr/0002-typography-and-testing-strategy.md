# ADR-0002: Mobile Typography & TDD Strategy

## Status
Accepted

## Context
We are implementing a complex UI for a reader app. Readability is paramount. We also need to ensure the core parsing and data extraction logic is rock solid to prevent data loss or crashes during heavy IO operations. 

## Decision
1. **Typography**: We will follow strict mobile design rules. Base 16px body, minimum AA contrast (aiming for AAA in reading view), with user-controlled font scaling applied exclusively to the reading view (not the global app shell).
2. **Testing (TDD)**: We will use Test-Driven Development (TDD) strictly for the core logic layer (parsers, isolate extraction, database queries, and state management providers). We will only write UI widget tests for critical paths (e.g., the library import button).

## Rationale
- **Typography**: Adhering to the 16px minimum and high contrast prevents eye strain during long reading sessions. Restricting user scaling to the reader view prevents the Library Grid UI from breaking uncontrollably.
- **Testing**: UI tests in Flutter can be brittle and slow down rapid prototyping of the reader view. By focusing TDD on the data and domain logic, we ensure the app won't crash on corrupted files or memory leaks, while maintaining UI agility.

## Consequences
- The design system must be carefully split between "App Shell Typography" and "Reader Typography".
- Developers must write failing unit tests for all `data/` and `application/` layer code before implementation.
