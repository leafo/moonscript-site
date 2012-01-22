
window.onload = ->
  $ = (id) -> document.getElementById id

  shroud = $ "shroud"
  popup = $ "shroud-popup"

  show_modal = ->
    window.onkeydown = (e) ->
      e = e || window.event
      hide_modal() if e.keyCode == 27

    shroud.style.display = "block"

  hide_modal = ->
    window.onkeydown = ->
    shroud.style.display = "none"

  shroud.onclick = hide_modal
  $("shroud-close").onclick = hide_modal

  popup.onclick = (e) -> e.stopPropagation()

  nodes = document.querySelectorAll ".see-lua"
  for node in nodes
    node.onclick = ->
      code_id = this.getAttribute("code_id")

      $("left").innerHTML = $("moon-#{code_id}").innerHTML
      $("right").innerHTML = $("lua-#{code_id}").innerHTML

      show_modal()

