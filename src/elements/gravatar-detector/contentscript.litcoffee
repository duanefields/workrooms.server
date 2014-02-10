This is a content script that will detect and augment gravatars
with video calls.

    MutationSummary = require('../../../vendor/mutation-summary.js')
    urlparse = require('urlparse')
    bonzo = require('bonzo')
    qwery = require('qwery')
    _ = require('lodash')

    gravatarRegex = new RegExp('gravatar')

Keep a hash of debounced functions to ask the server if users are online.
Hash this by user.

    isOnlineSignals = {}

If a user is online, do the HTML injection. The idea here is to make the
minimum amount of injection possible to avoid breaking pages.

    chrome.runtime.onMessage.addListener (message, sender, respond) ->
      if message.type is 'online'
        isOnlineSignals[message.detail.gravatar]?.show(message.detail)

    processImageForGravatar = (img) ->
      if img?.src?.match(gravatarRegex)

Try to capture the original styling and then build up a similarly styled
replacement.

        gravatarToCall = urlparse(img.src).path.split('/')?[2]

Ask the server if this users is online, with the debounce to not be
a chatterbox in particular on pages like commits where a user will be
listed multiple times.

        if not isOnlineSignals[gravatarToCall]
          isOnlineSignals[gravatarToCall] = _.debounce ->
            chrome.runtime.sendMessage
              type: 'isonline'
              detail:
                gravatar: gravatarToCall
          , 300
          isOnlineSignals[gravatarToCall].images = []
          isOnlineSignals[gravatarToCall].show = (detail) ->
            _.each isOnlineSignals[gravatarToCall].images, (img) -> gravatarImageOnline(img, detail)
        isOnlineSignals[gravatarToCall].images.push img
        isOnlineSignals[gravatarToCall]()

Jam in a replacement element to take over the gravatar with the link.

    gravatarImageOnline = (img, detail) ->
      marginRight = getComputedStyle(img)['margin-right']
      marginLeft = getComputedStyle(img)['margin-left']
      marginTop = getComputedStyle(img)['margin-top']
      float = getComputedStyle(img)['float']
      display = getComputedStyle(img)['display']
      html = img.outerHTML
      img = bonzo(img)
      parent = img.parent()
      if parent.length and not parent.hasClass('callable')
        img.addClass('gravatar')
        elem = img.replaceWith("""
        <span class="callable" style="display: #{display}; margin-right: #{marginRight}; margin-top: #{marginTop}; margin-left: #{marginLeft}; float: #{float};">
          #{html}
          <i class="fa fa-video-camera video-call"></i>
        </span>
        """)

Here is the result, sending a message to `call` with a `gravatar` id, this
is the *click to dial*.

        parent[0].querySelector('.video-call').addEventListener 'click', (evt) ->
          evt.preventDefault()
          chrome.runtime.sendMessage
            type: 'call'
            detail:
              to: detail.sessionid
          chrome.runtime.sendMessage
            showConferenceTab: true

Now, look all through the document for all images and process em!

    qwery('img').forEach processImageForGravatar
    observer = new MutationSummary
      callback: (summaries) ->
        summaries.forEach (summary) ->
          summary.added?.forEach processImageForGravatar
          summary.attributeChanged?.src?.forEach processImageForGravatar
      queries: [
        {element: 'img', elementAttributes: 'src'}
      ]
