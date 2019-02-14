function Simplified() {

  // Valid states for the `tracking` property.
  var TRACKING_IS_WAITING_FOR_TOUCH = 0;
  var TRACKING_IS_ACTIVE = 1;
  var TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH = 2;

  // Stores whether or not we're still considering the current set of touches as
  // a potential tap.
  var tracking = TRACKING_IS_WAITING_FOR_TOUCH;

  // The starting location of a tap.
  var startX = 0;
  var startY = 0;

  // The time the last tap was started.
  var startTime = 0;

  // Called whenever the user puts a finger down anywhere within the webview.
  var handleTouchStart = function(event) {

    // We only want to detect taps made with a single finger. As such, if we
    // ever have more than one touch active at a time, we make a note so that
    // `handleTouchEnd` will not do anything later on.
    if (event.touches.length > 1) {
      tracking = TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH;
    }

    // The user had more than one finger down during the current gesture so we
    // do nothing.
    if (tracking === TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH) {
      return;
    }

    // We're beginning to track a single-finger tap.
    tracking = TRACKING_IS_ACTIVE;

    var touch = event.changedTouches[0];

    startX = touch.screenX;
    startY = touch.screenY;
    startTime = Date.now();
  };

  // Called almost whenever the user lifts a finger that was previously placed
  // within the webview.
  var handleTouchEnd = function(event) {

    // If tracking was aborted due to entering a multitouch state...
    if (tracking !== TRACKING_IS_ACTIVE) {
      // ... then if no fingers are on the screen...
      if(event.touches.length === 0) {
        // ... reset the tracking state.
        tracking = TRACKING_IS_WAITING_FOR_TOUCH;
      }

      // Stop here because of having been in a multitouch state.
      return;
    }

    // This is the end of a single-finger gesture so reset tracking.
    tracking = TRACKING_IS_WAITING_FOR_TOUCH;

    var touch = event.changedTouches[0];

    var maxScreenX = window.orientation === 0 || window.orientation == 180
      ? screen.width
      : screen.height;

    var relativeDistanceX = (touch.screenX - startX) / maxScreenX;

    // If a touch began and ended in roughly the same place...
    if(Math.abs(relativeDistanceX) < 0.1) {
      // ... we consider it a tap (as opposed to a swipe) and handle it as such.

      // If the user tapped on a link...
      if(touch.target.nodeName.toUpperCase() === "A") {
        // ... let the webview apply its default behavior.
        return;
      }

      // Prevent interference with holding for text selection.
      if (Date.now() - startTime < 500) {
        var position = touch.screenX / maxScreenX;
        if(position <= 0.25) {
          window.location = "simplified:gesture-left";
        } else if(position >= 0.75) {
          window.location = "simplified:gesture-right";
        } else {
          window.location = "simplified:gesture-center";
        }
      }

      // Since we handled the event, we stop the webview from applying its
      // default behavior.
      event.stopPropagation();
      event.preventDefault();

      return;
    } else {
      var slope = (touch.screenY - startY) / (touch.screenX - startX);
      // If the user swiped horizontally...
      if(Math.abs(slope) <= 0.5) {
        // ... we consider it a swipe-to-turn gesture.
        if(relativeDistanceX > 0) {
          window.location = "simplified:gesture-left";
        } else {
          window.location = "simplified:gesture-right";
        }

        // Since we handled the event, we stop the webview from applying its
        // default behavior.
        event.stopPropagation();
        event.preventDefault();

        return;
      }
    }
  };

  // Handle gestures between the inner content and the edge of the screen.
  document.addEventListener("touchstart", handleTouchStart, false);
  document.addEventListener("touchend", handleTouchEnd, false);

  // Disable selection outside the iframe. This is probably not necessary as we
  // do not disable it inside the iframe (because doing so breaks Readium's CFI
  // logic), but it's safe to do and may avoid persistent selection strangeness
  // across resource boundaries.
  document.documentElement.style.webkitTouchCallout = "none";
  document.documentElement.style.webkitUserSelect = "none";

  // This should be called by the host whenever the page changes. This is
  // because a change in the page can mean a change in the iframe and thus
  // requires resetting properties.
  this.pageDidChange = function() {

    var iframe = window.frames["epubContentIframe"];
    if (!iframe) {
      // This method was called too early, so do nothing.
      return;
    }

    var innerDocument = iframe.document;
    if (!innerDocument) {
      // iOS >= 12
      innerDocument = iframe.contentDocument;
    }

    // Remove existing handlers, if any.
    innerDocument.removeEventListener("touchstart", handleTouchStart);
    innerDocument.removeEventListener("touchend", handleTouchEnd);

    // Handle gestures for the inner content.
    innerDocument.addEventListener("touchstart", handleTouchStart, false);
    innerDocument.addEventListener("touchend", handleTouchEnd, false);

    // Set up the page turning animation.
    innerDocument.documentElement.style["transition"] = "left 0.2s";

    // Allow OpenDyslexic fonts to work.
    this.linkOpenDyslexicFonts();
  };

  // Allows the inner iframe to fetch OpenDyslexic fonts from the web server.
  this.linkOpenDyslexicFonts = function() {
    var id = 'simplified-opendyslexic';
    var innerDocument = window.frames['epubContentIframe'].document;
    if (!innerDocument) {
      // iOS >= 12
      innerDocument = window.frames['epubContentIframe'].contentDocument;
    }
    if (innerDocument.getElementById(id)) {
      return;
    }
    var styleElement = document.createElement('style');
    styleElement.id = id;
    styleElement.textContent =
      "@font-face { \
        font-family: 'OpenDyslexic3'; \
        src: url('/simplified-readium/OpenDyslexic3-Medium.ttf'); \
        font-weight: normal; \
      } \
      \
      @font-face { \
        font-family: 'OpenDyslexic3'; \
        src: url('/simplified-readium/OpenDyslexic3-Bold.ttf'); \
        font-weight: bold; \
      }";
    innerDocument.head.appendChild(styleElement);
  }
  
  /**
   * FIXME: The following two functions are only here to provide slightly better
   * support for returning to a particular spot in the book. This is due to the
   * inconsistencies and the unreliability of Readium's CFI returning us to the same
   * spot after certain UI actions take place. Previously, changing the font size (for
   * example) constantly returned the user to the first page of the current chapter.
   * This update is not perfect but stays within 2 to 3 pages of the current
   * bookmark CFI captured before the UI update.
   */
   
  /**
   * saveLocationBeforeSettingsUpdate
   * Before there's a font size or font family change in the UI, keep track of the CFI of
   * the current view bookmark's CFI.
   */
  this.saveLocationBeforeSettingsUpdate = function() {
    var currentView = ReadiumSDK.reader.getCurrentView();
    var bookMark = currentView.bookmarkCurrentPage();
    
    this.currentViewCFI = bookMark;
  }

  /**
   * applyLocationAferSettingsUpdate
   * If there's an existing CFI that we are tracking, open the reader to that CFI.
   * TODO: the CFI works well for the previous font size or font family. When switching to
   * a new font size or font family, the CFI is no longer exactly the same as before. 
   */
  this.applyLocationAferSettingsUpdate = function() {
    var currentViewCFI = this.currentViewCFI || undefined;

    if (currentViewCFI) {
      setTimeout(function () {
        ReadiumSDK.reader.openSpineItemElementCfi(currentViewCFI.idref, currentViewCFI.contentCFI);
      }, 250);
    }
  }

  this.pageDidChange();
}

simplified = new Simplified();
