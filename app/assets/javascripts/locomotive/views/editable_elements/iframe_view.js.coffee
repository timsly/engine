Locomotive.Views.EditableElements ||= {}

class Locomotive.Views.EditableElements.IframeView extends Backbone.View

  el: '.preview iframe'

  startup: true

  initialize: ->
    # shortcut
    @window = $(@el)[0].contentWindow

    # when the url of the iframe changes, process
    $(@el).load (event) => @on_load(event)

  reload: ->
    $(@el).attr('src', @preview_url)

  on_load: (event) ->
    # Able to get the path to the edit form?
    if (path = @edit_view_path())?
      @preview_url = @window.document.location.href

      if !@startup
        History.replaceState({ live_editing: true, url: @preview_url }, '', path)
        @options.parent_view.replace_edit_view(path)
      else
        @startup = false

    @build_and_render_page_view()

  edit_view_path: ->
    # the browser might be unable to load the iframe because of
    # the 'X-Frame-Options' option which is set to 'SAMEORIGIN'.
    try
      $document = $(@window.document)
      return $document.find('meta[name=locomotive-editable-elements-path]').attr('content')
    catch e
      # reload the iframe with the previous url and display an error message
      @reload()
      Locomotive.notify $(@el).data('redirection-error'), 'warning'
      return null

  build_and_render_page_view: ->
    @page_view.remove() if @page_view?
    @page_view = new Locomotive.Views.EditableElements.PageView
      el:           $(@window.document)
      parent_view:  @
      button_labels:
        edit: $(@el).data('edit-label')
    @page_view.render()

    # insert the highlighter CSS (path to the CSS in the iframe data)
    window.addStylesheet(@window.document, $(@el).data('style-path'))

  remove: ->
    super()
    @page_view.remove() if @page_view?
    _.each @tokens, (token) -> PubSub.unsubscribe(token)
