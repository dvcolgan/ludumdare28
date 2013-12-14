class GameState
    constructor: ->
        @assetManager = new AssetManager()

        @loadAssets()

        @assetManager.start =>
            @eventManager = new EventManager()
            @entityManager = new EntityManager(window.components)

            @create()


    start: (@cq) ->
        @cq.framework
            onstep: (delta, time) =>
                @step(delta, time)

            onrender: (delta, time) =>
                @render(delta, time)
                
            onkeydown: (key) =>
                @keyDown(key)

            onkeyup: (key) =>
                @keyUp(key)

    loadAssets: ->
    create: ->
    step: (delta, time) ->
    render: (delta, time) ->
    keyUp: (key) ->
    keyDown: (key) ->


class Game
    @SCREEN_WIDTH: 320
    @SCREEN_HEIGHT: 288
    @GRID_SIZE: 32
    @states = []

    constructor: ->
        @cq = cq(Game.SCREEN_WIDTH, Game.SCREEN_HEIGHT).appendTo('.gameboy')
        @states.push(new TitleScreenState())

    pushState: (state) ->
        @states.push(state)

    popState: ->
        @states.pop()


window.game = new Game()
