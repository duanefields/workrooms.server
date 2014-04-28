Mixin methods to HTMLElement.

    bonzo = require('bonzo')
    bean = require('bean')
    morpheus = require('morpheus')
    _ = require('lodash')

    ANIMATION_DURATION = 300

Showing with animation and a callback that fires once it is done.

    if not HTMLElement::showAnimated
      HTMLElement::showAnimated = (callback) ->
        target = @
        @visible = true
        @classList.remove('hide')
        morpheus target,
          opacity: 1
          duration: ANIMATION_DURATION
          complete: ->
            callback() if callback

    if not HTMLElement::show
      HTMLElement::show = ->
        @visible = true
        @classList.remove('hide')

Hiding with animation and a callback that fires once it is done.

    if not HTMLElement::hideAnimated
      HTMLElement::hideAnimated = (callback) ->
        target = @
        @visible = false
        morpheus target,
          opacity: 0
          duration: ANIMATION_DURATION
          complete: ->
            target.classList.add('hide')
            callback() if callback

    if not HTMLElement::hide
      HTMLElement::hide = ->
        @visible = false
        @classList.add('hide')

Polymer doesn't have a callback or way to animate elements as they are
data bound, so patch the DOM calls to trap appending and removing nodes.

    if not Node::appendChild.patched?
      Node::appendChild.patched = true

    if not Node::removeChild.patched?
      Node::removeChild.patched = true

jQuery doesn't seem to understand offset and position with polymer. This patch
makes the semantic-ui tooltips show in the right spot.

    if jQuery?
      jQuery.fn.position = ->
        if not @[0]
          return
        else
          bonzo(@[0]).offset()

Tooltip positioning for every element.

    if not HTMLElement::tooltipPosition
      HTMLElement::tooltipPosition = ->
        if bonzo(@).offset().left > (bonzo(@).parent().offset().width/2)
          'bottom left'
        else
          'bottom right'

Turn all the keys into a string.

    if PolymerExpressions?
      PolymerExpressions::keyString = (obj) ->
        _.keys(obj).join(' ')
