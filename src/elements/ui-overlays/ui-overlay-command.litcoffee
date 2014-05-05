An overlay action with a Font Awesome icon. This will show on a hover and
fire off an event when clicked.
#Attributes
##command
This is the type of an event to fire when clicked.
##detail
Detail of the event to fire when clicked.
##icon
Name of a the font-awesome style to use as the icon. If you really want
you can put any style names in here to use other than FontAwesome.

#Events
This fires a dynamic event based on `command`.

    bonzo = require 'bonzo'

    Polymer 'ui-overlay-command',
      resize: ->
        offset = bonzo(@$.overlay).offset()
        size = Math.min(offset.width, offset.height) * 0.8
        bonzo(@$.overlay)
          .css 'font-size', size
          .css 'padding-top', size * 0.125
      attached: ->
        setInterval =>
          @resize()
        , 1000
        @resize()
      clickLink: (evt) ->
        if @command
          @fire @command, @detail
        if not @href?.length
          evt.preventDefault()
      tooltipChanged: ->
        $(@$.tool).popup
          inline: true
          content: @tooltip
          position: @tooltipPosition()

