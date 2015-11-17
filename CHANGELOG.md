# Simplified-iOS Changelog
This project does not currently adhere to Semantic Versioning. But it should.

## 0.9.0 (17) 17-11-2015
### Changed
- The app no longer checks for the current state of location services when the user starts a new card application. This is because location services is not necessary, and because that check occurs at a later part of the application.
- Single-tap now brings up the reader options, and there is an associated animation
- Turning pages with multiple fast swipes can no longer turn pages faster than Readium (queueing page turns was the source of some very tricky bugs)
- Single taps no longer percolate up from the web view, but rather as passed to the web view if they intersect links (we can go back to the old behavior later)
 
### Fixed
- SIM-25 Double-tapping on the "Sign Up" should no longer start a second library card application
- SIM-32 Single-tap brings up the reader options menu, now.
- SIM-34 It should no longer be possible to turn pages so fast that the reader ends up on a blank page
- SIM-35 No longer possible to turn past the first or last page