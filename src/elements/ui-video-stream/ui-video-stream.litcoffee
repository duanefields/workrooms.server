Show a video stream with user interface.

#Attributes
##audio
##video
##mirror
##selfie
Mute the local audio output to avoid feedback.
##snapshot
Encoded snapshot as a data-url, allowing easy text transport.
##stream
Live video stream will be played.

#Events
##snapshot
Fired when a fresh snapshot is taken.

    _ = require('lodash')
    require('../elementmixin.litcoffee')
    audio = require('../../scripts/web-audio.litcoffee')
    audioContext = audio.getContext()


    Polymer 'ui-video-stream',

      ready: ->
        @$.snapshot.hide()
        @$.sourcemutedaudio.hide()
<<<<<<< HEAD

      attached: ->

        if !@hasAttribute('selfie') and !document.querySelector('conference-room').focused
          audio.playSound 'media/startup.ogg'
          window.focus()
=======
>>>>>>> 07d0962d2bf9a332eb2a8403a56a85c16ab79c21

Cool. Static snapshots to use when the video is muted. This gets defined when
the video plays.

      takeSnapshot: ->
        width = parseInt(getComputedStyle(@$.video).getPropertyValue('width').replace('px',''))
        height = parseInt(getComputedStyle(@$.video).getPropertyValue('height').replace('px',''))
        @$.takesnapshot.setAttribute('width', width)
        @$.takesnapshot.setAttribute('height', height)
        try
          ctx = @$.takesnapshot.getContext('2d')
          ctx.drawImage(@$.video, 0, 0, width, height)
          @snapshot = @$.takesnapshot.toDataURL('image/png')
        catch error
          console.log error, width, height

Looking for attributes to mute.

      audioChanged: ->
        if @audio
          @$.sourcemutedaudio.hide()
        else
          @$.sourcemutedaudio.show()

      videoChanged: ->
        if @video and @stream
          @$.snapshot.hideAnimated =>
            @$.video.showAnimated()
        else
          @$.video.hideAnimated =>
            @$.snapshot.showAnimated()

Show the snapshot in the image viewer, and if there is no stream, which will
happen on preview tiles such as screenshares, then go ahead and display.

      snapshotChanged: ->
        @$.snapshot.setAttribute 'src', @snapshot
        @fire 'snapshot'
        if not @stream
          @$.video.hideAnimated =>
            @$.loading.hideAnimated =>
              @$.snapshot.showAnimated()

Play the video stream. This mutes local audio if it is a `selfie`, otherwise
the feedback would be brutal. Mirroing is available too.

      streamChanged: ->

        if @hasAttribute('selfie')
          @$.video.setAttribute 'muted', ''

        if @hasAttribute('mirror')
          @$.video.classList.add 'mirror'
          @$.snapshot.classList.add 'mirror'
        
        if @stream
          @$.video.src = URL.createObjectURL(@stream)
          @$.video.play()

          @$.loading.hide()
          setTimeout @takeSnapshot.bind(@), 3000
        else
          @$.video.src = ''
          @$.loading.show()
