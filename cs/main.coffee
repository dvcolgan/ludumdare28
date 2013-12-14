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
            ['AnimationActionComponent', {name: 'walk-right', row: 0, indices: [0,0,0,1,2,2,2,1], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'walk-left',  row: 1, indices: [0,0,0,1,2,2,2,1], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'walk-down',  row: 2, indices: [0,0,0,1,2,2,2,1], frameLength: 100 }]
            ['AnimationActionComponent', {name: 'walk-up',    row: 3, indices: [0,0,0,1,2,2,2,1], frameLength: 100 }]
        ])

        camera = @entityManager.createEntityWithComponents([
            ['CameraComponent', {}]
            ['PixelPositionComponent', { x: 0, y: 0 }]
        ])

        scoreEntity = @entityManager.createEntityWithComponents([
            ['ScoreComponent', { score: 0 }]
            ['AcornsLeftComponent', { amount: 0 }]
        ])

        @loadLevel('level1.json')

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
        

    loadLevel: (tileDataUrl) ->

        # Clear out old layers
        oldLayers = []
        for [layerEntity, _] in @entityManager.iterateEntitiesAndComponents(['TilemapVisibleLayerComponent'])
            oldLayers.push(layerEntity)
        for [collisionEntity, _] in @entityManager.iterateEntitiesAndComponents(['TilemapCollisionLayerComponent'])
            oldLayers.push(collisionEntity)
        for entity in oldLayers
            @entityManager.removeEntity(entity)

        # Set up map
        mapData = @assetManager.assets[tileDataUrl]

        background = mapData.layers[0]
        objects = mapData.layers[1]

        backgroundLayer = @entityManager.createEntityWithComponents([
            ['TilemapVisibleLayerComponent', { tileData: background, tileImageUrl: 'tiles.png', tileWidth: 64, tileHeight: 64, zIndex: 0 }]
        ])
        objectsLayer = @entityManager.createEntityWithComponents([
            ['TilemapVisibleLayerComponent', { tileData: objects, tileImageUrl: 'tiles.png', tileWidth: 64, tileHeight: 64, zIndex: 1 }]
        ])
        collisionLayer = @entityManager.createEntityWithComponents([
            ['TilemapCollisionLayerComponent', { tileData: objects }]
        ])

        # Position the player
        [player, _, playerPixelPosition, playerGridPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'PixelPositionComponent', 'GridPositionComponent'])
        playerGridPosition.col = 9
        playerGridPosition.row = 11
        playerPixelPosition.col = 9 * Game.GRID_SIZE
        playerPixelPosition.row = 11 * Game.GRID_SIZE

        # Set up acorns
        [_, acornsLeft] = @entityManager.getFirstEntityAndComponents(['AcornsLeftComponent'])
        acornsLeft.amount = 0
        for tile, idx in objects.data
            if tile == 0
                col = (idx % objects.width)
                row = Math.floor(idx / objects.width)
                acorn = @entityManager.createEntityWithComponents([
                    ['AcornComponent', {}]
                    ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
                    ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
                    ['StaticSpriteComponent', { spriteUrl: 'acorn.png' }]
                    ['EyeHavingComponent', { offsetMax: 4, targetEntity: player, eyesImageUrl: 'acorn-eyes.png' }]
                ])
                acornsLeft.amount++
                


    step: (delta, time) ->
        @gridMovementSystem.update(delta, time)
        @tweenSystem.update(delta, time)
        @randomInputSystem.update(delta, time)
        @acornSystem.update(delta, time)
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
    @SCREEN_HEIGHT: 640
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
        @assetManager.loadTilemap('level1.json')
        @assetManager.loadTilemap('level2.json')
        @assetManager.loadTilemap('level3.json')

        @assetManager.start =>
            @states.push(new OverworldState(@cq, @assetManager))
            @states[0].start()

    pushState: (state) ->
        @states.push(state)

    popState: ->
        @states.pop()


window.game = new Game()
