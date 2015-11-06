function Simplified() {
  
  document.documentElement.style.webkitTouchCallout = "none";
  document.documentElement.style.webkitUserSelect = "none";
  
  this.shouldUpdateVisibilityOnUpdate = false;
  
  function updateVisibility() {
    
    var iframe = window.frames["epubContentIframe"];
    var childs = iframe.document.documentElement.getElementsByTagName('*');
    
    var firstElt = null;
    for (var i=0; i<childs.length; ++i) {
      var child = childs[i];
      var visible = ReadiumSDK.reader.getElementVisibility(child);
      child.setAttribute("aria-hidden", visible ? "false"   : "true");
      child.setAttribute("tabindex", visible ? i : -1); // Make sure the elements are focusable
      
      if (visible) {
        console.log("Vibisle element: " + child.tagName + " " + child.innerHTML.slice(0, 20));
        if (firstElt == null && child.tagName == "p")
          firstElt = child;
      }
      
      var isBlock = window.getComputedStyle(child, "").display == "block";
      if (!isBlock) {
        child.setAttribute("role", "presentation");
      }
    }
    
    return firstElt;
  }
  
  this.beginVisibilityUpdates = function() {
    this.shouldUpdateVisibilityOnUpdate = true;
    var firstElt = updateVisibility();
    if (firstElt)
      firstElt.focus();
  }
  
  this.settingsDidChange = function() {
    if (this.shouldUpdateVisibilityOnUpdate) {
      updateVisibility();
    }
  };
  
  // This should be called by the host whenever the page changes. This is because a change in the
  // page can mean a change in the iframe and thus requires resetting properties.
  this.pageDidChange = function(cfi) {
    // Disable selection.
    window.frames["epubContentIframe"].document.documentElement.style.webkitTouchCallout = "none";
    window.frames["epubContentIframe"].document.documentElement.style.webkitUserSelect = "none";
    
    if (this.shouldUpdateVisibilityOnUpdate) {
      updateVisibility();
    }
  };
}

simplified = new Simplified();