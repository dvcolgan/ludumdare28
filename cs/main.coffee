class GameState
    constructor: (@cq, @assetManager, args) ->
        @eventManager = new EventManager()
        @entityManager = new EntityManager(window.components)
        @create(args)

    loadAssets: ->
    create: (args) ->
    start: ->
    step: (delta, time) ->
    render: (delta, time) ->
    keyUp: (key) ->
    keyDown: (key) ->

class TitleScreenState extends GameState
    create: (args) ->
        background = @entityManager.createEntityWithComponents([
            ['PixelPositionComponent', { x: 0, y: 0 }]
            ['StaticSpriteComponent', { spriteUrl: 'title-screen.png' }]
        ])
        camera = @entityManager.createEntityWithComponents([
            ['CameraComponent', {}]
            ['PixelPositionComponent', { x: 0, y: 0 }]
        ])
        @staticSpriteRenderSystem = new StaticSpriteRenderSystem(@cq, @entityManager, @eventManager, @assetManager)

    render: (delta, time) ->
        @staticSpriteRenderSystem.draw()

    keyUp: (key) ->
        if key == 'space'
            game.pushState(PlayState, {})



class PlayState extends GameState

    create: (args) ->
        col = 5
        row = 5
        player = @entityManager.createEntityWithComponents([
            ['PlayerComponent', {}]
            ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
            ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
            ['DirectionComponent', { direction: 'right'}]
            ['ActionInputComponent', {}]
            ['KeyboardArrowsInputComponent', {}]
            ['ColorComponent', { color: 'red' }]
            #['ShapeRendererComponent', { width: Game.GRID_SIZE, height: Game.GRID_SIZE, type: 'rectangle' }]
            ['GridMovementComponent', { speed: 0.4 }]
            ['CollidableComponent', {}]
            ['AnimationComponent', { currentAction: 'idle-right', spritesheetUrl: 'squirrel.png', frameWidth: 112, frameHeight: 112, offsetX: 24, offsetY: 48 }]
            ['AnimationActionComponent', {name: 'idle-right', row: 0, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-left',  row: 1, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-down',  row: 2, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-up',    row: 3, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'walk-right', row: 0, indices: [0,1,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-left',  row: 1, indices: [0,1,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-down',  row: 2, indices: [0,1,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-up',    row: 3, indices: [0,1,2,1], frameLength: 50 }]
            ['CameraFollowsComponent', {}]
        ])

        camera = @entityManager.createEntityWithComponents([
            ['CameraComponent', {}]
            ['PixelPositionComponent', { x: 0, y: 0 }]
        ])

        scoreEntity = @entityManager.createEntityWithComponents([
            ['ScoreComponent', { score: 0 }]
            ['AcornsLeftComponent', { amount: 0 }]
            ['LivesComponent', { lives: 3 }]
            ['CurrentLevelComponent', { level: 0 }]
        ])

        @gridMovementSystem = new GridMovementSystem(@cq, @entityManager, @eventManager, @assetManager)
        @tweenSystem = new TweenSystem(@cq, @entityManager, @eventManager, @assetManager)
        @shapeRenderSystem = new ShapeRenderSystem(@cq, @entityManager, @eventManager, @assetManager)
        @inputSystem = new InputSystem(@cq, @entityManager, @eventManager, @assetManager)
        @cameraFollowingSystem = new CameraFollowingSystem(@cq, @entityManager, @eventManager, @assetManager)
        @randomInputSystem = new RandomInputSystem(@cq, @entityManager, @eventManager, @assetManager)
        @tilemapRenderingSystem = new TilemapRenderingSystem(@cq, @entityManager, @eventManager, @assetManager)
        @animationDirectionSyncSystem = new AnimationDirectionSyncSystem(@cq, @entityManager, @eventManager, @assetManager)
        @animatedSpriteSystem = new AnimatedSpriteSystem(@cq, @entityManager, @eventManager, @assetManager)
        @staticSpriteRenderSystem = new StaticSpriteRenderSystem(@cq, @entityManager, @eventManager, @assetManager)
        @eyeFollowingSystem = new EyeFollowingSystem(@cq, @entityManager, @eventManager, @assetManager)
        @acornSystem = new AcornSystem(@cq, @entityManager, @eventManager, @assetManager)
        @astarInputSystem = new AstarInputSystem(@cq, @entityManager, @eventManager, @assetManager)
        @scoreRenderingSystem = new ScoreRenderingSystem(@cq, @entityManager, @eventManager, @assetManager)
        @enemyDamageSystem = new EnemyDamageSystem(@cq, @entityManager, @eventManager, @assetManager)
        @levelLoaderSystem = new LevelLoaderSystem(@cq, @entityManager, @eventManager, @assetManager)


        @eventManager.trigger('next-level', player)


    step: (delta, time) ->
        @eventManager.pump()
        @astarInputSystem.update(delta, time)
        @gridMovementSystem.update(delta, time)
        @tweenSystem.update(delta, time)
        @randomInputSystem.update(delta, time)
        @acornSystem.update(delta, time)
        @animatedSpriteSystem.update(delta, time)
        @animationDirectionSyncSystem.update(delta, time)
        @cameraFollowingSystem.update(delta, time)
        @enemyDamageSystem.update(delta, time)

    render: (delta, time) ->
        @cq.clear('white')
        @tilemapRenderingSystem.draw()
        @shapeRenderSystem.draw()
        @staticSpriteRenderSystem.draw()
        @eyeFollowingSystem.draw()
        @animatedSpriteSystem.draw()
        @scoreRenderingSystem.draw()

    keyUp: (key) ->
        @inputSystem.updateKey(key, off)

    keyDown: (key) ->
        @inputSystem.updateKey(key, on)


class GameOverScreenState extends GameState
    create: (args) ->
        background = @entityManager.createEntityWithComponents([
            ['PixelPositionComponent', { x: 0, y: 0 }]
            ['StaticSpriteComponent', { spriteUrl: 'game-over-screen.png' }]
        ])
        camera = @entityManager.createEntityWithComponents([
            ['CameraComponent', {}]
            ['PixelPositionComponent', { x: 0, y: 0 }]
        ])
        @score = args.finalScore

        @staticSpriteRenderSystem = new StaticSpriteRenderSystem(@cq, @entityManager, @eventManager, @assetManager)

    render: (delta, time) ->
        @cq.font('102px "Merienda One"').textAlign('center').textBaseline('top').fillStyle('black')
        @staticSpriteRenderSystem.draw()
        @cq.fillText(@score, Game.SCREEN_WIDTH/2, 86)

    keyUp: (key) ->
        if key == 'space'
            game.popState()
            game.popState()
            game.pushState(PlayState, {})


class Game
    @SCREEN_WIDTH: 640
    @SCREEN_HEIGHT: 640
    @GRID_SIZE: 64

    constructor: ->
        @cq = cq(Game.SCREEN_WIDTH, Game.SCREEN_HEIGHT).appendTo('body')
        @states = []
        @currentState = null
        @assetManager = new AssetManager()

        @assetManager.loadImage('tiles.png')
        @assetManager.loadImage('squirrel.png')
        @assetManager.loadImage('acorn.png')
        @assetManager.loadImage('acorn-eyes.png')
        @assetManager.loadImage('fire.png')
        @assetManager.loadImage('dog.png')
        @assetManager.loadImage('title-screen.png')
        @assetManager.loadImage('game-over-screen.png')
        @assetManager.loadTilemap('level1.json')
        @assetManager.loadTilemap('level2.json')
        @assetManager.loadTilemap('level3.json')
        @assetManager.loadTilemap('testlevel.json')

        @assetManager.start =>
            @pushState(TitleScreenState)

            @cq.framework
                onstep: (delta, time) =>
                    if @currentState
                        @currentState.step(delta, time)

                onrender: (delta, time) =>
                    if @currentState
                        @currentState.render(delta, time)
                    
                onkeydown: (key) =>
                    if @currentState
                        @currentState.keyDown(key)

                onkeyup: (key) =>
                    if @currentState
                        @currentState.keyUp(key)

    pushState: (stateClass, args) ->
        state = new stateClass(@cq, @assetManager, args)
        @states.push(state)
        @currentState = state
        state.start(args)

    popState: (args) ->
        if @states.length > 1
            @states.pop()
            prevState = @states[@states.length-1]
            @currentState = prevState
            prevState.start(args)
        else
            throw "Can't pop last state!"


window.game = new Game()
