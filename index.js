const sections = [...document.querySelectorAll(".primary_nav a[data-name]")]
  .map(link => ({ link, heading: document.getElementById(link.dataset.name) }))
  .filter(s => s.heading)

const updateActive = () => {
  const line = innerHeight / 3
  const passed = sections.filter(s => s.heading.getBoundingClientRect().top < line)
  // a short section's heading can pass the line while the previous heading is
  // still on screen, so prefer the earliest passed heading that's still visible
  const current = passed.find(s => s.heading.getBoundingClientRect().top >= 0)
    ?? passed.at(-1)
    ?? sections[0]

  for (const s of sections) {
    s.link.classList.toggle("active", s === current)
  }
}

let queued = false
window.addEventListener("scroll", () => {
  if (queued) return
  queued = true
  requestAnimationFrame(() => {
    queued = false
    updateActive()
  })
}, { passive: true })

updateActive()

const shroud = document.querySelector(".shroud")
const luaColumn = document.querySelector(".lightbox .lua_col")

const showLightbox = html => {
  luaColumn.innerHTML = html
  document.body.classList.add("show_lightbox")
  shroud.scrollTop = 0
  // flush the display change so the animate class transitions from the hidden state
  shroud.offsetWidth
  document.body.classList.add("animate_lightbox")
}

const hideLightbox = () => {
  document.body.classList.remove("show_lightbox", "animate_lightbox")
}

document.body.addEventListener("click", e => {
  if (e.target === shroud || e.target.closest(".lightbox .close_btn")) {
    e.preventDefault()
    hideLightbox()
    return
  }

  const button = e.target.closest(".see_lua_btn")
  if (!button) return

  e.preventDefault()
  showLightbox(button.closest("[data-compiled_lua]").dataset.compiled_lua)
})

window.addEventListener("keydown", e => {
  if (e.key === "Escape") {
    hideLightbox()
  }
})
