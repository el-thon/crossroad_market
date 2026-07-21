# Migration scope

This migration removes the Store navigation graph stack after all active references are replaced:

- `scripts/navigation/store/`
- Store path graph implementations and helpers
- layered/revision-aware NPC route controller subclasses
- reachable-shelf metadata shopping wrapper
- Store route sanitizer
- budgeted shelf metadata placement wrapper

The player shelf placement surface remains because it is a placement system, not NPC navigation.
