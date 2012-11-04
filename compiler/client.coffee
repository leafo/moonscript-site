
class WebCompiler
  api: "proxy.php"

  compile: (code, callback) =>
    $.post "#{@api}?action=compile", {code: code}, callback

  execute: (code, callback) =>
    $.post "#{@api}?action=run", {code: code}, callback

  version: (callback) ->
    $.get "#{@api}?action=version", callback

class Page
  constructor: (container) ->
    @container = $ container
    @status = $ "#status"
    @out = $ "#out"

    @compiler = new WebCompiler @

    @compiler.version (v) => $("#version").text "(#{v})"
    @set_status "success", "Ready"

    @highlighter = new Lua

    @last_action = null

    @editor = CodeMirror.fromTextArea $("#input")[0], {
      tabMode: "shift"
      theme: "moon"
      lineNumbers: true
    }

    @examples = new ExamplePicker "#example-picker", @
    @snippets = new SnippetSaver $("#header").find(".toolbar"), @

    buttons = $("#compile, #run").prop("disabled", false)

    @container.on "click", "#compile", =>
      buttons.prop("disabled", true)
      start_time = new Date
      @set_status "loading", "Compiling..."
      code = @editor.getValue()
      @compiler.compile code, (res) =>
        buttons.prop("disabled", false)
        if res.error
          @set_status "error", "Fatal error"
          @put_output res.msg
        else
          @set_status "success", "Finished in #{new Date - start_time}ms"
          @put_lua res.code

        @last_action = { type: "compile", input: code, output: res.code }
      false

    @container.on "click", "#run", =>
      buttons.prop("disabled", true)
      start_time = new Date
      @set_status "loading", "Running..."
      code = @editor.getValue()
      @compiler.execute code, (res) =>
        buttons.prop("disabled", false)
        if res.error
          @set_status "error", "Fatal error"
          @put_output res.msg
        else
          @set_status "success", "Finished in #{new Date - start_time}ms"
          @put_output res.stdout
        @last_action = { type: "run", input: code, output: res.stdout }
      false

    @container.on "click", "#clear", =>
      @editor.setValue ""
      @editor.focus()
      false

  set_status: (type, msg) ->
    if type == "loading"
      msg = "<img src='img/ajax-loader.gif' /> #{msg}"

    @status
      .removeClass("success error loading").addClass(type)
      .html msg
  
  put_lua: (code) ->
    @out.html @highlighter.format_text code

  put_output: (text) ->
    if text == ""
      @out.html '<span class="meta">&rarr; No output</span>'
    else
      @out.text text

class SnippetSaver
  api: "snippet.php"

  error: (msg) =>
    @status.html """<span class="error"><b>Error: </b>#{msg}</span>"""

  load_snippet: ->
    hash = window.location.hash
    if hash
      return if @page.last_action && "##{@page.last_action.id}" == hash
      hash = hash.substr 1
      return unless hash.match /^[0-9a-z]+$/i
      @status.html '<img src="img/ajax-loader.gif" /> Loading Snippet...'

      $.ajax {
        url: "#{@api}?#{$.param act: "get", id: hash}"
        success: (res) =>
          if res.error
            @error res.msg
            return

          @status.text "Loaded snippet ##{hash}"
          @page.editor.setValue res.input
          @page.editor.focus()
          @page.put_output res.output || ""

          res.id = hash
          @page.last_action = res

        error: =>
          @error "Failed to load snippet"
      }

  constructor: (container, @page) ->
    @container = $ container
    button = @container.find("#save_button")

    @status = @container.find "#toolbar_status"
    @url = @container.find "#snippet_url"

    $(window).on "hashchange", => @load_snippet()
    @load_snippet()

    @container.on "click", "#save_button", (e) =>
      action = @page.last_action

      if !action || action.id
        alert "You must compile or execute before saving"
        return false

      if action.input.match /^\s*$/
        alert "Can't save blank snippet"
        return false

      button.prop "disabled", true
      @url.hide()
      @status.html '<img src="img/ajax-loader.gif" /> Saving...'

      $.post "#{@api}?act=save", action, (res) =>
        button.prop "disabled", false

        if res.error
          alert res.msg
          @status.empty()
          return

        @url.show().val 'http://moonscript.org/compiler/#' + res.id
        @status.text "Saved!"

        action.id = res.id
        window.location.hash = "#" + res.id

      false

class ExamplePicker
  example_dir: "examples"

  update: (fname) =>
    @page.editor.setValue @cache[fname]

  constructor: (container, @page) ->
    @container = $ container
    @cache = {}
    @container.on "change", (e) =>
      return unless fname = $(e.currentTarget).val()
      console.log "getting", fname

      if @cache[fname]
        @update fname
      else
        $.get "#{@example_dir}/#{fname}", (res) =>
          @cache[fname] = res
          @update fname

$ ->
  page = new Page "#compiler"
  page.editor.focus()

