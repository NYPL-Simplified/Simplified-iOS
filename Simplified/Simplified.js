function Simplified() {
  
  var handleTouchEnd = function(event) {
    var touch = event.changedTouches[0];
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
  document.addEventListener("touchend", handleTouchEnd, false);
  
  // Handles inner content. Should be called each time the page changes as the iframe may have
  // changed.
  this.pageDidChange = function() {
    window.frames["epubContentIframe"].removeEventListener("touchend", handleTouchEnd);
    window.frames["epubContentIframe"].addEventListener("touchend", handleTouchEnd, false);
  };
  
}

simplified = new Simplified();