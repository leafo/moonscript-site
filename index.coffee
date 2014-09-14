
if navigator.appVersion.indexOf("Win") == -1
  document.body.classList.add "nice_fonts"

setTimeout =>
  document.querySelectorAll(".main")[0].classList.remove("obscured")
, 10

$ = (id) -> document.getElementById id

matches = (el, selector) ->
  (el.matches || el.matchesSelector || el.msMatchesSelector || el.mozMatchesSelector || el.webkitMatchesSelector || el.oMatchesSelector).call(el, selector)

debounce = (fn, wait) ->
  timeout = null
  ->
    if timeout
      clearTimeout timeout

    timeout = setTimeout ->
      timeout = null
      fn()
    , wait

window.addEventListener "scroll", debounce (e) ->
  h2 = window.innerHeight / 3
  anchors = document.body.querySelectorAll "div[id]:empty"

  current = anchors[0]
  current_i = 0
  for a, i in anchors by -1
    rect = a.getBoundingClientRect()
    if rect.top < h2
      current = a
      current_i = i
      break

  while before = anchors[current_i - 1]
    if before.getBoundingClientRect().top >= 0
      current = before
      current_i -= 1
    else
    break

  document.body.querySelectorAll(".primary_nav .active")[0]
    .classList.remove "active"

  document.body
    .querySelectorAll(".primary_nav [data-name='#{current.id}']")[0]?.classList
    .add "active"

, 50

return

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

nodes = document.querySelectorAll ".see_lua"
for node in nodes
  node.onclick = ->
    code_id = this.getAttribute("code_id")

    $("left").innerHTML = $("moon-#{code_id}").innerHTML
    $("right").innerHTML = $("lua-#{code_id}").innerHTML

    show_modal()

