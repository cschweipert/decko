$.extend decko,
  # returns full path with slot parameters
  slotPath: (path, slot)->
    params = decko.slotData(slot)
    decko.path(path) + ( (if path.match /\?/ then '&' else '?') + $.param(params) )

  slotData: (slot) ->
    xtra = {}
    main = $('#main').children('.card-slot').data 'cardName'
    xtra['main'] = main if main?
    if slot
      xtra['is_main'] = true if slot.isMain()
      slotdata = slot.data 'slot'
      decko.slotParams slotdata, xtra, 'slot' if slotdata?
    xtra

  slotEditView: (slot) ->
    data = decko.slotData(slot)
    if data["edit"]? then data["edit"] else "standard"

  slotParams: (raw, processed, prefix)->
    $.each raw, (key, value)->
      cgiKey = prefix + '[' + snakeCase(key) + ']'
      if key == 'items'
        decko.slotParams value, processed, cgiKey
      else
        processed[cgiKey] = value

  slotReady: (func)->
    $('document').ready ->
      $('body').on 'slotReady', '.card-slot', (e, slotter) ->
        e.stopPropagation()
        if slotter?
          func.call this, $(this), $(slotter)
        else
          func.call this, $(this)

jQuery.fn.extend
  slot: (status="success", mode="replace") ->
    if mode == "modal"
      @modalSlot()
    else
      @selectSlot("slot-#{status}-selector") ||
        @selectSlot("slot-selector") ||
        @closest(".card-slot")

  selectSlot: (selectorName) ->
    if selector = @data(selectorName)
      slot = @findSlot selector
      slot && slot[0] && slot

  isSlot: ->
    $(this).hasClass "card-slot"

  isMain: -> @slot().parent('#main')[0]

  findSlot: (selector) ->
    if selector == "modal-origin"
      @findOriginSlot("modal")
    else if selector == "overlay-origin"
      @findOriginSlot("overlay")
    else
      target_slot = @closest(selector)
      parent_slot = @closest '.card-slot'

      # if slot-selector doesn't apply to a child, search in all parent slots and finally in the body
      while target_slot.length == 0 and parent_slot.length > 0
        target_slot = $(parent_slot).find(selector)
        parent_slot = $(parent_slot).parent().closest '.card-slot'
      if target_slot.length == 0
        $(selector)
      else
        target_slot

  # type can be "modal" or "overlay"
  findOriginSlot: (type) ->
    overlaySlot = @closest("[data-#{type}-origin-slot-id]")
    origin_slot_id = overlaySlot.data("#{type}-origin-slot-id")
    origin_slot = $("[data-slot-id=#{origin_slot_id}]")
    if origin_slot[0]?
      origin_slot
    else
      console.log "couldn't find origin with slot id #{origin_slot_id}"

  reloadSlot: (url) ->
    $slot = $(this)
    if $slot.length > 1
      $slot.each ->
        $(this).reloadSlot url
      return

    $slot = $slot.slot() unless $slot.isSlot
    return unless $slot[0]

    unless url?
      url = $slot.slotUrl()
    $slot.addClass 'slotter'
    $slot.attr 'href', url
    $slot.data "url", url
    this[0].href = url # that's where handleRemote gets the url from
                       # .attr(href, url) only works for anchors
    $slot.data "remote", true
    $.rails.handleRemote($slot)

  slotUrl: ->
    mark = if @data('cardId') then "~#{@data('cardId')}" else @data("cardName")
    decko.slotPath "#{mark}?view=#{@data("slot")["view"]}"

  setSlotContent: (val, mode, $slotter) ->
    v = $(val)[0] && $(val) || val

    if typeof(v) == "string"
      # Needed to support "TEXT: result" pattern in success (eg deleting nested cards)
      @slot("success", mode).replaceWith v
    else
      if v.hasClass("_overlay")
        mode = "overlay"
      else if v.hasClass("_modal")
        mode = "modal"
      @slot("success", mode).setSlotContentFromElement v, mode, $slotter
    v

  setSlotContentFromElement: (el, mode, $slotter) ->
    if mode == "overlay"
      @addOverlay(el, $slotter)
    else if el.hasClass("_modal-slot") or mode == "modal"
      el.showAsModal($slotter)
    else
      slot_id = @data("slot-id")
      el.attr("data-slot-id", slot_id) if slot_id
      @replaceWith el

    el.triggerSlotReady($slotter)

  triggerSlotReady: (slotter) ->
    @trigger "slotReady", slotter
    @find(".card-slot").trigger "slotReady", slotter
