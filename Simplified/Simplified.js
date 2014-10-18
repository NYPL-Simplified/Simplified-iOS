(function() {
  
  function handleTouchEnd(event) {
    var touch = event.changedTouches[0];
    var position = touch.clientX / document.documentElement.clientWidth;
    if(position <= 0.15) {
      window.location = "simplified:tap-back"
    } else if(position >= 0.85) {
      window.location = "simplified:tap-forward"
    }
    event.stopPropagation();
    event.preventDefault();
  }

  // handles border between inner content and edge of screen
  document.addEventListener("touchend", handleTouchEnd, false);
  
  // handles inner content
  window.frames["epubContentIframe"].document.addEventListener("touchend", handleTouchEnd, false);

})();