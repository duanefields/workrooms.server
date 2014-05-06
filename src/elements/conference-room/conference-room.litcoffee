The conference room is a lot like a controller, bringing together
multiple different elements and coordinating them. In particular, this
element is responsible for taking events from `RTCPeerConnection` objects in
scope and sending them along to the signalling server in order to set up
peer-to-peer communication.

This differs from a controller in that only the DOM scoping is used, events
bubble up from contained elements, and messages are send back down
via method calls and property sets. Nice and simple.

#Attributes
##localstream
This is your local video/audio data stream.
##calls
Array of all active calls metadata. These aren't calls themselves, just
identifiers used to data bind and generate `ui-video-call` elements.
##serverconfig
The server literally sends the config back to the client on a connect.
##nametag
A string that is all about who you are.

    require '../elementmixin.litcoffee'
    uuid = require 'node-uuid'
    _ = require 'lodash'
    _.str = require 'underscore.string'
    bowser = require 'bowser'
    SignallingServer = require '../../scripts/signalling-server.litcoffee'
    getScreenMedia = require 'getscreenmedia'

    Polymer 'conference-room',

      roomSelectorKeypressed: -> 
        window.location.hash = "/" + _.str.dasherize @$.roomSelector.value?.toLowerCase()
        
      roomChanged: _.debounce ->
        if @roomLabel.length > 2
          @signallingServer.send 'register',
            room: @room   
      , 500

      call: (clientid, screenshare) ->
        if clientid
          message =
            to: clientid
            screenshare: screenshare?
          @signallingServer.send 'call', message

      screenshare: (clientid) ->
        @call clientid, true

      attached: ->
        if bowser.browser.chrome
          @$.chromeonly.hide()
        @nametag = 'Anonymous'
        @audioon = true
        @videoon = true
        @serverconfig = null
        @calls = []
        @chatCount = 0
        @focused = true
        @roomLabel = _.str.humanize window.location.hash?.replace('#/', '')

        @root = "#{document.location.origin}#{document.location.pathname}"
        if @root.slice(0,3) isnt 'https'
          window.location = "https#{@root.slice(4)}#{document.location.hash or ''}"
        if @root.slice(-1) isnt '/'
          @root += '/'
        @signallingServer = new SignallingServer("ws#{@root.slice(4)}")
        @signallingServer.on 'error', (err) ->
          console.log err
        @addEventListener 'error', (err) ->
          console.log err


##Setting Up Signalling
Hello from the server! The roomChanged event handler will hook the rest of the registration

        @signallingServer.on 'hello', =>
          @fire 'hello'
          

After we have registered, the server sends along a configuration, this is to
protect -- or really to be able to switch -- ids for OAuth and STUN/TURN.

        @signallingServer.on 'configured', (config) =>
          @serverConfig = config

        @signallingServer.on 'pong', (hashes) =>
          @fire 'pong', hashes

And sometimes you just have to let go.

        @signallingServer.on 'disconnect', =>
          @signallingServer.close()
          @signallingServer = null

##Toolbar Buttons

Show and hide the selfie -- this really needs to be data bound instead.

        @addEventListener 'selfie.on', =>
          @$.selfie.showAnimated()
        @addEventListener 'selfie.off', =>
          @$.selfie.hideAnimated()

Sidebars, are you even allowed to have an application without one any more?

         @addEventListener 'chatbar.on', =>
          @$.chatbar.visible = true
          @chatCount = 0

        @addEventListener 'chatbar.off', =>
          @$.chatbar.visible = false

Screensharing, this asks for a screen to share and adds it to the room.

        @addEventListener 'screenshare', =>
          getScreenMedia (err, screen) =>
            console.log 'screen', err, screen
##Call Tracking

Keeps track of all your calls, and forwards them to all connected call
peers in order to support auto-conference.

        callOverlap = (a, b) ->
          a.fromclientid is b.fromclientid and a.toclientid is b.toclientid

        takeCall = (newCall) =>
          if _.any(@calls, (call) -> callOverlap(call, newCall))
            console.log 'already connected'
          else
            newCall.config = @serverConfig
            console.log 'new call', newCall
            @calls.push newCall

        @signallingServer.on 'outboundcall', takeCall

        @signallingServer.on 'inboundcall', takeCall

When the room list changes, place calls. This uses a simply bully algorithm
where the larger client id is in charge of actually making the call.

        @signallingServer.on 'roomlist', (clientids) =>
          for clientid in clientids
            console.log 'call?', clientid
            if clientid < @signallingServer.clientid
              console.log 'call!', clientid
              @call clientid
          _.remove @calls, (call) ->
            call.fromclientid not in clientids or call.toclientid not in clientids

##Call Signal Processing

Relay signalling server messages into the calls.

        @addEventListener 'ice', (evt) =>
          evt.detail.nolog = true
          @signallingServer.send 'ice', evt.detail
        @signallingServer.on 'ice', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processIce detail

        @addEventListener 'offer', (evt) =>
          @signallingServer.send 'offer', evt.detail
        @signallingServer.on 'offer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processOffer detail

        @addEventListener 'answer', (evt) =>
          @signallingServer.send 'answer', evt.detail
        @signallingServer.on 'answer', (detail) =>
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.processAnswer detail

        @addEventListener 'call', (evt) =>
          @call evt.detail.to
        window.debugFailCall = =>
          @call 'fail'

##Chat

Hook up chat message processing, most important thing is to attach your local
user identity to messages as they are posted. This will send messages as they
are posted to the connected WebRTC calls on the page so everyone gets a chat.

        @$.chat.addEventListener 'message', (evt) =>
          evt.stopPropagation()
          message =
            who: @nametag
            what: evt.detail.what
            when: evt.detail.when
          evt.detail.callback undefined, message
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'message', message

        @addEventListener 'message', (evt) =>
          evt.detail.when = new Date()
          @$.chat.addMessage evt.detail
          @chatCount++ unless @$.chatbar.visible

        @$.chat.addEventListener 'chunk', (evt) =>
          evt.detail.callback undefined, 0, 0, []

        @$.chat.addEventListener 'typing', _.debounce =>
          message =
            who: @nametag
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'typing', message
        , 1000, leading: true

        @addEventListener 'typing', (evt) =>
          @$.chat.typerName = evt?.detail?.who

        @$.chat.addEventListener 'not-typing', =>
          message =
            who: @nametag
          _.each @shadowRoot.querySelectorAll('ui-video-call'), (call) ->
            call.send 'not-typing', message

        @addEventListener 'not-typing', (evt) =>
          @$.chat.typerName = ""

