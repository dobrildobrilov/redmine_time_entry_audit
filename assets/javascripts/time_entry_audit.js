(function(){
  document.addEventListener('DOMContentLoaded', function () {
    var sel = document.querySelector('select[multiple]#tea_admins');
    if (!sel) return;

    // Hide the native select
    sel.style.position = 'absolute';
    sel.style.left = '-9999px';
    sel.style.display = 'none';

    // Build custom multiselect
    var box = document.createElement('div');
    box.className = 'tea-ms';
    box.tabIndex = 0;
    sel.parentNode.insertBefore(box, sel.nextSibling);

    function addOpt(opt) {
      var div = document.createElement('div');
      div.className = 'opt' + (opt.selected ? ' selected initial' : '');
      div.textContent = opt.textContent;
      div.dataset.value = opt.value;

      div.addEventListener('click', function () {
        var nowSelected = !opt.selected;
        opt.selected = nowSelected;
        div.classList.toggle('selected', nowSelected);

        if (nowSelected) {
          div.classList.remove('deselected-initial');
          if (!div.classList.contains('initial')) {
            div.classList.add('newly');
          }
        } else {
          div.classList.remove('newly');
          if (div.classList.contains('initial')) {
            div.classList.add('deselected-initial');
          } else {
            div.classList.remove('deselected-initial');
          }
        }

        sel.dispatchEvent(new Event('change', { bubbles: true }));
      });

      box.appendChild(div);
    }

    Array.from(sel.options).forEach(addOpt);

    var row = box.querySelector('.opt');
    if (row && sel.size) {
      var rowH = row.getBoundingClientRect().height;
      box.style.height = (rowH * sel.size + 4) + 'px';
    }

    var out = document.getElementById('tea_admins_selected');
    if (out) {
      var saved = Array.from(sel.options)
        .filter(function (o) { return o.defaultSelected; })
        .map(function (o) { return o.textContent.trim(); });

      out.innerHTML = '';

      var label = document.createElement('span');
      label.style.fontWeight = '600';
      label.style.marginRight = '6px';
      label.textContent = 'Allowed:';
      out.appendChild(label);

      if (saved.length === 0) {
        var none = document.createElement('span');
        none.style.color = '#777';
        none.textContent = '(none)';
        out.appendChild(none);
      } else {
        saved.forEach(function (name, i) {
          var tag = document.createElement('span');
          tag.className = 'username';
          tag.textContent = name;
          out.appendChild(tag);
          if (i < saved.length - 1) {
            out.appendChild(document.createTextNode(' '));
          }
        });
      }
    }
  });
})();