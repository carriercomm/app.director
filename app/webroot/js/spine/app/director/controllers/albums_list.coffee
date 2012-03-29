Spine ?= require("spine")
$      = Spine.$

class AlbumsList extends Spine.Controller
  
  events:
    'click .item'        : 'click'
    'dblclick .item'     : 'dblclick'
    'mousemove .item'    : 'infoUp'
    'mouseleave .item'   : 'infoBye'
    'dragstart .item'    : 'stopInfo'
    
  constructor: ->
    super
    # initialize twitters slideshow
#    @el.toggleSlideshow()
    Album.bind('sortupdate', @proxy @sortupdate)
    GalleriesAlbum.bind('destroy', @proxy @sortupdate)
    Photo.bind('refresh', @proxy @refreshBackgrounds)
    AlbumsPhoto.bind('beforeDestroy beforeCreate', @proxy @clearAlbumCache)
    AlbumsPhoto.bind('beforeDestroy', @proxy @widowedAlbums)
    AlbumsPhoto.bind('destroy create', @proxy @changeBackgrounds)
    Album.bind("ajaxError", Album.errorHandler)
    Spine.bind('album:activate', @proxy @activate)
    
  template: -> arguments[0]
  
  albumPhotosTemplate: (items) ->
    $('#albumPhotosTemplate').tmpl items
  
  change: (items) ->
    @renderBackgrounds items
  
  select: (item, e) ->
    @activate()
    
  exposeSelection: ->
    list = Gallery.selectionList()
    @deselect()
    for id in list
      if Album.exists(id)
        item = Album.find(id)
        el = @children().forItem(item)
        el.addClass("active")
        
    Spine.trigger('expose:sublistSelection', Gallery.record)
  
  activate: ->
    selection = Gallery.selectionList()
    if selection.length is 1
      first = Album.find(selection[0]) if Album.exists(selection[0])

      unless first?.destroyed
        @current = first
        Album.current(first)
    else
        Album.current()
        
    @exposeSelection()
  
  render: (items, mode) ->
    console.log 'AlbumsList::render'
    @el.toggleClass('all', !Gallery.record)
      
    if items.length
      @html @template items
    else
      if Album.count()
        @html '<label class="invite"><span class="enlightened">This Gallery has no albums. &nbsp;<button class="optCreateAlbum dark large">New Album</button><button class="optShowAllAlbums dark large">Show available Albums</button></span></label>'
      else
        @html '<label class="invite"><span class="enlightened">Time to create a new album. &nbsp;<button class="optCreateAlbum dark large">New Album</button></span></label>'
        
    @change items, mode
    @el
    
  clearAlbumCache: (record, mode) ->
    album = Album.find(record.album_id)
    Album.clearCache record.album_id
    
  refreshBackgrounds: (photos) ->
    uploadAlbum = App.upload.album
    @renderBackgrounds [uploadAlbum] if uploadAlbum
  
  changeBackgrounds: (ap, mode) ->
    console.log 'AlbumsList::changeBackgrounds'
    albums = ap.albums()
    @renderBackgrounds albums, mode
  
  widowedAlbums: (ap) ->
    @widows = ap.albums()
  
  renderBackgrounds: (albums, mode) ->
    return unless App.ready

    if albums.length
      @processAlbum album for album in albums
    else if @widows?.length
      @processAlbum album for album in @widows
      @widows = []
  
  processAlbum: (album) ->
    album.uri
      width: 50
      height: 50
      , 'html'
      , (xhr, album) =>
        @callback(xhr, album)
      , 4
  
  callback: (json, item) =>
    el = @children().forItem(item)
    searchJSON = (itm) ->
      for key, value of itm
        value
    css = for itm in json
      arr = searchJSON itm
      'url(' + arr[0].src + ')' if arr.length
    el.css('backgroundImage', css)
  
  create: ->
    Spine.trigger('create:album')

  click: (e) ->
    console.log 'AlbumsList::click'
    item = $(e.currentTarget).item()
    
    item.addRemoveSelection(@isCtrlClick(e))
    
    @activate()
    
    Spine.trigger('change:toolbarOne')
#    Spine.trigger('change:toolbarOne', ['Album'])
    
    e.stopPropagation()
    e.preventDefault()

  dblclick: (e) ->
    #@openPanel('album', App.showView.btnAlbum)
      
    Spine.trigger('show:photos')
    @activate()
    
    e.stopPropagation()
    e.preventDefault()
  
  edit: (e) ->
    console.log 'AlbumsList::edit'
    item = $(e.target).item()
    @change item
    
  sortupdate: (e, item) ->
    @children().each (index) ->
      item = $(@).item()
#      console.log item
      if item and Gallery.record
        ga = GalleriesAlbum.filter(item.id, func: 'selectAlbum')[0]
        if ga and ga.order isnt index
          ga.order = index
          ga.save()
      else if item
        album = (Album.filter(item.id, func: 'selectAlbum'))[0]
        album.order = index
        album.save()
        
    @exposeSelection()
    
  infoUp: (e) =>
    @info.up(e)
    e.preventDefault()
    
  infoBye: (e) =>
    @info.bye()
    e.preventDefault()
    
  stopInfo: (e) =>
    @info.bye()

module?.exports = AlbumsList