Spine ?= require("spine")
$      = Spine.$

class ModalView extends Spine.Controller
  
  elements:
    '.modal-header'       : 'header'
    '.modal-body'         : 'body'
    '.modal-footer'       : 'footer'
  
  template: (item) ->
    $('#modalTemplate').tmpl(item)
    
  constructor: ->
    super
    # initialize Twitters Modal
    @el.modal
      show: false
    @defaults =
      header  : 'Default Header Text'
      body    : 'Default Body Text'
      footer  : 'Default Footer Text'
    
  render: (opts) ->
    console.log 'ModalView::render'
    options = $.extend @defaults, opts
    @html @template options
    @el
      
  show: ->
    @el.modal 'show'

  hide: ->
    @el.modal 'hide'
    
module?.exports = ModalView