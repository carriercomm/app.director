Spine           = require("spine")
$               = Spine.$
Model           = Spine.Model
Gallery         = require('models/gallery')
Album           = require('models/album')
Photo           = require('models/photo')
AlbumsPhoto     = require('models/albums_photo')
GalleriesAlbum  = require('models/galleries_album')
Extender        = require("plugins/controller_extender")
Drag            = require("plugins/drag")

require("plugins/tmpl")

class AlbumsList extends Spine.Controller
  
  @extend Extender
  @extend Drag
  
  events:
    'click .opt-AddAlbums'         : 'addAlbums'
    'click .delete'                : 'deleteAlbum'
    'click .back'                  : 'back'
    'click .zoom'                  : 'zoom'
    
  constructor: ->
    super
    @widows = []
    @add = @html
    Album.bind('update', @proxy @updateTemplate)
    Album.bind("ajaxError", Album.errorHandler)
    GalleriesAlbum.bind('change', @proxy @changeRelated)
    AlbumsPhoto.bind('beforeDestroy', @proxy @widowedAlbumsPhoto)
    Gallery.bind('change:selection', @proxy @exposeSelection)
    
  changedAlbums: (gallery) ->
    
    
  changeRelated: (item, mode) ->
    return unless @parent and @parent.isActive()
    return unless Gallery.record
    return unless Gallery.record.id is item['gallery_id']
    return unless album = Album.exists(item['album_id'])
    console.log 'AlbumsList::changeRelated'
    
    switch mode
      when 'create'
        @wipe()
        @append @template album
        @renderBackgrounds [album]
        @el.sortable('destroy').sortable()
#        $('.tooltips', @el).tooltip()
        
      when 'destroy'
        el = @findModelElement(album)
        el.detach()
        
      when 'update'
        @el.sortable('destroy').sortable()
    
    @refreshElements()
    @el
  
  render: (items=[], mode) ->
    console.log 'AlbumsList::render'
    if items.length
      @wipe()
      @[mode] @template items
      @renderBackgrounds items
#      @el.sortable() if Gallery.record
      @exposeSelection(Gallery.record)
    else if mode is 'add'
      @html '<label class="invite"><span class="enlightened">Nothing to add. &nbsp;</span></label>'
      @append '<h3><label class="invite label label-default"><span class="enlightened">Either no more albums can be added or there is no gallery selected.</span></label></h3>'
    else
      if Gallery.record
        if Album.count()
          @html '<label class="invite"><span class="enlightened">This Gallery has no albums. &nbsp;</span><br><br>
          <button class="opt-CreateAlbum dark large"><i class="glyphicon glyphicon-asterisk"></i><span>&nbsp;New Album</span></button>
          <button class="opt-AddAlbums dark large"><i class="glyphicon glyphicon-book"></i><span>&nbsp;Library</span></button>
          <button class="back dark large"><i class="glyphicon glyphicon-chevron-up"></i><span>&nbsp;Up</span></button>
          </label>'
        else
          @html '<label class="invite"><span class="enlightened">This Gallery has no albums.<br>It\'s time to create one.</span><br><br>
          <button class="opt-CreateAlbum dark large"><i class="glyphicon glyphicon-asterisk"></i><span>&nbsp;New Album</span></button>
          <button class="back dark large"><i class="glyphicon glyphicon-chevron-up"></i><span>&nbsp;Up</span></button>
          </label>'
      else
        @html '<label class="invite"><span class="enlightened">You don\'t have any albums yet</span><br><br>
        <button class="opt-CreateAlbum dark large"><i class="glyphicon glyphicon-asterisk"></i><span>&nbsp;New Album</span></button>
        <button class="back dark large"><i class="glyphicon glyphicon-chevron-up"></i><span>&nbsp;Up</span></button>
        </label>'
    
    @el
    
  updateTemplate: (album) ->
    console.log 'AlbumsList::updateTemplate'
    albumEl = @children().forItem(album)
    contentEl = $('.thumbnail', albumEl)
    active = albumEl.hasClass('active')
    hot = albumEl.hasClass('hot')
    style = contentEl.attr('style')
    tmplItem = contentEl.tmplItem()
    alert 'no tmpl item' unless tmplItem
    if tmplItem
      tmplItem.tmpl = $( "#albumsTemplate" ).template()
      tmplItem.update?()
      albumEl = @children().forItem(album)
      contentEl = $('.thumbnail', albumEl)
      albumEl.toggleClass('active', active)
      albumEl.toggleClass('hot', hot)
      contentEl.attr('style', style)
    @el.sortable()
  
  exposeSelection: (item=Gallery.record, sel) ->
    console.log 'AlbumsList::exposeSelection'
    
    if Gallery.record
      if item then return unless Gallery.record.id is item.id
    else
      return if item
      
      
    item = item or Gallery
    selection = sel or item.selectionList()
      
    @deselect()
    for id in selection
      $('#'+id, @el).addClass("active")
    if first = selection.first()
      $('#'+first, @el).addClass("hot")
      
    
  # workaround:
  # remember the Album since
  # after last AlbumPhoto is destroyed the Album container cannot be retrieved anymore
  widowedAlbumsPhoto: (ap) ->
    console.log 'AlbumsList::widowedAlbumsPhoto'
    list = ap.albums()
    @widows.push item for item in list
    @widows
  
  renderBackgrounds: (albums) ->
    console.log 'AlbumsList::renderBackgrounds'
    if @widows.length
      Model.Uri.Ajax.cache = false
      for widow in @widows
#        @processAlbum album
        $.when(@processAlbumDeferred(widow)).done (xhr, rec) =>
          @callback xhr, rec
      @widows = []
      Model.Uri.Ajax.cache = true
    for album in albums
#        @processAlbum album
      $.when(@processAlbumDeferred(album)).done (xhr, rec) =>
        @callback xhr, rec
  
  processAlbum: (album) ->
    data = album.photos(4)
  
    Photo.uri
      width: 50
      height: 50,
      (xhr, rec) => @callback(xhr, album)
      data
  
  processAlbumDeferred: (album) ->
    console.log 'AlbumsList::processAlbumDeferred'
    deferred = $.Deferred()
    data = album.photos(4)
    
    Photo.uri
      width: 50
      height: 50,
      (xhr, rec) -> deferred.resolve(xhr, album)#@callback(xhr, album)
      data
      
    deferred.promise()
      
  callback: (json, album) ->
    console.log 'AlbumsList::callback'
    el = $('#'+album.id, @el)
    thumb = $('.thumbnail', el)
    
    res = for jsn in json
      ret = for key, val of jsn
        val.src
      ret[0]
    
    css = for itm in res
      'url(' + itm + ')'
      
    thumb.css('backgroundImage', if css.length then css else 'url(img/drag_info.png)')

  zoom: (e) ->
    console.log 'AlbumsList::zoom'
    item = $(e.currentTarget).item()
    
    @parent.stopInfo()
    @navigate '/gallery', (Gallery.record?.id or ''), item.id
    e.preventDefault()
    e.stopPropagation()
    
  back: (e) ->
    @navigate '/galleries/'
    e.preventDefault()
    e.stopPropagation()

  deleteAlbum: (e) ->
    console.log 'AlbumsList::deleteAlbum'
    item = $(e.currentTarget).item()
    return unless item?.constructor?.className is 'Album'
    
    Spine.trigger('destroy:album', [item.id])
    
    e.stopPropagation()
    e.preventDefault()
    
  addAlbums: (e) ->
    console.log 'AlbumsList::add'
    e.stopPropagation()
    e.preventDefault()
    
    Spine.trigger('albums:add')
    
  wipe: ->
    if Gallery.record
      first = Gallery.record.count() is 1
    else
      first = Album.count() is 1
    @el.empty() if first
    @el
    
module?.exports = AlbumsList