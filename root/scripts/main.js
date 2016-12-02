// from http://stackoverflow.com/questions/10158190/how-to-set-cursor-at-the-end-in-a-textarea-by-not-using-jquery @Starx
function moveCaretToEnd(el) {
    if (typeof el.selectionStart == "number") {
        el.selectionStart = el.selectionEnd = el.value.length;
    } else if (typeof el.createTextRange != "undefined") {
        el.focus();
        var range = el.createTextRange();
        range.collapse(false);
        range.select();
    }
}


var area = container.querySelector('textarea');
if (area.addEventListener) {
  area.addEventListener('input', function() {
      this.value = hljs.highlightAuto(this.value)
    // event handling code for sane browsers
  }, false);
} else if (area.attachEvent) {
  area.attachEvent('onpropertychange', function() {
      this.value = hljs.highlightAuto(this.value)
    // IE-specific event handling code
  });
}

function typeInTextarea(el, newText, add) {
    if ( typeof add === "undefined") {
	add = '"'
    }
    newText = add + newText + add;
    var start = el.selectionStart;
    var end = el.selectionEnd;
    var text = el.value;
    var before = text.substring(0, start);
    var after  = text.substring(end, text.length);
    el.value = (before + newText + after);
    el.selectionStart = el.selectionEnd = start + newText.length;
    el.focus();
}