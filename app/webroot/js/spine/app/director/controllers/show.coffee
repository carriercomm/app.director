class ShowView extends Spine.Controller

  @extend Spine.Controller.Toolbars
  
  elements:
    '#views .views'           : 'views'
    '.photosHeader'           : 'photosHeaderEl'
    '.albumsHeader'           : 'albumsHeaderEl'
    '.header'                 : 'albumHeader'
    '.optOverview'            : 'btnOverview'
    '.optEditGallery'         : 'btnEditGallery'
    '.optGallery'             : 'btnGallery'
    '.optAlbum'               : 'btnAlbum'
    '.optPhoto'               : 'btnPhoto'
    '.optUpload'              : 'btnUpload'
    '.optSlideshow'           : 'btnSlideshow'
    '.toolbar'                : 'toolBar'
    '.albums'                 : 'albumsEl'
    '.photos'                 : 'photosEl'
    '.items'                  : 'items'
    '#slider'                 : 'slider'
    
  events:
    "click .optOverview"              : "showOverview"
    "click .optPhotos"                : "showPhotos"
    "click .optAlbums"                : "showAlbums"
    "click .optCreatePhoto"           : "createPhoto"
    "click .optDestroyPhoto"          : "destroyPhoto"
    "click .optShowPhotos"            : "showPhotos"
    "click .optCreateAlbum"           : "createAlbum"
    "click .optShowAllAlbums"         : "showAllAlbums"
    "click .optDestroyAlbum"          : "destroyAlbum"
    "click .optEditGallery"           : "editGallery"
    "click .optCreateGallery"         : "createGallery"
    "click .optDestroyGallery"        : "destroyGallery"
    "click .optEmail"                 : "email"
    "click .optGallery"               : "toggleGallery"
    "click .optAlbum"                 : "toggleAlbum"
    "click .optPhoto"                 : "togglePhoto"
    "click .optUpload"                : "toggleUpload"
    "click .optSlideshow"             : "toggleSlideshow"
    "click .optThumbsize"             : "showSizeSlider"
    'dblclick .draghandle'            : 'toggleDraghandle'
    'click .items'                    : "deselect" 
    'fileuploadprogress'              : "uploadProgress" 
    'fileuploaddone'                  : "uploadDone"
    'slide #slider'                   : 'sliderSlide'
    'slidestop #slider'               : 'sliderStop'
    'slidestart #slider'              : 'sliderStart'
    
  toolsTemplate: (items) ->
    $("#toolsTemplate").tmpl items

  constructor: ->
    super
    @albumsHeader = new AlbumsHeader
      el: @albumsHeaderEl
    @photosHeader = new PhotosHeader
      el: @photosHeaderEl
    @albumsView = new AlbumsView
      el: @albumsEl
      className: 'items'
      header: @albumsHeader
      parent: @
      parentModel: 'Gallery'
    @photosView = new PhotosView
      el: @photosEl
      className: 'items'
      header: @photosHeader
      parent: @
      parentModel: 'Album'
    
    Spine.bind('change:canvas', @proxy @changeCanvas)
    Gallery.bind('change', @proxy @renderToolbar)
    Album.bind('change', @proxy @renderToolbar)
    Photo.bind('change', @proxy @renderToolbar)
    @bind('change:toolbar', @proxy @changeToolbar)
    @bind('render:toolbar', @proxy @renderToolbar)
    @bind("toggle:view", @proxy @toggleView)
    @current = @albumsView
    @sOutValue = 110
    
    if @activeControl
      @initControl @activeControl
    else throw 'need initial control'
    @edit = @editGallery
    
    @canvasManager = new Spine.Manager(@albumsView, @photosView)
    @canvasManager.change @current
    @headerManager = new Spine.Manager(@albumsHeader, @photosHeader)
    @headerManager.change @albumsHeader
    
  changeCanvas: (controller) ->
    console.log 'ShowView::changeCanvas'
    @current = controller
    @el.data current:@current.el.data()
    @canvasManager.change controller
    @headerManager.change controller.header
    

  renderToolbar: ->
    console.log 'ShowView::renderToolbar'
    @toolBar.html @toolsTemplate @currentToolbar
    @refreshElements()
    
  renderViewControl: (controller, controlEl) ->
    active = controller.isActive()

    $(".options .opt").each ->
      if(@ == controlEl)
        $(@).toggleClass("active", active)
      else
        $(@).removeClass("active")
  
  showGallery: ->
    App.contentManager.change(App.showView)
  
  showAlbums: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('show:albums')
  
  showAllAlbums: ->
    Gallery.record = false
    Spine.trigger('change:selectedGallery', false)
  
  showPhotos: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('show:photos')
  
  createGallery: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('create:gallery')
  
  createPhoto: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('create:photo')
  
  createAlbum: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('create:album')
  
  editGallery: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    App.galleryEditView.render()
    App.contentManager.change(App.galleryEditView)
    #@focusFirstInput App.galleryEditView.el

  editAlbum: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('edit:album')

  destroyGallery: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('destroy:gallery')
  
  destroyAlbum: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('destroy:album')

  destroyPhoto: (e) ->
    return if $(e.currentTarget).hasClass('disabled')
    Spine.trigger('destroy:photo')

  showOverview: (e) ->
    Spine.trigger('show:overview')

  animateView: ->
    hasActive = ->
      if App.hmanager.hasActive()
        return App.hmanager.enableDrag()
      App.hmanager.disableDrag()
    
    height = ->
      App.hmanager.currentDim
      if hasActive() then parseInt(App.hmanager.currentDim)+"px" else "8px"
    
    @views.animate
      height: height()
      400
    
  toggleGallery: (e) ->
    @changeToolbar Gallery
    @trigger("toggle:view", App.gallery, e.target)

  toggleAlbum: (e) ->
    @changeToolbar Album
    @trigger("toggle:view", App.album, e.target)
    
  togglePhoto: (e) ->
    @changeToolbar Photo
    @trigger("toggle:view", App.photo, e.target)

  toggleUpload: (e) ->
    @changeToolbar 'Upload'
    @trigger("toggle:view", App.upload, e.target)

  toggleSlideshow: (e) ->
    @changeToolbar 'Slideshow'
    @trigger("toggle:view", App.slideshow, e.target)
  
  toggleView: (controller, control) ->
    isActive = controller.isActive()
    
    if(isActive)
      App.hmanager.trigger("change", false)
    else
      @activeControl = $(control)
      App.hmanager.trigger("change", controller)
    
    @renderViewControl controller, control
    @animateView()
  
  toggleDraghandle: ->
    @activeControl.click()
    
  initControl: (control) ->
    if Object::toString.call(control) is "[object String]"
      @activeControl = @[control]
    else
      @activeControl = control
      
  deselect: (e) =>
    item = @el.data().current
      
    switch @current.parentModel
      when 'Album'
        Spine.Model['Album'].emptySelection()
        Photo.current()
        Spine.trigger('photo:exposeSelection')
        Spine.trigger('change:selectedPhoto', item)
      when 'Gallery'
        Spine.Model['Gallery'].emptySelection()
        Album.current()
        Spine.trigger('album:exposeSelection')
        Spine.trigger('change:selectedAlbum', item)
    
    @current.items.deselect()
    @renderToolbar()
    
    e.stopPropagation()
    e.preventDefault()
    false
    
  uploadProgress: (e, coll) ->
    console.log coll
    
  uploadDone: (e, coll) ->
    console.log coll
    
  sliderInValue: (val) ->
    val = val or @sOutValue
    @sInValue=(val/2)-20
    @sInValue
    
  sliderOutValue: (val) ->
    val = val or @sInValue
    @sOutValue=(val+20)*2
    @sOutValue
    
  initSlider: ->
    t = @slider.slider
      orientation: 'vertical'
      value: @sliderInValue()
    
  showSizeSlider: =>
    @initSlider()
    @slider.toggle()
      
  sliderStart: =>
    @photosView.list.sliderStart()
    
  sliderSlide: =>
    value = @sliderOutValue(@slider.slider('value'))
    @photosView.list.size(value)
    
  sliderStop: =>
    # rerender thumbnails to its final size
    console.log @sliderOutValue(@slider.slider('value'))
    
    
    