function Simplified() {

  // Valid states for the `tracking` property.
  var TRACKING_IS_WAITING_FOR_TOUCH = 0;
  var TRACKING_IS_ACTIVE = 1;
  var TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH = 2;

  // Stores whether or not we're still considering the current set of touches
  // as a potential tap.
  var tracking = TRACKING_IS_WAITING_FOR_TOUCH;

  // The starting location of a tap.
  var startX = 0;
  var startY = 0;

  // Called whenever the user puts a finger down anywhere within the webview.
  var handleTouchStart = function(event) {

    // We only want to detect taps made with a single finger. As such, if
    // we ever have more than one touch active at a time, we make a note so
    // that `handleTouchEnd` will not do anything later on.
    if (event.touches.length > 1) {
      tracking = TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH;
      return;
    }

    if (tracking === TRACKING_IS_ACTIVE) {
      tracking = TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH;
      return;
    }

    if (tracking === TRACKING_HAS_BEEN_CANCELLED_DUE_TO_MULTITOUCH) {
      return;
    }

    tracking = TRACKING_IS_ACTIVE;

    var touch = event.changedTouches[0];

    if(touch.target.nodeName.toUpperCase() === "A") {
      return;
    }

    startX = touch.screenX;
    startY = touch.screenY;
  };

  // Called almost whenever the user lifts a finger that was previously placed
  // within the webview. We say "almost" because the shuffling of views that the
  // native layer does not handle the swipe transitions sometimes results in
  // `ontuochend` events not being generated at the appropriate times.
  var handleTouchEnd = function(event) {

    // If the user just lifted up more than one finger...
    if (event.changedTouches.length > 1) {
      // ... we do not want to interpret it as the end of a tap because all taps
      // should involve only a single finger.
      return;
    }

    // If the user still has any fingers on the screen...
    if (event.touches.length !== 0) {
      // FIXME: Normally we would want to bail out here, but we do not reliably get
      // `ontouchend` events at the moment because of how swiping is handled in the
      // native layer of the application.
      //
      // return
    }

    // If tracking was previosuly aborted due to entering a multitouch state...
    if (tracking !== TRACKING_IS_ACTIVE) {
      // FIXME: We cannot bail out here as we'd like to for the same reason
      // mentioned above.
      ///
      // tracking = TRACKING_IS_WAITING_FOR_TOUCH;
      // return
    }

    tracking = TRACKING_IS_WAITING_FOR_TOUCH;

    var touch = event.changedTouches[0];

    // If the user tapped on a link...
    if(touch.target.nodeName.toUpperCase() === "A") {
      // ... let the webview apply its default behavior.
      return;
    }

    var maxScreenX = window.orientation === 0 || window.orientation == 180
      ? screen.width
      : screen.height;

    var relativeDistanceX = (touch.screenX - startX) / maxScreenX;

    // If a touch began and ended in roughly the same place...
    if(Math.abs(relativeDistanceX) < 0.1) {
      // ... we consider it a tap (as opposed to a swipe) and handle it as such.
      var position = touch.screenX / maxScreenX;
      if(position <= 0.25) {
        window.location = "simplified:gesture-left";
      } else if(position >= 0.75) {
        window.location = "simplified:gesture-right";
      } else {
        window.location = "simplified:gesture-center";
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

  // This should be called by the host whenever the page changes. This is because a change in the
  // page can mean a change in the iframe and thus requires resetting properties.
  this.pageDidChange = function() {

    var iframe = window.frames["epubContentIframe"];
    if (!iframe) {
      return;
    }

    // Remove existing handlers, if any.
    try {
      iframe.removeEventListener("touchstart", handleTouchStart);
      iframe.removeEventListener("touchend", handleTouchEnd);
    } catch (e) {
      // Do nothing.
    }

    // Handles gestures for the inner content.
    iframe.addEventListener("touchstart", handleTouchStart, false);
    iframe.addEventListener("touchend", handleTouchEnd, false);

    // Set up the page turning animation.
    iframe.document.documentElement.style["transition"] = "left 0.2s";
  };

  this.pageDidChange();
}

simplified = new Simplified();
