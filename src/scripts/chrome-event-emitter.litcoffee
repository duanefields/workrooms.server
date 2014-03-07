This is a simple `EventEmitter` bridge in to chrome, with a notion
of channels. You make this with a named channel.

    EventEmitter = require('events').EventEmitter
    module.exports = 
      class ChromeEventEmitter extends EventEmitter
        constructor: (@channel) ->
          chrome.runtime.onMessage.addListener (message, sender, respond) =>
            if message.channel is @channel
              @emit message.type, message.detail

Send a `name` message with object `detail` over chrome messaging on this
channel.

        send: (name, detail, toAllTabs) ->
          @emit name, detail
          console.log @channel, name, detail
          if toAllTabs
            chrome.tabs.query {}, (tabs) =>
              tabs.forEach (tab) =>
                chrome.tabs.sendMessage tab.id,
                  channel: @channel
                  type: name
                  detail: detail
          else
            chrome.runtime.sendMessage
              channel: @channel
              type: name
              detail: detail
