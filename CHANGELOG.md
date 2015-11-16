# Simplified-iOS Changelog
This project does not currently adhere to Semantic Versioning. But it should.

## [Unrealeased]
### Changed
- The app no longer checks for the current state of location services when the user starts a new card application. This is because location services is not necessary, and because that check occurs at a later part of the application.
- Single-tap now brings up the reader options, and there is an associated animation
 
### Fixed
- SIM-25 Double-tapping on the "Sign Up" should no longer start a second library card application
- SIM-32 Single-tap brings up the reader options menu, now.