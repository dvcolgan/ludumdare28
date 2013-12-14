class GameState
    constructor: (@cq, @assetManager) ->
        @eventManager = new EventManager()
        @entityManager = new EntityManager(window.components)

        @create()


    start: ->
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


class OverworldState extends GameState

    create: ->
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
            ['CameraFollowsComponent', {}]
            ['AnimationComponent', { currentAction: 'idle-right', spritesheetUrl: 'squirrel.png', frameWidth: 112, frameHeight: 112, offsetX: 24, offsetY: 48 }]
            ['AnimationActionComponent', {name: 'idle-right', row: 0, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-left',  row: 1, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-down',  row: 2, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'idle-up',    row: 3, indices: [0], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'walk-right', row: 0, indices: [0,0,0,1,2,2,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-left',  row: 1, indices: [0,0,0,1,2,2,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-down',  row: 2, indices: [0,0,0,1,2,2,2,1], frameLength: 50 }]
            ['AnimationActionComponent', {name: 'walk-up',    row: 3, indices: [0,0,0,1,2,2,2,1], frameLength: 50 }]
        ])

        camera = @entityManager.createEntityWithComponents([
            ['CameraComponent', {}]
            ['PixelPositionComponent', { x: 0, y: 0 }]
        ])

        #npc = @entityManager.createEntityWithComponents([
        #    ['PlayerComponent', {}]
        #    ['PixelPositionComponent', { x: 256, y: 256 }]
        #    ['GridPositionComponent', { col: 3, row: 3, gridSize: Game.GRID_SIZE }]
        #    ['DirectionComponent', { direction: 'right'}]
        #    ['ActionInputComponent', {}]
        #    ['RandomArrowsInputComponent', {}]
        #    ['ColorComponent', { color: 'blue' }]
        #    ['ShapeRendererComponent', { width: Game.GRID_SIZE, height: Game.GRID_SIZE, type: 'rectangle' }]
        #    ['GridMovementComponent', { speed: 0.2 }]
        #    ['CollidableComponent', {}]
        #    ['AnimationComponent', { currentAction: 'idle-right', spritesheetUrl: 'squirrel.png', frameWidth: 112, frameHeight: 112, offsetX: 24, offsetY: 24 }]
        #    ['AnimationActionComponent', {name: 'idle-right', row: 0, indices: [0], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'idle-left',  row: 1, indices: [0], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'idle-down',  row: 2, indices: [0], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'idle-up',    row: 3, indices: [0], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'walk-right', row: 0, indices: [0,1,2,1], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'walk-left',  row: 1, indices: [0,1,2,1], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'walk-down',  row: 2, indices: [0,1,2,1], frameLength: 100 }]
        #    ['AnimationActionComponent', {name: 'walk-up',    row: 3, indices: [0,1,2,1], frameLength: 100 }]
        #])

        mapData = @assetManager.assets['sad-forest.json']

        background = mapData.layers[0]
        objects = mapData.layers[1]
        collision = mapData.layers[2]

        backgroundLayer = @entityManager.createEntityWithComponents([
            ['TilemapVisibleLayerComponent', { tileData: background, tileImageUrl: 'tiles.png', tileWidth: 64, tileHeight: 64, zIndex: 0 }]
        ])
        objectsLayer = @entityManager.createEntityWithComponents([
            ['TilemapVisibleLayerComponent', { tileData: objects, tileImageUrl: 'tiles.png', tileWidth: 64, tileHeight: 64, zIndex: 1 }]
        ])
        collisionLayer = @entityManager.createEntityWithComponents([
            ['TilemapCollisionLayerComponent', { tileData: objects }]
        ])

        for tile, idx in objects.data
            if tile == 0
                col = (idx % objects.width)
                row = Math.floor(idx / objects.width)
                acorn = @entityManager.createEntityWithComponents([
                    ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
                    ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
                    ['PickUpAbleComponent', {}]
                    ['StaticSpriteComponent', { spriteUrl: 'acorn.png' }]
                    ['EyeHavingComponent', { offsetMax: 4, targetEntity: player, eyesImageUrl: 'acorn-eyes.png' }]
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

    step: (delta, time) ->
        @gridMovementSystem.update(delta, time)
        @tweenSystem.update(delta, time)
        @randomInputSystem.update(delta, time)
        @animatedSpriteSystem.update(delta, time)
        @animationDirectionSyncSystem.update(delta, time)
        @cameraFollowingSystem.update(delta, time)

    render: (delta, time) ->
        @cq.clear('white')
        @tilemapRenderingSystem.draw()
        @shapeRenderSystem.draw()
        @staticSpriteRenderSystem.draw()
        @eyeFollowingSystem.draw()
        @animatedSpriteSystem.draw()

    keyUp: (key) ->
        @inputSystem.updateKey(key, off)

    keyDown: (key) ->
        @inputSystem.updateKey(key, on)


class Game
    @SCREEN_WIDTH: 640
    @SCREEN_HEIGHT: 576
    @GRID_SIZE: 64

    constructor: ->
        @states = []
        @cq = cq(Game.SCREEN_WIDTH, Game.SCREEN_HEIGHT).appendTo('body')
        @assetManager = new AssetManager()

        @assetManager.loadImage('tiles.png')
        @assetManager.loadImage('squirrel.png')
        @assetManager.loadImage('acorn.png')
        @assetManager.loadImage('acorn-eyes.png')
        @assetManager.loadTilemap('sad-forest.json')

        @assetManager.start =>
            @states.push(new OverworldState(@cq, @assetManager))
            @states[0].start()

    pushState: (state) ->
        @states.push(state)

    popState: ->
        @states.pop()


window.game = new Game()
