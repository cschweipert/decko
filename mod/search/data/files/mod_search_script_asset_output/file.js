// autocomplete.js.coffee
(function(){decko.slot.ready(function(e){return e.find("._autocomplete").each(function(){return decko.initAutoCardPlete($(this))}),e.find("._select2autocomplete").each(function(){return decko.select2Autocomplete.init($(this))})}),decko.initAutoCardPlete=function(e){var t,n;if(t=e.data("options-card"))return n=t+".json?view=name_match",e.autocomplete({source:decko.slot.path(n)})},decko.select2Autocomplete={init:function(e,t,n){var o;return o=$.extend({},this._defaults(e),t),n&&$.extend(o.ajax,n),e.select2(o)},_defaults:function(e){return{multiple:!1,width:"100%!important",minimumInputLength:0,maximumSelectionSize:1,placeholder:e.attr("placeholder"),escapeMarkup:function(e){return e},ajax:{delay:200,cache:!0,url:decko.path(":search.json"),processResults:function(e){return{results:e}},data:function(e){return{query:{keyword:e.term},view:"complete"}}}}}}}).call(this);
// search_box.js.coffee
(function(){$(window).ready(function(){var t,o;return o=$("._search-box"),t=new decko.searchBox(o),o.data("searchBox",t),t.init()}),decko.searchBox=function(){function t(t){this.box=t,this.sourcepath=this.box.data("completepath"),this.originalpath=this.sourcepath,this.config={source:this.sourcepath,select:this.select}}return t.prototype.init=function(){return this.box.autocomplete(this.config,{html:!0})},t.prototype.select=function(t,o){var e;if(e=o.item.url)return window.location=e},t.prototype.form=function(){return this.box.closest("form")},t.prototype.keyword=function(){return this.form().find("#query_keyword").val()},t}()}).call(this);