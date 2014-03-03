Maintain a dynamic extension icon with here, this draws the chrome extension
icon rather than just using an image. This way is it possible to draw with
web tech, not using a graphics program.

#Attributes
##size
Pixels, as an integer.

* TODO: use the tiny avatar instead of the icon?
* TODO: hook up badges to indicate the number of folks in your conference

    Polymer 'extension-icon',
      size: 19
      attached: ->
        console.log 'hi icon'

Of course, chrome events don't follow the pattern for dom elements...

        chrome.browserAction.onClicked.addListener =>
          @fire 'showconferencetab'

This is a fun one. This is an invisible element for sure, but unless the
canvas is 'in the DOM' -- `attached` in Polymer parlance, the `fillText`
ends up always using a *1px* font, no matter what you tell it.

      drawIcon: (calls) ->
        canvas = @$.extensionIcon
        context = canvas.getContext('2d')
        context.clearRect(0, 0, @size, @size)
        context.font = "#{@size-2}px FontAwesome"
        context.textBaseline = "top"
        context.fillStyle = "rgba(0, 0, 0, 0.5)"
        context.strokeStyle = "rgba(0, 0, 0, 0.3)"
        context.fillText(String.fromCharCode(0xf0c0), 1, 1)
        image = context.getImageData(0, 0, @size, @size)
        chrome.browserAction.setIcon imageData: image
        chrome.browserAction.setBadgeText
          text: "#{calls?.length or ''}"


