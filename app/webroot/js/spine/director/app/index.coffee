Spine                   = require("spine")
$                       = Spine.$
Drag                    = require("plugins/drag")
User                    = require('models/user')
Config                  = require('models/config')
Album                   = require('models/album')
Root                    = require('models/root')
Gallery                 = require('models/gallery')
Toolbar                 = require("models/toolbar")
Settings                = require('models/settings')
SpineError              = require("models/spine_error")
Clipboard               = require("models/clipboard")
MainView                = require("controllers/main_view")
LoginView               = require("controllers/login_view")
LoaderView              = require("controllers/loader_view")
Sidebar                 = require("controllers/sidebar")
ShowView                = require("controllers/show_view")
ModalSimpleView         = require("controllers/modal_simple_view")
ModalActionView         = require("controllers/modal_action_view")
ToolbarView             = require("controllers/toolbar_view")
LoginView               = require("controllers/login_view")
SidebarFlickr           = require("controllers/sidebar_flickr")
AlbumEditView           = require("controllers/album_edit_view")
PhotoEditView           = require("controllers/photo_edit_view")
UploadEditView          = require("controllers/upload_edit_view")
GalleryEditView         = require("controllers/gallery_edit_view")
OverviewView            = require('controllers/overview_view')
MissingView             = require("controllers/missing_view")
FlickrView              = require("controllers/flickr_view")
Extender                = require('plugins/controller_extender')
SpineDragItem           = require('models/drag_item')

require('spine/lib/route')
require('spine/lib/manager')
require("plugins/manager")

class Main extends Spine.Controller
  
  @extend Drag
  @extend Extender
  
  # Note:
  # this is how to change a toolbar:
  # App.showView.trigger('change:toolbar', 'Album')
  
  elements:
    '#fileupload'         : 'uploader'
    '#flickr'             : 'flickrEl'
    '#main'               : 'mainEl'
    '#sidebar'            : 'sidebarEl'
    '#show'               : 'showEl'
    '#overview'           : 'overviewEl'
    '#sidebar .flickr'    : 'sidebarFlickrEl'
    '#missing'            : 'missingEl'
    '#ga'                 : 'galleryEl'
    '#al'                 : 'albumEl'
    '#ph'                 : 'photoEl'
    '#fu'                 : 'uploadEl'
    '#loader'             : 'loaderEl'
    '#login'              : 'loginEl'
    '#modal-gallery'      : 'slideshowEl'
    '#show .content'      : 'content'
    '.vdraggable'         : 'vDrag'
    '.hdraggable'         : 'hDrag'
    '.status-symbol img'  : 'statusIcon'
    '.status-text'        : 'statusText'
    '.status-symbol'      : 'statusSymbol'
    
  events:
    'click [class*="-trigger-edit"]' : 'activateEditor'
    'click'               : 'delegateFocus'
    
    'drop'                : 'drop'
    
    'keyup'               : 'key'
    'keydown'             : 'key'

  constructor: ->
    super
    
    @version = "2.0.0"
    
    # default user settings if none found
    @autoupload = true
    
    Spine.DragItem = SpineDragItem.create()
    
    @ALBUM_SINGLE_MOVE = @createImage('/img/cursor_folder_1.png')
    @ALBUM_DOUBLE_MOVE = @createImage('/img/cursor_folder_3.png')
    @IMAGE_SINGLE_MOVE = @createImage('/img/cursor_images_1.png')
    @IMAGE_DOUBLE_MOVE = @createImage('/img/cursor_images_3.png')
    
    @modal = exists: false
    
    $(window).bind('hashchange', @proxy @storeHash)
    
    @ignoredHashes = ['slideshow', 'overview', 'preview', 'flickr', 'logout']
    
    User.bind('pinger', @proxy @validate)
    
    #reset clipboard
    Clipboard.fetch()
    Clipboard.destroyAll()
    
    Settings.one('refresh', @proxy @refreshSettings)
    Settings.one('change', @proxy @changeSettings)
    
    $('#modal-gallery').bind('hidden', @proxy @hideSlideshow)
    
    @modalView = new ModalSimpleView
#    @modal2ButtonView = new Modal2ButtonView
#      el: @modalEl
    @missingView = new MissingView
      el: @missingEl
    @gallery = new GalleryEditView
      el: @galleryEl
      externalClass: '.optGallery'
    @album = new AlbumEditView
      el: @albumEl
      externalClass: '.optAlbum'
    @photo = new PhotoEditView
      el: @photoEl
      externalClass: '.optPhoto'
    @upload = new UploadEditView
      el: @uploadEl
      externalClass: '.optUpload'
    @sidebar = new Sidebar
      el: @sidebarEl
      externalClass: '.optSidebar'
    @sidebarFlickr = new SidebarFlickr
      el: @sidebarFlickrEl
    @loginView = new LoginView
      el: @loginEl
    @mainView = new MainView
      el: @mainEl
    @loaderView = new LoaderView
      el: @loaderEl
    @flickrView = new FlickrView
      el: @flickrEl
    @showView = new ShowView
      el: @showEl
      activeControl: 'btnGallery'
      uploader: @upload
      sidebar: @sidebar
      parent: @
    @overviewView = new OverviewView
      el: @overviewEl
      slideshow: @showView.slideshowView
    @slideshowView = @showView.slideshowView

    @vmanager = new Spine.Manager(@sidebar)
    @vmanager.external = @showView.toolbarOne
    @vmanager.initDrag @vDrag,
      initSize: => @el.width()/4
      sleep: true
      disabled: false
      axis: 'x'
      min: -> 8
      tol: -> 50
      max: => @el.width()/2
      goSleep: => @sidebar.inner.hide()
      awake: => @sidebar.inner.show()

    @hmanager = new Spine.Manager(@gallery, @album, @photo, @upload)
    @hmanager.external = @showView.toolbarOne
    @hmanager.initDrag @hDrag,
      initSize: => @el.height()/4
      disabled: false
      axis: 'y'
      min: -> 50
      sleep: true
      max: => @el.height()/1.5
      goSleep: ->
#        controller.el.hide() if controller = @manager.active()
      awake: ->
#        controller.el.show() if controller = @manager.active()
    
    @appManager = new Spine.Manager(@mainView, @loaderView)
    @contentManager = new Spine.Manager(@overviewView, @missingView, @showView, @flickrView)
    
    @hmanager.bind('awake', => @showView.trigger('awake'))
    @hmanager.bind('sleep', => @showView.trigger('sleep'))
    @hmanager.bind('change', @proxy @changeEditCanvas)
    @appManager.bind('change', @proxy @changeMainCanvas)
    @contentManager.bind('change', @proxy @changeContentCanvas)
    
    @bind('canvas', @proxy @canvas)

    @upload.trigger('active')
    @loaderView.trigger('active')
    
    @initializeFileupload()
    
    @routes
      '/gallery/:gid/:aid/:pid': (params) ->
        Root.updateSelection params.gid or null
        Gallery.updateSelection params.aid or null
        Album.updateSelection params.pid or null
        if params.pid is 'slideshow'
          @showView.trigger('active', @showView.photosView, params.pid)
        else
          @showView.trigger('active', @showView.photoView)
      '/gallery/:gid/:aid': (params) ->
        Root.updateSelection params.gid or null
        Gallery.updateSelection params.aid or null
        @showView.trigger('active', @showView.photosView)
      '/gallery/:gid': (params) ->
        Root.updateSelection params.gid or null
        @showView.trigger('active', @showView.albumsView)
      '/galleries/*': ->
        @showView.trigger('active', @showView.galleriesView)
      '/overview/*': ->
        @overviewView.trigger('active')
      '/slideshow/:index': (params) ->
        @showView.trigger('active', @showView.slideshowView, params.index)
#      '/slideshow/*glob': (params) ->
#        @showView.trigger('active', @showView.slideshowView, params.glob)
      '/wait/*glob': (params) ->
        @showView.trigger('active', @showView.waitView)
      '/flickr/:type/:page': (params) ->
        @flickrView.trigger('active', params.type, params.page)
      '/flickr/': (params) ->
        @flickrView.trigger('active', @showView.flickrView)
      '/*glob': (params) ->
        @missingView.trigger('active')

    @defaultSettings =
      welcomeScreen: false,
      test: true
    
    @loadToolbars()
    
  storeHash: ->
    return unless settings = Settings.findUserSettings()
    if hash = location.hash
      if !@ignoredHashes.contains(hash)
        settings.previousHash = hash
      settings.hash = hash
      settings.save()
    
  fullscreen: ->
    Spine.trigger('chromeless', true)
    
  validate: (user, json) ->
    @log 'Pinger done'
    valid = user.sessionid is json.sessionid
    valid = user.id is json.id and valid
    unless valid
      User.logout()
    else
      @loadUserSettings(user.id)
      @delay @setupView, 1000
      
  drop: (e) ->
    @log 'drop'
    
    # prevent ui drops
    unless e.originalEvent.dataTransfer.files.length
      e.stopPropagation()
      e.preventDefault()
      
    # clean up placeholders, jquery-sortable-plugin sometimes leaves alone
    $('.sortable-placeholder').detach()
      
  notify: (text) ->
    @modalView.render
      small: true
      body: -> require("views/notify")
        text: text
    .show()
      
  loadUserSettings: (id) ->
    Settings.fetch()
    
    unless settings = Settings.findByAttribute('user_id', id)
      @notify 'You seem to be using this App for the first time.<br>The Auto Upload will be set to '+ @autoupload + '.<br>To change this setting<br>go to Photo->Auto Upload'
      
      Settings.create
        user_id   : id
        autoupload: @autoupload
        hash: '#/overview/'
        previousHash: '#/overview/'
        
  refreshSettings: (records) ->
    if hash = location.hash
      @navigate hash
    else if settings = Settings.findUserSettings()
      @navigate settings.hash
      
    
  changeSettings: (rec) ->
    @navigate rec.hash
    
  setupView: ->
    Spine.unbind('uri:alldone')
    @mainView.trigger('active')
    @mainView.el.hide()
    @statusSymbol.fadeOut('slow', @proxy @finalizeView)
      
  finalizeView: ->
    @loginView.render()
    @mainView.el.fadeIn(1500)
      
  canvas: (controller) ->
    controller.trigger 'active'
    
  changeMainCanvas: (controller) ->
    
  changeContentCanvas: (controller) ->
    controller.el.addClass('in')
      
  changeEditCanvas: (controller) ->
  
  initializeFileupload: ->
    @uploader.fileupload
      autoUpload        : true
      singleFileUploads : false
      sequentialUploads : true
      maxFileSize       : 10000000 #5MB
      maxNumberOfFiles  : 20
      acceptFileTypes   : /(\.|\/)(gif|jpe?g|png)$/i
      getFilesFromResponse: (data) ->
        res = []
        for file in data.files
          res.push file
        res
    
  loadToolbars: ->
    Toolbar.load()

  activateEditor: (e) ->
    el = $(e.currentTarget)
    test = el.prop('class')
    if /\bgal-*/.test(test)
      @gallery.trigger('active')
    else if /\balb-*/.test(test)
      @album.trigger('active')
    else if /\bpho-*/.test(test)
      @photo.trigger('active')
      
    e.preventDefault()
    e.stopPropagation()
    
  key: (e) ->
    code = e.charCode or e.keyCode
    type = e.type
    
    @log e.type , code
    
    el=$(document.activeElement)
    isFormfield = $().isFormElement(el)
      
    #use this keydown for tabindices to gain focus
    #tabindex elements will then be able to listen for keyup events subscribed in the controller 
    return unless type is 'keydown'
    
    switch code
      when 8 #Backspace
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 9 #Tab
        unless isFormfield
          @sidebar.toggleDraghandle()
          e.preventDefault()
      when 13 #Return
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 27 #Esc
        unless isFormfield
          if @overviewView.isActive()
            @delegateFocus(e, @overviewView)
          else
            @delegateFocus(e, @showView)
          e.preventDefault()
      when 32 #Space
        unless isFormfield
          if @overviewView.isActive()
            @delegateFocus(e, @overviewView)
          else
            @delegateFocus(e, @showView)
          e.preventDefault()
      when 37 #Left
        unless isFormfield
          if @overviewView.isActive()
            @delegateFocus(e, @overviewView)
          else
            @delegateFocus(e, @showView)
          e.preventDefault()
      when 38 #Up
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 39 #Right
        unless isFormfield
          if @overviewView.isActive()
            @delegateFocus(e, @overviewView)
          else
            @delegateFocus(e, @showView)
          e.preventDefault()
      when 40 #Down
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 65 #ctrl A
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 73 #ctrl I
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
      when 77 #ctrl M
        unless isFormfield
          @delegateFocus(e, @showView)
          e.preventDefault()
          
  delegateFocus: (e, controller = @showView) ->
    el=$(document.activeElement)
    return if $().isFormElement(el)
    controller.focus()
      
module?.exports = Main
