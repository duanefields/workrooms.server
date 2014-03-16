This is a non visual element that listens for
`audio.on` and `audio.off` and `stream` events and then mutes
or unmutes said stream for you.

Not clear that this really warrants being its own component.

    Polymer 'audio-control',
      attached: ->
        document.addEventListener 'audio.on', (evt) =>
          @stream?.getAudioTracks()?.forEach (x) -> x.enabled = true
        document.addEventListener 'audio.off', (evt) =>
          @stream?.getAudioTracks()?.forEach (x) -> x.enabled = false
