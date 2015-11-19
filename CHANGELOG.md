# Simplified-iOS Changelog
This project does not currently adhere to Semantic Versioning. But it should.

## [Uncommitted]
### Changed
- Borrow requests now use the HTTP method PUT instead of GET
- NYPLBookAcquisition now stores a dictionary of fulfillment links (generic and open access) instead of just a single URL, to allow for multiple formats
- NYPLConfiguration adds a method that other classes may call to determine which file formats Simplified is capable of reading

### Fixed
- SIM-37 Borrow requests should be working correctly now
- SIM-37 Acquisitions that can only be fulfilled as PDF should be ignored
- SIM-37 Client shooudl always follow the fulfillment link to an epub, rather than some other format that the client cannot recognize

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