function Simplified() {
  
  var startX = 0;
  var startY = 0;
  
  var handleTouchStart = function(event) {
    var touch = event.changedTouches[0];
    startX = touch.screenX;
    startY = touch.screenY;
  };
  
  var handleTouchEnd = function(event) {
    var touch = event.changedTouches[0];
    
    // Tap to turn.
    if(Math.abs(touch.screenX - startX) <= 5 &&
       Math.abs(touch.screenY - startY) <= 5) {
      var position = touch.screenX / screen.width;
      if(position <= 0.2) {
        window.location = "simplified:tap-back";
      } else if(position >= 0.8) {
        window.location = "simplified:tap-forward";
      }
      event.stopPropagation();
      event.preventDefault();
      return;
    }
    
    var relativeDistanceX = (touch.screenX - startX) / screen.width;
    var slope = (touch.screenY - startY) / (touch.screenX - startX);
    
    // Swipe to turn.
    if(Math.abs(slope) <= 0.5 && Math.abs(relativeDistanceX) >= 0.1) {
      if(relativeDistanceX > 0) {
        window.location = "simplified:tap-back";
      } else {
        window.location = "simplified:tap-forward";
      }
      event.stopPropagation();
      event.preventDefault();
      return;
    }
  };
  
  // Handles border between inner content and edge of screen.
  document.addEventListener("touchstart", handleTouchStart, false);
  document.addEventListener("touchend", handleTouchEnd, false);
  
  // Handles inner content. Should be called each time the page changes as the iframe may have
  // changed.
  this.pageDidChange = function() {
    window.frames["epubContentIframe"].removeEventListener("touchstart", handleTouchStart);
    window.frames["epubContentIframe"].addEventListener("touchstart", handleTouchStart, false);
    window.frames["epubContentIframe"].removeEventListener("touchend", handleTouchEnd);
    window.frames["epubContentIframe"].addEventListener("touchend", handleTouchEnd, false);
  };
  
}

simplified = new Simplified();