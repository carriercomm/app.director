var $, GalleryList;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
if (typeof Spine === "undefined" || Spine === null) {
  Spine = require("spine");
}
$ = Spine.$;
GalleryList = (function() {
  __extends(GalleryList, Spine.Controller);
  GalleryList.extend(Spine.Controller.Drag);
  GalleryList.prototype.elements = {
    '.gal.item': 'item',
    '.expander': 'expander'
  };
  GalleryList.prototype.events = {
    "click      .gal.item": "click",
    "dblclick   .gal.item": "dblclick",
    "click      .alb.item": "clickAlb",
    "click      .expander": "expand",
    'dragstart  .sublist-item': 'dragstart',
    'dragenter  .sublist-item': 'dragenter',
    'dragover   .sublist-item': 'dragover',
    'dragleave  .sublist-item': 'dragleave',
    'drop       .sublist-item': 'drop',
    'dragend    .sublist-item': 'dragend'
  };
  GalleryList.prototype.selectFirst = false;
  GalleryList.prototype.sublistTemplate = function(items) {
    return $('#albumsSublistTemplate').tmpl(items);
  };
  function GalleryList() {
    this.change = __bind(this.change, this);    GalleryList.__super__.constructor.apply(this, arguments);
    Spine.bind('drag:timeout', this.proxy(this.expandExpander));
    Spine.bind('render:sublist', this.proxy(this.renderSublist));
    Spine.bind('expose:sublistSelection', this.proxy(this.exposeSublistSelection));
  }
  GalleryList.prototype.template = function() {
    return arguments[0];
  };
  GalleryList.prototype.change = function(item, mode, e) {
    var cmdKey, dblclick;
    console.log('GalleryList::change');
    if (e) {
      cmdKey = this.isCtrlClick(e);
      dblclick = e.type === 'dblclick';
    }
    this.children().removeClass("active");
    if (!cmdKey && item) {
      if (mode !== 'update') {
        this.current = item;
      }
      this.children().forItem(this.current).addClass("active");
    } else {
      this.current = false;
    }
    Gallery.current(this.current);
    Spine.trigger('change:selectedGallery', this.current, mode);
    if (mode === 'edit') {
      return App.showView.btnEditGallery.click();
    }
  };
  GalleryList.prototype.render = function(items, item, mode) {
    var new_content, old_content;
    console.log('GalleryList::render');
    if (!item) {
      this.items = items;
      this.html(this.template(this.items));
    } else if (mode === 'update') {
      old_content = $('.item-content', '#' + item.id);
      new_content = $('.item-content', this.template(item)).html();
      old_content.html(new_content);
    } else if (mode === 'create') {
      this.append(this.template(item));
    } else if (mode === 'destroy') {
      $('#' + item.id).remove();
    }
    this.change(item, mode);
    if ((!this.current || this.current.destroyed) && !(mode === 'update')) {
      if (!this.children(".active").length) {
        return this.children(":first").click();
      }
    }
  };
  GalleryList.prototype.renderSublist = function(gallery) {
    var album, albums, total, _i, _len;
    console.log('GalleryList::renderSublist');
    albums = Album.filter(gallery.id);
    total = 0;
    for (_i = 0, _len = albums.length; _i < _len; _i++) {
      album = albums[_i];
      total += album.count = AlbumsPhoto.filter(album.id).length;
    }
    if (!albums.length) {
      albums.push({
        flash: 'no albums'
      });
    }
    $('#' + gallery.id + ' ul').html(this.sublistTemplate(albums));
    return $('.item-header .cta', '#' + gallery.id).html(Album.filter(gallery.id).length + ' <span style="font-size: 0.5em;">(' + total + ')</span>');
  };
  GalleryList.prototype.exposeSublistSelection = function(gallery) {
    var album, albums, galleryEl, id, _i, _len, _ref, _results;
    console.log('GalleryList::exposeSublistSelection');
    galleryEl = this.children().forItem(gallery);
    albums = galleryEl.find('li');
    albums.removeClass('active');
    _ref = Gallery.selectionList();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      id = _ref[_i];
      album = Album.find(id);
      _results.push(albums.forItem(album).addClass('active'));
    }
    return _results;
  };
  GalleryList.prototype.children = function(sel) {
    return this.el.children(sel);
  };
  GalleryList.prototype.clickAlb = function(e) {
    var album, albumEl, gallery, galleryEl;
    console.log('GalleryList::albclick');
    albumEl = $(e.currentTarget);
    galleryEl = $(e.currentTarget).closest('li.gal');
    album = albumEl.item();
    gallery = galleryEl.item();
    Gallery.current(gallery);
    if (!this.isCtrlClick(e)) {
      Album.current(album);
      Gallery.updateSelection([album.id]);
      if (App.hmanager.hasActive()) {
        this.openPanel('album', App.showView.btnAlbum);
      }
    } else {
      Album.current();
      Gallery.emptySelection();
      Album.emptySelection();
    }
    this.change(gallery);
    this.exposeSublistSelection(gallery);
    App.showView.trigger('change:toolbar', 'Album');
    Spine.trigger('show:photos', album);
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
  GalleryList.prototype.click = function(e) {
    var item;
    console.log('GalleryList::click');
    item = $(e.target).item();
    this.change(item, 'show', e);
    this.exposeSublistSelection(item);
    App.showView.trigger('change:toolbar', 'Gallery');
    Spine.trigger('show:albums');
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
  GalleryList.prototype.dblclick = function(e) {
    var item;
    console.log('GalleryList::edit');
    item = $(e.target).item();
    App.showView.lockToolbar();
    this.change(item, 'edit', e);
    App.showView.unlockToolbar();
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
  GalleryList.prototype.expandExpander = function(e) {
    var closest, el, expander;
    el = $(e.target);
    closest = (el.closest('.item')) || [];
    if (closest.length) {
      expander = $('.expander', closest);
      if (expander.length) {
        return this.expand(e, true);
      }
    }
  };
  GalleryList.prototype.expand = function(e, force) {
    var content, gallery, icon, parent;
    if (force == null) {
      force = false;
    }
    parent = $(e.target).parents('li');
    gallery = parent.item();
    icon = $('.expander', parent);
    content = $('.sublist', parent);
    if (force) {
      icon.toggleClass('expand', force);
    } else {
      icon.toggleClass('expand');
    }
    if ($('.expand', parent).length) {
      this.renderSublist(gallery);
      this.exposeSublistSelection(gallery);
      content.show();
    } else {
      content.hide();
    }
    e.stopPropagation();
    e.preventDefault();
    return false;
  };
  return GalleryList;
})();
if (typeof module !== "undefined" && module !== null) {
  module.exports = GalleryList;
}