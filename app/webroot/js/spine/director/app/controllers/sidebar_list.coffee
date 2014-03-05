Spine           = require("spine")
$               = Spine.$
Album           = require('models/album')
Gallery         = require('models/gallery')
AlbumsPhoto     = require('models/albums_photo')
GalleriesAlbum  = require('models/galleries_album')
Drag            = require("plugins/drag")
KeyEnhancer     = require("plugins/key_enhancer")
Extender        = require('plugins/controller_extender')
require("plugins/tmpl")

class SidebarList extends Spine.Controller

  @extend Drag
  @extend KeyEnhancer
  @extend Extender
  
  elements:
    '.gal.item'               : 'item'
    '.expander'               : 'expander'

  events:
    "click      .gal.item"            : 'clickGallery'
    "click      .alb.item"            : 'clickAlbum'
    "click      .expander"            : 'clickExpander'
    'dragstart  .sublist-item'        : 'dragstart'
    'dragenter  .sublist-item'        : 'dragenter'
    'dragleave  .sublist-item'        : 'dragleave'
    'drop       .sublist-item'        : 'drop'
    'dragend    .sublist-item'        : 'dragend'

  selectFirst: true
    
  contentTemplate: (items) ->
    $('#sidebarContentTemplate').tmpl(items)
    
  sublistTemplate: (items) ->
    $('#albumsSublistTemplate').tmpl(items)
    
  ctaTemplate: (item) ->
    $('#ctaTemplate').tmpl(item)
    
  constructor: ->
    super
    AlbumsPhoto.bind('change', @proxy @renderItemFromAlbumsPhoto)
    GalleriesAlbum.bind('change', @proxy @renderItemFromGalleriesAlbum)
    Gallery.bind('change', @proxy @change)
#    Album.bind('refresh destroy create update', @proxy @renderAllSublist)
#    Album.one('refresh', @proxy @renderAllSublist)
    Album.bind('update destroy', @proxy @renderSublists)
    Spine.bind('drag:timeout', @proxy @expandAfterTimeout)
    Spine.bind('expose:sublistSelection', @proxy @exposeSublistSelection)
    Spine.bind('gallery:exposeSelection', @proxy @exposeSelection)
    Gallery.bind('activate', @proxy @activate)
    
  template: -> arguments[0]
  
  change: (item, mode, e) =>
    console.log 'SidebarList::change'
    
    switch mode
      when 'create'
        @current = item
        @create item
      when 'update'
        @current = item
        @update item
      when 'destroy'
        @current = false
        @destroy item
          
    @activate(@current)
        
  create: (item) ->
    @append @template item
    @reorder item
  
  update: (item) ->
    @updateTemplate item
    @reorder item
  
  destroy: (item) ->
    @children().forItem(item, true).remove()
  
  render: (items, mode) ->
    console.log 'SidebarList::render'
    @children().addClass('invalid')
    for item in items
      galleryEl = @children().forItem(item)
      unless galleryEl.length
        @append @template item
        @reorder item
      else
        @updateTemplate(item).removeClass('invalid')
      @renderOneSublist item
    @children('.invalid').remove()
    
  reorder: (item) ->
    id = item.id
    index = (id, list) ->
      for itm, i in list
        return i if itm.id is id
      i
    
    children = @children()
    oldEl = @children().forItem(item)
    idxBeforeSort =  @children().index(oldEl)
    idxAfterSort = index(id, Gallery.all().sort(Gallery.nameSort))
    newEl = $(children[idxAfterSort])
    if idxBeforeSort < idxAfterSort
      newEl.after oldEl
    else if idxBeforeSort > idxAfterSort
      newEl.before oldEl
    
  renderAllSublist: ->
    console.log 'SidebarList::renderAllSublist'
    for gal, index in Gallery.records
      @renderOneSublist gal
      
  renderSublists: (album) ->
    console.log 'SidebarList::renderSublists'
    gas = GalleriesAlbum.filter(album.id, key: 'album_id')
    for ga in gas
      @renderOneSublist gallery if gallery = Gallery.exists ga.gallery_id
      
  renderOneSublist: (gallery = Gallery.record) ->
    console.log 'SidebarList::renderOneSublist'
    filterOptions =
      key:'gallery_id'
      joinTable: 'GalleriesAlbum'
      sorted: true
    albums = Album.filterRelated(gallery.id, filterOptions)
    for album in albums
      album.count = AlbumsPhoto.filter(album.id, key: 'album_id').length
    albums.push {flash: ' '} unless albums.length
    galleryEl = @children().forItem(gallery)
    gallerySublist = $('ul', galleryEl)
    gallerySublist.html @sublistTemplate(albums)
    
    @exposeSublistSelection gallery
  
  updateTemplate: (item) ->
    console.log 'SidebarList::updateTemplate'
    galleryEl = @children().forItem(item)
    galleryContentEl = $('.item-content', galleryEl)
    tmplItem = galleryContentEl.tmplItem()
    tmplItem.tmpl = $( "#sidebarContentTemplate" ).template()
    try
      tmplItem.update()
    catch e
    galleryEl
    
  renderItemFromGalleriesAlbum: (ga, mode) ->
    gallery = Gallery.exists(ga.gallery_id)
    @updateTemplate gallery
    @renderOneSublist gallery if gallery
    
  renderItemFromAlbumsPhoto: (ap, mode) ->
    console.log 'SidebarList::renderItemFromAlbumsPhoto'
    gas = GalleriesAlbum.filter(ap.album_id, key: 'album_id')
    for ga in gas
      @renderItemFromGalleriesAlbum ga
  
  exposeSelection: (item = Gallery.record) ->
    @children().removeClass('active')
    @children().forItem(item).addClass("active") if item.id is Gallery.record.id
    @exposeSublistSelection(item)
    
  exposeSublistSelection: (gallery = Gallery.record) ->
    console.log 'SidebarList::exposeSublistSelection'
    removeAlbumSelection = =>
      galleries = []
      galleries.push gal for gal in Gallery.records
      for item in galleries
        galleryEl = @children().forItem(item)
        albumsEl = galleryEl.find('li')
        $('.glyphicon', albumsEl).removeClass('glyphicon-folder-open')
        
        
    if gallery
      removeAlbumSelection()
      galleryEl = @children().forItem(gallery)
      albumsEl = galleryEl.find('li')
      albumsEl.removeClass('selected').removeClass('active')
      
      albums = Gallery.selectionList()
      for album in albums
        if alb = Album.exists(album)
          albumsEl.forItem(alb).addClass('selected') 
        
      if activeAlbum = Album.exists(albums.first())
        activeEl = albumsEl.forItem(activeAlbum).addClass('active')
        $('.glyphicon', activeEl).addClass('glyphicon-folder-open')
        
    @refreshElements()
    
  activate: (idOrRecord) ->
    Gallery.current(idOrRecord)
    Album.trigger('activate', Gallery.selectionList())
    @exposeSelection()

  clickGallery: (e) ->
    console.log 'SidebarList::clickGallery'
    e.stopPropagation()
    e.preventDefault()
    galleryEl = $(e.target).closest('li.gal')
    item = galleryEl.item()
    if item
      @expand(item) 
      @navigate '/gallery', item.id
    
  clickAlbum: (e) ->
    galleryEl = $(e.target).parents('.gal').addClass('active')
    albumEl = $(e.currentTarget)
    galleryEl = $(e.currentTarget).closest('.gal')
    
    album = albumEl.item()
    gallery = galleryEl.item()
    
    @navigate '/gallery', gallery.id + '/' + album.id
    
    e.stopPropagation()
    e.preventDefault()
    
  clickExpander: (e) ->
    galleryEl = $(e.target).closest('li.gal')
    item = galleryEl.item()
    @expand(item, false, e) if item
    
    e.stopPropagation()
    e.preventDefault()
    
    
  expand: (item, force, e) ->
    galleryEl = @galleryFromItem(item)
    expander = $('.expander', galleryEl)
    if e
      targetIsExpander = $(e.currentTarget).hasClass('expander')
    
    if force
      @openSublist(galleryEl)
    else
      open = galleryEl.hasClass('open')
      active = galleryEl.hasClass('active')

      if open
        @closeSublist(galleryEl) if active or targetIsExpander
      else
        @openSublist(galleryEl)
        
  openSublist: (el) ->
    el.addClass('open')
    
  closeSublist: (el) ->
    el.removeClass('open')
      
  galleryFromItem: (item) ->
    @children().forItem(item)
    
  expandAfterTimeout: (e, timer) ->
    clearTimeout timer
    galleryEl = $(e.target).closest('.gal.item')
    item = galleryEl.item()
    return unless item and item.id isnt Spine.dragItem.origin.id
    @expand(item, true)

  close: () ->
    
  closeAllSublists: (item) ->
    for gallery in Gallery.all()
      parentEl = @galleryFromItem gallery
      unless parentEl.hasClass('manual')
        @expand gallery, item?.id is gallery.id
        
    
  show: (e) ->
    App.contentManager.change App.showView
    e.stopPropagation()
    e.preventDefault()
    
module?.exports = SidebarList