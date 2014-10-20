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
    if(Math.abs(touch.screenX - startX) >= 5 ||
       Math.abs(touch.screenY - startY) >= 5) {
      // This is not a simple tap.
      return;
    }
    var position = touch.screenX / screen.width;
    if(position <= 0.2) {
      window.location = "simplified:tap-back";
    } else if(position >= 0.8) {
      window.location = "simplified:tap-forward";
    }
    event.stopPropagation();
    event.preventDefault();
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