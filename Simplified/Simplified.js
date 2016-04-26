function Simplified() {
  
  document.documentElement.style.webkitTouchCallout = "none";
  document.documentElement.style.webkitUserSelect = "none";
  
  this.shouldUpdateVisibilityOnUpdate = false;
  
  this.getSemicolonSeparatedLinkRects = function() {
    var offsetRect = document.getElementById('epubContentIframe').getBoundingClientRect();
    var a = window.frames['epubContentIframe'].document.getElementsByTagName('a');
    var retVal = new Array();
    for (var idx= 0; idx < a.length; ++idx) {
      var r = a[idx].getBoundingClientRect();
      r.left += offsetRect.left;
      r.top += offsetRect.top;
      retVal[idx] = '{{'+r.left+','+r.top+'},{'+r.width+','+r.height+'}}';
    }
    return retVal.join(';');
  }
  
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
  
  // Because WKWebKit cannot access application fonts, it is necessary to
  // load them via a @font-face declaration. This declaration must be placed
  // dynamically on the iframe managed by Readium: Adding it to the container
  // HTML would not allow the iframe contents to use the font.
  this.loadOpenDyslexicFonts = function() {
    if(document.getElementById("openDyslexic") == null) {
      var iframe = window.frames["epubContentIframe"];
      var head = iframe.document.head;
      var style = document.createElement("style");
      style.id = "openDyslexic";
      style.appendChild(document.createTextNode(
        "@font-face { \
          font-family: 'OpenDyslexic3'; \
          src: url('/simplified-readium/OpenDyslexic3-Regular.ttf'); \
        } \
        @font-face { \
          font-family: 'OpenDyslexic3'; \
          src: url('/simplified-readium/OpenDyslexic3-Bold.ttf'); \
          font-style: bold; \
        }"));
      head.appendChild(style);
    }
  }
  
  // This should be called by the host whenever the page changes. This is because a change in the
  // page can mean a change in the iframe and thus requires resetting properties.
  this.pageDidChange = function() {
    // Disable selection.
    window.frames["epubContentIframe"].document.documentElement.style.webkitTouchCallout = "none";
    window.frames["epubContentIframe"].document.documentElement.style.webkitUserSelect = "none";
    
    this.loadOpenDyslexicFonts();
    
    if (this.shouldUpdateVisibilityOnUpdate) {
      updateVisibility();
    }
  };
}

simplified = new Simplified();