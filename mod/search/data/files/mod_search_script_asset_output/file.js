// autocomplete.js.coffee
(function(){decko.slot.ready(function(e){return e.find("._autocomplete").each(function(){return decko.initAutoCardPlete($(this))}),e.find("._select2autocomplete").each(function(){return decko.select2Autocomplete.init($(this))})}),decko.initAutoCardPlete=function(e){var t,n;if(t=e.data("options-card"))return n=t+".json?view=name_match",e.autocomplete({source:decko.slot.path(n)})},decko.select2Autocomplete={init:function(e,t,n){var o;return o=$.extend({},this._defaults(e),t),n&&$.extend(o.ajax,n),e.select2(o)},_defaults:function(e){return{multiple:!1,width:"100%!important",minimumInputLength:0,maximumSelectionSize:1,placeholder:e.attr("placeholder"),escapeMarkup:function(e){return e},ajax:{delay:200,cache:!0,url:decko.path(":search.json"),processResults:function(e){return{results:e}},data:function(e){return{query:{keyword:e.term},view:"complete"}}}}}}}).call(this);
// search_box.js.coffee
(function(){$(window).ready(function(){var e;if((e=$("._search-box")).length>0)return decko.searchBox.init(e),e.on("select2:select",function(e){return decko.searchBox.select(e)})}),decko.searchBox={init:function(e){return decko.select2Autocomplete.init(e,this._options(),{data:function(t){var n;return n={query:{keyword:t.term},view:"search_box_complete"},e.closest("form").serializeArray().map(function(e){if("query[keyword]"!==e.name)return n[e.name]=e.value}),n}})},select:function(e){var t,n;return n=this._eventHref(e),t=$(e.target).closest("form"),n?window.location=decko.path(n):t.submit()},_eventHref:function(e){var t,n;return(t=(n=e.params)&&n.data)&&t.href},_options:function(){return{minimumInputLength:1,containerCssClass:"select2-search-box-autocomplete",dropdownCssClass:"select2-search-box-dropdown",allowClear:!0,width:"100%"}}}}).call(this);