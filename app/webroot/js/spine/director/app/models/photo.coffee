Spine         = require("spine")
$             = Spine.$
Model         = Spine.Model
Filter        = require("plugins/filter")
Gallery       = require('models/gallery')
Album         = require('models/album')
Extender      = require("plugins/model_extender")
AjaxRelations = require("plugins/ajax_relations")

Uri           = require("plugins/uri")
Cache         = require("plugins/cache")
require("spine/lib/ajax")

class Photo extends Spine.Model
  @configure "Photo", 'id', 'title', "description", 'filesize', 'captured', 'exposure', "iso", 'longitude', 'aperture', 'make', 'model', 'user_id', 'order', 'active', 'src'

  @extend Cache
  @extend Model.Ajax
  @extend Uri
  @extend AjaxRelations
  @extend Filter
  @extend Extender

  @selectAttributes: ['title', "description", 'user_id']
  
  @parent: 'Album'
  
  @foreignModels: ->
    'Album':
      className             : 'Album'
      joinTable             : 'AlbumsPhoto'
      foreignKey            : 'photo_id'
      associationForeignKey : 'album_id'

  @url: '' + base_url + @className.toLowerCase() + 's'

  @nameSort: (a, b) ->
    aa = (a or '').name?.toLowerCase()
    bb = (b or '').name?.toLowerCase()
    return if aa == bb then 0 else if aa < bb then -1 else 1
  
  @defaults:
    width: 140
    height: 140
    square: 1
    quality: 70
  
  @success: (uri) =>
    console.log 'Ajax::success'
    Photo.trigger('uri', uri)
    
  @error: (json) =>
    Photo.trigger('ajaxError', json)
  
  @create: (atts) ->
    @__super__.constructor.create.call @, atts
  
  @refresh: (values, options = {}) ->
    @__super__.constructor.refresh.call @, values, options
    
  @trashed: ->
    res = []
    for item of @irecords
      res.push item unless AlbumsPhoto.exists(item.id)
    res
    
  @inactive: ->
    @findAllByAttribute('active', false)
    
  @getGallery: ->
    Gallery.record
    
  @getAlbum: ->
    Album.record
    
  init: (instance) ->
    return unless instance?.id
    @constructor.initCache instance.id
  
  selectAttributes: ->
    result = {}
    result[attr] = @[attr] for attr in @constructor.selectAttributes
    result

  select: (joinTableItems) ->
    for record in joinTableItems
      return true if record.photo_id is @id and (@['order'] = record.order)?
      
  selectPhoto: (id) ->
    return true if @id is id
    return false
      
  details: =>
    gallery : Model.Gallery.record
    album   : Model.Album.record
    photo   : Model.Photo.record
    author  : User.first().name

module?.exports = Model.Photo = Photo