
if navigator.appVersion.indexOf("Win") == -1
  document.body.classList.add "nice_fonts"

if navigator.appVersion.indexOf("Chrome") >= 0
  document.body.classList.add "enable_rainbow"

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
  anchors = document.querySelectorAll "div[id]:empty"

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

  document.querySelector(".primary_nav .active")
    .classList.remove "active"

  document.body
    .querySelector(".primary_nav [data-name='#{current.id}']")?.classList
    .add "active"

, 50


closest = (el, selector) ->
  while true
    return el if matches el, selector
    el = el.parentNode
    return null if el == document

remove_lightbox = (e) ->
  document.body.classList.remove "show_lightbox"
  document.body.classList.remove "animate_lightbox"
  e?.preventDefault()


document.body.addEventListener "click", (e) ->
  if matches(e.target, ".shroud") || matches(e.target, ".lightbox .close_btn")
    remove_lightbox e
    return

  lua_btn = closest e.target, ".see_lua_btn"
  return unless lua_btn
  container = closest(lua_btn, "[data-compiled_lua]")

  lua_code = container.dataset.compiled_lua
  document.querySelector(".lightbox .lua_col").innerHTML = lua_code

  document.body.classList.add "show_lightbox"
  document.querySelector(".shroud").scrollTop = 0
  setTimeout ->
    document.body.classList.add "animate_lightbox"
  , 1

  e.preventDefault()


window.addEventListener "keydown", (e) ->
  if e.keyCode == 27
    remove_lightbox e

