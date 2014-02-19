Show a video stream with user interface.

#Attributes
##sourcemutedvideo
##sourcemutedaudio
##mirror
##mutedaudio

#Events
##stream
Fires off when a stream is present.
##playerready
Fires off that this player is ready.

#Methods
##display(stream)

    _ = require('lodash')
    bonzo = require('bonzo')

    SNAPSHOT_TIMEOUT = 1 * 1000

    Polymer 'ui-video-stream',

      ready: ->
        bonzo(@$.snapshot).hide()
        bonzo(@$.sourcemutedaudio).hide()

Cool. Static snapshots to use when the video is muted. This gets defined when
the video plays.

      attached: ->
        @$.video.addEventListener 'canplay', =>
          @fire 'snapshot'
        @addEventListener 'snapshot', =>
          width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
          height = parseInt(getComputedStyle(@$.video).getPropertyValue('height').replace('px',''))
          @$.takesnapshot.setAttribute('width', width)
          @$.takesnapshot.setAttribute('height', height)
          takeSnapshot = =>
            width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
            height = @$.video.videoHeight / (@$.video.videoWidth/width)
            ctx = @$.takesnapshot.getContext('2d')
            ctx.drawImage(@$.video, 0, 0, width, height)
            @$.snapshot.setAttribute('src', @$.takesnapshot.toDataURL('image/png'))
          takeSnapshot()
          setInterval =>
            if not @hasAttribute('sourcemutedvideo') or @getAttribute('sourcemutedvideo') is 'false'
              takeSnapshot()
          , SNAPSHOT_TIMEOUT

Looking for attributes to mute. This is a neat trick as these are attributes
that trigger by presence, so we can hit them with the ?

      sourcemutedaudioChanged: (oldValue, newValue) ->
        if newValue?
          bonzo(@$.sourcemutedaudio).show()
        else
          bonzo(@$.sourcemutedaudio).hide()

      sourcemutedvideoChanged: (oldValue, newValue) ->
        if newValue?
          bonzo(@$.video).hide()
          bonzo(@$.snapshot).show()
        else
          bonzo(@$.video).show()
          bonzo(@$.snapshot).hide()

      display: (stream) ->
        if @hasAttribute('mutedaudio')
          @$.video.setAttribute('muted', '')
        else
          @$.video.removeAttribute('muted')
        if @hasAttribute('mirror')
          bonzo(@$.video)
           .css('-webkit-transform', 'scaleX(-1)')
          bonzo(@$.snapshot)
           .css('-webkit-transform', 'scaleX(-1)')
        if stream
          @$.video.src = URL.createObjectURL(stream)
          @$.video.play()
          bonzo(@$.loading).hide()
          @fire 'stream', stream
          @fire 'playerready', @
        else
          @$.video.src = ''
          bonzo(@$.loading).show()
