class AssetManager
    constructor: ->
        @imagesPrefix = 'images/'
        @tilemapsPrefix = 'levels/'
        @audiosPrefix = 'audio/'
        @imagesToLoad = []
        @tilemapsToLoad = []
        @soundEffectsToLoad = []
        @bgmsToLoad = []
        @assets = {}
        @remaining = 0

    loadImage: (url) ->
        @imagesToLoad.push(url)

    loadTilemap: (url) ->
        @tilemapsToLoad.push(url)

    loadSoundEffect: (url) ->
        @soundEffectsToLoad.push(url)
    loadBGM: (url) ->
        @bgmsToLoad.push(url)

    start: (callback) ->
        for tilemapUrl in @tilemapsToLoad
            ((tilemapUrl) =>
                xhr = new XMLHttpRequest()
                xhr.open('GET', @tilemapsPrefix + tilemapUrl, true)
                xhr.url = tilemapUrl
                @remaining++
                xhr.onreadystatechange = =>
                    if xhr.readyState == 4
                        @assets[xhr.url] = JSON.parse(xhr.response)
                        @remaining--
                        if @remaining == 0
                            callback()
                xhr.send()
            )(tilemapUrl)

        for imgUrl in @imagesToLoad
            img = new Image()
            img.src = @imagesPrefix + imgUrl
            @remaining++
            img.onload = =>
                console.log 'loaded image'
                @remaining--
                if @remaining == 0
                    callback()
            @assets[imgUrl] = img

            #for audioUrl in @audiosToLoad
            #for audio = new Audio()
            #for audio.addEventListener('canplaythrough', (=>
            #for     console.log 'loaded audio'
            #for     @remaining--
            #for     if @remaining == 0
            #for         callback()
            #for ), false)
            #for audio.src = @audiosPrefix + audioUrl
            #for @remaining++
            #for @assets[audioUrl] = audio
        
        for bgmUrl in @bgmsToLoad
            @remaining++
            window.soundManager.createSound
                volume: 100
                autoLoad: true
                loops: 10000
                id: bgmUrl
                url: @audiosPrefix + bgmUrl
                onload: =>
                    console.log 'loaded audio'
                    @remaining--
                    if @remaining == 0
                        callback()

        for soundEffectUrl in @soundEffectsToLoad
            @remaining++
            window.soundManager.createSound
                volume: 100
                autoLoad: true
                multiShot: true
                id: soundEffectUrl
                url: @audiosPrefix + soundEffectUrl
                onload: =>
                    console.log 'loaded audio'
                    @remaining--
                    if @remaining == 0
                        callback()

        if Object.keys(@assets).length == 0 then callback()


