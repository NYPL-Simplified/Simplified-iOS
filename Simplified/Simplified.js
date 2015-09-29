function Simplified() {
  
  // Handling gestures in here with custom touch UI code is just... seriously? Why would that be a good idea?
  
  document.documentElement.style.webkitTouchCallout = "none";
  document.documentElement.style.webkitUserSelect = "none";
  
  // This should be called by the host whenever the page changes. This is because a change in the
  // page can mean a change in the iframe and thus requires resetting properties.
  this.pageDidChange = function() {
    // Disable selection.
    window.frames["epubContentIframe"].document.documentElement.style.webkitTouchCallout = "none";
    window.frames["epubContentIframe"].document.documentElement.style.webkitUserSelect = "none";
    // Handles gestures for the inner content.
    window.frames["epubContentIframe"].removeEventListener("touchstart", handleTouchStart);
    window.frames["epubContentIframe"].addEventListener("touchstart", handleTouchStart, false);
    window.frames["epubContentIframe"].removeEventListener("touchend", handleTouchEnd);
    window.frames["epubContentIframe"].addEventListener("touchend", handleTouchEnd, false);
  };
  
}

simplified = new Simplified();