function Simplified() {
  
  // Handling gestures in here with custom touch UI code is just... seriously? Why would that be a good idea?
  
  document.documentElement.style.webkitTouchCallout = "none";
  document.documentElement.style.webkitUserSelect = "none";
  
  // This should be called by the host whenever the page changes. This is because a change in the
  // page can mean a change in the iframe and thus requires resetting properties.
  this.pageDidChange = function(cfi) {
    // Disable selection.
    window.frames["epubContentIframe"].document.documentElement.style.webkitTouchCallout = "none";
    window.frames["epubContentIframe"].document.documentElement.style.webkitUserSelect = "none";
    
    var iframe = window.frames["epubContentIframe"];
    var childs = iframe.document.documentElement.getElementsByTagName('*');
    
    var firstElt = null;
    for (var i=0; i<childs.length; ++i) {
      var child = childs[i];
      var visible = ReadiumSDK.reader.getElementVisibility(child);
      child.setAttribute("aria-hidden", visible ? "false"   : "true");
      child.setAttribute("tabindex", 0); // Make sure the elements are focusable=
      
      if (firstElt == null && visible && child.tagName == "p")
        firstElt = child;
    }
    
    console.log("Element tag:" + firstElt.tagName);
    console.log(firstElt.innerHTML.slice(0, 20));
    
    // Select the element at the top of the page
    if (firstElt)
      firstElt.focus();
    
//    console.log("Element: " + elt);
//    this.lastElt = elt;
//    var r = elt.getBoundingClientRect();
//    console.log("Child :" + i + " tag:" + elt.tagName + " l:" + r.left + " r:" + r.right + " t:" + r.top + " b:" + r.bottom + " w:" + r.width + " h:" + r.height);
//    console.log(elt.innerHTML.slice(0, 20));
//    
//    for (var i=0; i<childs.length; ++i) {
//      var child = childs[i];
//      var r = childs[i].getBoundingClientRect();
//      console.log("Child :" + i + " tag:" + child.tagName + " l:" + r.left + " r:" + r.right + " t:" + r.top + " b:" + r.bottom + " w:" + r.width + " h:" + r.height);
//      console.log(child.innerHTML.slice(0, 20));  
//    }
  };
}

simplified = new Simplified();