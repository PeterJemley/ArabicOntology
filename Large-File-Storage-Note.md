# Large File Storage Note

## Context
- The prebuilt SwiftData store file is about 99.8 MB.
- GitHub recommends keeping individual files under 50 MB, and blocks pushes above 100 MB.
- This is a binary file, so changes add to repo size quickly over time.

## Options
1. Keep the store in git
   - Simple, no extra tooling.
   - Repo size grows and a larger store could be rejected in future pushes.

2. Move the store to Git LFS
   - Keeps the git history lightweight and avoids the 100 MB limit.
   - Requires Git LFS installed for contributors.
   - Uses GitHub LFS storage and bandwidth quotas.

## Recommendation
Defer a decision until we review other possible data formats (for example, a
prebuilt SwiftData store vs a SQLite/GRDB database). Once the long-term format
is chosen, we can decide whether LFS is the best fit for distribution.
