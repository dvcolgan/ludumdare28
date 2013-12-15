class System
    constructor: (@cq, @entityManager, @eventManager, @assetManager) ->


class GridMovementSystem extends System
    update: (delta) ->
        for [entity, movement, direction, input, gridPosition, pixelPosition] in @entityManager.iterateEntitiesAndComponents(['GridMovementComponent', 'DirectionComponent', 'ActionInputComponent', 'GridPositionComponent', 'PixelPositionComponent'])
            if not input.enabled then continue

            tweens = @entityManager.getComponents(entity, 'TweenComponent')
            movement.isMoving = no
            for tween in tweens
                if tween.component == pixelPosition
                    movement.isMoving = yes
                    break
            if not movement.isMoving
                newCol = Math.round(pixelPosition.x / gridPosition.gridSize)
                newRow = Math.round(pixelPosition.y / gridPosition.gridSize)
                if newCol != gridPosition.col or newRow != gridPosition.row
                    gridPosition.col = newCol
                    gridPosition.row = newRow
                    gridPosition.justEntered = yes
                else
                    gridPosition.justEntered = no

                dx = dy = 0
                if input.left then dx -= 1
                if input.right then dx += 1
                if dx == 0
                    if input.up then dy -= 1
                    if input.down then dy += 1
                if dx != 0 or dy != 0
                    if dx < 0 then direction.direction = 'left'
                    if dx > 0 then direction.direction = 'right'
                    if dy < 0 then direction.direction = 'up'
                    if dy > 0 then direction.direction = 'down'

                    for [__, collisionLayer] in @entityManager.iterateEntitiesAndComponents(['TilemapCollisionLayerComponent'])
                        tileIdx = (gridPosition.row+dy) * collisionLayer.tileData.width + (gridPosition.col+dx)
                        nextTile = collisionLayer.tileData.data[tileIdx]
                        if nextTile == 0
                            #canMove = true
                            #for [__, otherGridPosition, _] in @entityManager.iterateEntitiesAndComponents(['GridPositionComponent', 'CollidableComponent'])
                            #    if (gridPosition.col+dx) == otherGridPosition.col and (gridPosition.row+dy) == otherGridPosition.row
                            #        canMove = false
                            #if canMove
                            if dx > 0 or dx < 0
                                #pixelPosition.x += gridPosition.gridSize * dx
                                @entityManager.addComponent(entity, 'TweenComponent', {
                                    speed: movement.speed,
                                    start: pixelPosition.x, dest: pixelPosition.x + gridPosition.gridSize * dx,
                                    component: pixelPosition, attr: 'x', easingFn: 'linear'
                                })
                            if dy > 0 or dy < 0
                                #pixelPosition.y += gridPosition.gridSize * dy
                                @entityManager.addComponent(entity, 'TweenComponent', {
                                    speed: movement.speed,
                                    start: pixelPosition.y, dest: pixelPosition.y + gridPosition.gridSize * dy,
                                    component: pixelPosition, attr: 'y', easingFn: 'linear'
                                })
                            ((entity) =>
                                @eventManager.subscribeOnce 'tween-end', entity, =>
                                    @eventManager.trigger('movement-enter-square', entity, { col: gridPosition.col, row: gridPosition.row })
                            )(entity)


class TweenSystem extends System
    # PSEUDO CODE
    update: (delta) ->
        for [entity, tween] in @entityManager.iterateEntitiesAndComponents(['TweenComponent'])
            if tween.start == tween.dest
                @entityManager.removeComponent(entity, tween)

            if tween.current == null then tween.current = tween.start

            dir = if tween.start < tween.dest then 1 else -1

            if tween.easingFn == 'linear'
                tween.current += delta * tween.speed * dir
            else if tween.easingFn == 'ease-out-bounce'
                t = Math.abs(tween.current / tween.dest)
                c = delta * tween.speed * dir
                b = tween.start
                if t < (1/2.75)
                    tween.current = c*(7.5625*t*t) + b
                else if t < (2/2.75)
                    tween.current = c*(7.5625*(t-=(1.5/2.75))*t + .75) + b
                else if t < (2.5/2.75)
                    tween.current = c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b
                else
                    tween.current = c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b

            tween.component[tween.attr] = tween.current
            # TODO what happens if you add a tween that has the same start and dest?

            if (tween.start < tween.dest and tween.current > tween.dest) or (tween.start >= tween.dest and tween.current < tween.dest)
                tween.component[tween.attr] = tween.dest
                @entityManager.removeComponent(entity, tween)
                @eventManager.trigger('tween-end', entity, {})



class ShapeRenderSystem extends System

    draw: ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        for [entity, position, color, shape, direction] in @entityManager.iterateEntitiesAndComponents(['PixelPositionComponent', 'ColorComponent', 'ShapeRendererComponent', 'DirectionComponent'])
            @cq.fillStyle(color.color)
            if shape.type == 'rectangle'
                @cq.fillRect(position.x - cameraPosition.x, position.y - cameraPosition.y, shape.width, shape.height)
                @cq.beginPath()
                fromX = position.x + shape.width / 2
                fromY = position.y + shape.height / 2
                fromX -= cameraPosition.x
                fromY -= cameraPosition.y
                @cq.moveTo(fromX, fromY)
                toX = fromX
                toY = fromY
                switch direction.direction
                    when 'left'  then toX -= shape.width / 2
                    when 'right' then toX += shape.width / 2
                    when 'up'    then toY -= shape.width / 2
                    when 'down'  then toY += shape.width / 2
                @cq.lineTo(toX, toY)
                @cq.lineWidth = 4
                @cq.strokeStyle = 'black'
                @cq.lineCap = 'round'
                @cq.stroke()
            else
                throw 'NotImplementedException'


class InputSystem extends System
    updateKey: (key, value) ->
        for [entity, __, input] in @entityManager.iterateEntitiesAndComponents(['KeyboardArrowsInputComponent', 'ActionInputComponent'])
            if input.enabled or value == off
                if value == off
                    if key == 'left' or key == 'a' then input.left = off
                    if key == 'right' or key == 'd' or key == 'e' then input.right = off
                    if key == 'up' or key == 'w' or key == 'comma' then input.up = off
                    if key == 'down' or key == 's' or key == 'o'  then input.down = off
                    #if key == 'z' or key == 'semicolon' then input.action = off
                    #if key == 'x' or key == 'q'     then input.cancel = off
                else
                    # TODO MAKE A COFFEESCRIPT PRECOMPILER
                    #{% for dir in ['left', 'right', 'up', 'down'] %}
                    #    if key == '{{ dir }}' then if input.{{ dir }} == 'hit' then input.{{ dir }} = 'held' else input.{{ dir }} = 'hit'

                    if key == 'left' or key == 'a'
                        if input.left  == 'hit' then input.left  = 'held' else input.left  = 'hit'
                    if key == 'right' or key == 'd' or key == 'e'
                        if input.right == 'hit' then input.right = 'held' else input.right = 'hit'
                    if key == 'up' or key == 'w' or key == 'comma'
                        if input.up    == 'hit' then input.up    = 'held' else input.up    = 'hit'
                    if key == 'down' or key == 's' or key == 'o'
                        if input.down  == 'hit' then input.down  = 'held' else input.down  = 'hit'

                    #if key == 'z' or key == 'semicolon'
                    #    if input.action == 'hit' then input.action = 'held' else input.action = 'hit'
                    #if key == 'x' or key == 'q'
                    #    if input.cancel == 'hit' then input.cancel = 'held' else input.cancel = 'hit'

# TODO make this generic for any key using a nice hash table
class RandomInputSystem extends System
    update: (delta) ->
        for [entity, __, input] in @entityManager.iterateEntitiesAndComponents(['RandomArrowsInputComponent', 'ActionInputComponent'])
            input.left = input.right = input.up = input.down = false
            chance = 0.002
            if Math.random() < chance
                if input.left   == 'hit' then input.left   = 'held' else input.left   = 'hit'
            if Math.random() < chance
                if input.right  == 'hit' then input.right  = 'held' else input.right  = 'hit'
            if Math.random() < chance
                if input.up     == 'hit' then input.up     = 'held' else input.up     = 'hit'
            if Math.random() < chance
                if input.down   == 'hit' then input.down   = 'held' else input.down   = 'hit'
            if Math.random() < chance
                if input.action == 'hit' then input.action = 'held' else input.action = 'hit'
                



class AstarInputSystem extends System
    update: (delta) ->
        [player, __, playerPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent'])
        for [entity, __, __, input, enemyPosition] in @entityManager.iterateEntitiesAndComponents(['EnemyComponent', 'AstarInputComponent', 'ActionInputComponent', 'GridPositionComponent'])
            input.left = input.right = input.up = input.down = false

            if enemyPosition.justEntered

                [collisionEntity, collisionLayer] = @entityManager.getFirstEntityAndComponents(['TilemapCollisionLayerComponent'])

                tiles2D = _.groupBy collisionLayer.tileData.data, (tile, idx) ->
                    Math.floor(idx/collisionLayer.tileData.width)

                tiles2D = ([] for i in [0...collisionLayer.tileData.height])
                for tile, i in collisionLayer.tileData.data
                    weight = 0
                    if tile == 0 then weight = 1
                    tiles2D[i % collisionLayer.tileData.width][Math.floor(i / collisionLayer.tileData.height)] = weight

                graph = new Graph(tiles2D)

                start = graph.nodes[enemyPosition.col][enemyPosition.row]
                end = graph.nodes[playerPosition.col][playerPosition.row]
                result = astar.search(graph.nodes, start, end)
                if result.length > 0
                    first = result[0]
                    col = first.x
                    row = first.y

                    dx = col - enemyPosition.col
                    dy = row - enemyPosition.row

                    if dx < 0 then input.left = yes
                    if dx > 0 then input.right = yes
                    if dy < 0 then input.up = yes
                    if dy > 0 then input.down = yes



class MovementSystem extends System
    update: (delta) ->
        for [entity, position, velocity, input] in @entityManager.iterateEntitiesAndComponents(['PixelPositionComponent', 'VelocityComponent', 'ActionInputComponent'])
            velocity.dx = velocity.dy = 0
            if input.left then velocity.dx -= velocity.maxSpeed * delta
            if input.right then velocity.dx += velocity.maxSpeed * delta
            if input.up then velocity.dy -= velocity.maxSpeed * delta
            if input.down then velocity.dy += velocity.maxSpeed * delta

            position.x += velocity.dx
            position.y += velocity.dy


class CameraFollowingSystem extends System
    update: (delta) ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])
        [followee, __, followeePosition] = @entityManager.getFirstEntityAndComponents(['CameraFollowsComponent', 'PixelPositionComponent'])

        [mapLayer, mapLayerComponent] = @entityManager.getFirstEntityAndComponents(['TilemapVisibleLayerComponent'])

        if camera and followee and mapLayer

            mapWidth = mapLayerComponent.tileWidth * mapLayerComponent.tileData.width
            mapHeight = mapLayerComponent.tileHeight * mapLayerComponent.tileData.height

            targetX = followeePosition.x - (Game.SCREEN_WIDTH / 2)
            targetY = followeePosition.y - (Game.SCREEN_HEIGHT / 2)

            cameraPosition.x += (targetX - cameraPosition.x) * 0.1
            cameraPosition.y += (targetY - cameraPosition.y) * 0.1

            cameraPosition.x = cameraPosition.x.clamp(0, mapWidth - Game.SCREEN_WIDTH)
            cameraPosition.y = cameraPosition.y.clamp(0, mapHeight - Game.SCREEN_HEIGHT)


class TilemapRenderingSystem extends System

    draw: (delta) ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        entities = @entityManager.getEntitiesHavingComponent('TilemapVisibleLayerComponent')
        layers = []
        for entity in entities
            layers.push(@entityManager.getComponent(entity, 'TilemapVisibleLayerComponent'))

        layers.sort((a, b) -> a.zIndex - b.zIndex)

        for layer in layers
            tileImage = @assetManager.assets[layer.tileImageUrl]

            tileImageTilesWide = tileImage.width / layer.tileWidth
            tileImageTilesHigh = tileImage.height / layer.tileHeight

            startCol = Math.floor(cameraPosition.x/layer.tileWidth)
            startRow = Math.floor(cameraPosition.y/layer.tileHeight)

            endCol = startCol + Math.ceil(Game.SCREEN_WIDTH/layer.tileWidth)
            endRow = startRow + Math.ceil(Game.SCREEN_HEIGHT/layer.tileWidth)

            for row in [startRow..endRow]
                for col in [startCol..endCol]
                    tileIdx = row * layer.tileData.width + col
                    if col < layer.tileData.width and col >= 0 and row < layer.tileData.height and row >= 0

                        thisTile = layer.tileData.data[tileIdx] - 1
                        thisTileImageX = (thisTile % tileImageTilesWide) * layer.tileWidth
                        thisTileImageY = Math.floor(thisTile / tileImageTilesWide) * layer.tileHeight
                        screenX = Math.floor(col * layer.tileWidth - cameraPosition.x)
                        screenY = Math.floor(row * layer.tileHeight - cameraPosition.y)
                        @cq.drawImage(
                            tileImage,
                            thisTileImageX, thisTileImageY,
                            layer.tileWidth, layer.tileHeight,
                            screenX, screenY,
                            layer.tileWidth, layer.tileHeight
                        )


class DialogRenderingSystem extends System
    update: (delta) ->
        [playerEntity, __, playerGridPosition, playerDirection, playerInput] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent', 'DirectionComponent', 'ActionInputComponent'])
        if playerInput.enabled
            if playerInput.action == 'hit'
                for [otherEntity, otherDirection, otherGridPosition, ] in @entityManager.iterateEntitiesAndComponents(['DirectionComponent', 'GridPositionComponent'])
                    dx = if playerDirection.direction == 'left' then -1 else if playerDirection.direction == 'right' then 1 else 0
                    dy = if playerDirection.direction ==   'up' then -1 else if playerDirection.direction ==  'down' then 1 else 0
                    if otherGridPosition.col == playerGridPosition.col + dx and otherGridPosition.row == playerGridPosition.row + dy

                        # Found the other person we are talking to
                        if playerDirection.direction == 'left' then otherDirection.direction = 'right'
                        if playerDirection.direction == 'right' then otherDirection.direction = 'left'
                        if playerDirection.direction == 'up' then otherDirection.direction = 'down'
                        if playerDirection.direction == 'down' then otherDirection.direction = 'up'

                        playerInput.enabled = no
                        otherInput = @entityManager.getComponent(otherEntity, 'ActionInputComponent')
                        if otherInput then otherInput.enabled = no

                        [dialogBoxEntity, dialogBox, dialogInput] = @entityManager.getFirstEntityAndComponents(['DialogBoxComponent', 'ActionInputComponent'])
                        dialogBox.visible = true
                        dialogBox.talkee = otherEntity
                        dialogInput.enabled = yes
                        @assetManager.assets['audiotest.ogg'].play()
                        break
        else
            [dialogBoxEntity, dialogBox, dialogBoxText, dialogInput] = @entityManager.getFirstEntityAndComponents(['DialogBoxComponent', 'DialogBoxTextComponent', 'ActionInputComponent'])
            if dialogInput.action == 'hit'
                dialogInput.enabled = no
                dialogBox.visible = false
                [playerEntity, __, playerInput] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'ActionInputComponent'])
                playerInput.enabled = yes
                talkeeInput = @entityManager.getComponent(dialogBox.talkee, 'ActionInputComponent')
                if talkeeInput then talkeeInput.enabled = yes

            

    draw: (delta) ->
        [__, dialogBox, dialogBoxText] = @entityManager.getFirstEntityAndComponents(['DialogBoxComponent', 'DialogBoxTextComponent'])
        
        if dialogBox.visible
            @cq.font('16px "Press Start 2P"').textBaseline('top').fillStyle('black')

            image = @assetManager.assets['pokemon-dialog-box.png']
            @cq.drawImage(image, 0, Game.SCREEN_HEIGHT - image.height)

            for line, i in dialogBoxText.text.split('\n')
                @cq.fillText(line, 18, Game.SCREEN_HEIGHT - image.height + 22 + 20 * i)


class AnimationDirectionSyncSystem extends System
    update: (delta) ->
        for [animationEntity, animation, gridPosition, direction, movement] in @entityManager.iterateEntitiesAndComponents(['AnimationComponent', 'GridPositionComponent', 'DirectionComponent', 'GridMovementComponent'])
            if movement.isMoving
                animation.currentAction = 'walk-' + direction.direction
            else
                if not gridPosition.justEntered
                    animation.currentAction = 'idle-' + direction.direction




class AnimatedSpriteSystem extends System
    update: (delta) ->
        for [animationEntity, animation] in @entityManager.iterateEntitiesAndComponents(['AnimationComponent'])
            actions = @entityManager.getComponents(animationEntity, 'AnimationActionComponent')
            for action in actions
                if action.name == animation.currentAction
                    action.frameElapsedTime += delta
                    if action.frameElapsedTime > action.frameLength
                        action.frameElapsedTime = 0
                        action.currentFrame++
                        if action.currentFrame >= action.indices.length
                            action.currentFrame = 0
                    break

    draw: ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        for [animationEntity, animation, animationPosition] in @entityManager.iterateEntitiesAndComponents(['AnimationComponent', 'PixelPositionComponent'])

            actions = @entityManager.getComponents(animationEntity, 'AnimationActionComponent')
            for action in actions
                if action.name == animation.currentAction

                    imageX = action.indices[action.currentFrame] * animation.frameWidth
                    imageY = action.row * animation.frameHeight

                    screenX = Math.floor(animationPosition.x - cameraPosition.x)
                    screenY = Math.floor(animationPosition.y - cameraPosition.y)
                    @cq.drawImage(
                        @assetManager.assets[animation.spritesheetUrl],
                        imageX, imageY,
                        animation.frameWidth, animation.frameHeight,
                        screenX - animation.offsetX, screenY - animation.offsetY,
                        animation.frameWidth, animation.frameHeight,
                    )
                    break

class StaticSpriteRenderSystem extends System
    draw: ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        for [spriteEntity, sprite, position] in @entityManager.iterateEntitiesAndComponents(['StaticSpriteComponent', 'PixelPositionComponent'])
            screenX = Math.floor(position.x - cameraPosition.x)
            screenY = Math.floor(position.y - cameraPosition.y)
            @cq.drawImage(@assetManager.assets[sprite.spriteUrl], screenX, screenY)

class MultiStateStaticSpriteRenderSystem extends System
    draw: ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        for [spriteEntity, sprite, position] in @entityManager.iterateEntitiesAndComponents(['MultiStateSpriteComponent', 'PixelPositionComponent'])
            screenX = Math.floor(position.x - cameraPosition.x)
            screenY = Math.floor(position.y - cameraPosition.y)
            @cq.drawImage(
                @assetManager.assets[sprite.spriteUrl],
                sprite.currentFrame * sprite.frameWidth, 0,
                sprite.frameWidth, sprite.frameHeight,
                screenX, screenY,
                sprite.frameWidth, sprite.frameHeight
            )


class EyeFollowingSystem extends System
    draw: ->
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])
        for [eyeEntity, eyes, eyeHaverPosition] in @entityManager.iterateEntitiesAndComponents(['EyeHavingComponent', 'PixelPositionComponent'])
            #TODO cull the acorns offscreen
            targetPosition = @entityManager.getComponent(eyes.targetEntity, 'PixelPositionComponent')
            if targetPosition == null
                [player, targetPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'PixelPositionComponent'])
                eyes.targetEntity = player
            dx = targetPosition.x - eyeHaverPosition.x
            dy = targetPosition.y - eyeHaverPosition.y

            dist = Math.sqrt(dx*dx + dy*dy)

            if dist == 0
                offsetX = 0
                offsetY = 0
            else
                unitX = dx / dist
                unitY = dy / dist

                offsetX = unitX * eyes.offsetMax
                offsetY = unitY * eyes.offsetMax

            drawX = (eyeHaverPosition.x + offsetX) - cameraPosition.x
            drawY = (eyeHaverPosition.y + offsetY) - cameraPosition.y

            @cq.drawImage(@assetManager.assets['acorn-eyes.png'], drawX, drawY)



class AcornSystem extends System
    update: (delta) ->
        [player, __, playerPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent'])
        [scoreEntity, score, lives] = @entityManager.getFirstEntityAndComponents(['ScoreComponent', 'LivesComponent'])
        [camera, __, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        if (player == null) or (scoreEntity == null) or (camera == null)
            return

        enemies = @entityManager.iterateEntitiesAndComponents(['EnemyComponent', 'GridPositionComponent'])

        minScreenCol = Math.floor(cameraPosition.x/Game.GRID_SIZE)
        minScreenRow = Math.floor(cameraPosition.y/Game.GRID_SIZE)

        maxScreenCol = minScreenCol + Math.ceil(Game.SCREEN_WIDTH/Game.GRID_SIZE)
        maxScreenRow = minScreenRow + Math.ceil(Game.SCREEN_HEIGHT/Game.GRID_SIZE)

        for [acornEntity, acorn, acornPosition, eyes, sprite] in @entityManager.iterateEntitiesAndComponents(['AcornComponent', 'GridPositionComponent', 'EyeHavingComponent', 'MultiStateSpriteComponent'])

            if acornPosition.col >= minScreenCol and acornPosition.col <= maxScreenCol and
               acornPosition.row >= minScreenRow and acornPosition.row <= maxScreenRow

                if acornPosition.col == playerPosition.col and acornPosition.row == playerPosition.row
                    @entityManager.removeEntity(acornEntity)
                    score.score++
                    if score.score == 1000
                        lives.lives++

                closest = player
                closestDist = util.dist(
                    acornPosition.col, acornPosition.row,
                    playerPosition.col, playerPosition.row
                )
                sprite.currentFrame = 0
                for [enemyEntity, enemy, enemyPosition] in enemies
                    dist = util.dist(
                        acornPosition.col, acornPosition.row,
                        enemyPosition.col, enemyPosition.row
                    )
                    if dist < closestDist
                        closest = enemyEntity
                        closestDist = dist
                        sprite.currentFrame = 1
                eyes.targetEntity = closest

        acorns = @entityManager.iterateEntitiesAndComponents(['AcornComponent'])
        if acorns.length == 0
            @eventManager.trigger('next-level', player)



class ScoreRenderingSystem extends System
    draw: ->
        [scoreEntity, score, lives] = @entityManager.getFirstEntityAndComponents(['ScoreComponent', 'LivesComponent'])

        @cq.fillStyle('rgba(0,0,0,0.8)')
        @cq.roundRect(-30, -30, 156, 70, 25)
        @cq.fill()

        acornsWidth = @cq.measureText('Acorns: ' + score.score).width
        @cq.roundRect(Game.SCREEN_WIDTH - acornsWidth - 20, -30, 300, 70, 25)
        @cq.fill()

        @cq.font('30px "Merienda One"').textAlign('left').textBaseline('top').fillStyle('white')
        @cq.fillText('Lives: ' + lives.lives, 6, -2)
        #@cq.lineWidth(1).strokeStyle('white').strokeText('Lives: ' + lives.lives, 6, -2)

        @cq.textAlign('right').fillStyle('white')
        @cq.fillText('Acorns: ' + score.score, Game.SCREEN_WIDTH - 6, -2)
        #@cq.lineWidth(3).strokeStyle('black').strokeText('Acorns: ' + score.score, Game.SCREEN_WIDTH - 10, -4)


class EnemyDamageSystem extends System
    update: (delta) ->

        [player, __, playerPosition, playerPixelPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent', 'PixelPositionComponent'])

        for [enemy, __, enemyPosition] in @entityManager.iterateEntitiesAndComponents(['EnemyComponent', 'GridPositionComponent'])
            if enemyPosition.col == playerPosition.col and enemyPosition.row == playerPosition.row
                [scoreEntity, score, lives] = @entityManager.getFirstEntityAndComponents(['ScoreComponent', 'LivesComponent'])
                lives.lives--
                if lives.lives > 0
                    
                    # Reset game
                    playerPosition.col = 9
                    playerPosition.row = 11
                    playerPixelPosition.x = 9 * Game.GRID_SIZE
                    playerPixelPosition.y = 11 * Game.GRID_SIZE

                    enemyPosition.justEntered = yes

                else
                    game.pushState(GameOverScreenState, { finalScore: score.score })


class FireSpreadingSystem extends System
    update: (delta) ->
        for [fire, spreading, firePosition] in @entityManager.iterateEntitiesAndComponents(['SpreadingFireComponent', 'GridPositionComponent'])
            spreading.eventTimer += delta
            if spreading.eventTimer >= spreading.interval
                spreading.eventTimer = 0
                spreading.strength--
                if spreading.strength == 0
                    @entityManager.removeEntity(fire)

                if Math.random() < spreading.chance

                    for [acornEntity, acorn, acornPosition] in @entityManager.iterateEntitiesAndComponents(['AcornComponent', 'GridPositionComponent'])
                        if acornPosition.col == firePosition.col and acornPosition.row == firePosition.row
                            @entityManager.removeEntity(acornEntity)

                    direction = _.sample(['left','right','up','down'])
                    if direction == 'left'
                        newCol = firePosition.col - 1
                        newRow = firePosition.row
                    if direction == 'right'
                        newCol = firePosition.col + 1
                        newRow = firePosition.row
                    if direction == 'up'
                        newCol = firePosition.col
                        newRow = firePosition.row - 1
                    if direction == 'down'
                        newCol = firePosition.col
                        newRow = firePosition.row + 1

                    doSpread = yes
                    for [__, __, otherFirePosition] in @entityManager.iterateEntitiesAndComponents(['SpreadingFireComponent', 'GridPositionComponent'])
                        if otherFirePosition.col == newCol and otherFirePosition.row == newRow
                            doSpread = no

                    # Only spread if there isn't a fire here
                    if doSpread
                        newFireEnemy = @entityManager.createEntityWithComponents([
                            ['SpreadingFireComponent', {}]
                            ['EnemyComponent', {}]
                            ['PixelPositionComponent', { x: newCol * Game.GRID_SIZE, y: newRow * Game.GRID_SIZE }]
                            ['GridPositionComponent', { col: newCol, row: newRow, gridSize: Game.GRID_SIZE }]
                            ['CollidableComponent', {}]
                            ['AnimationComponent', { currentAction: 'fire', spritesheetUrl: 'fire.png', frameWidth: 64, frameHeight: 76, offsetX: 0, offsetY: 12 }]
                            ['AnimationActionComponent', { name: 'fire', row: 0, indices: [ 0,1,2,1,3,3,3,0,3,2,0,2,2,1,0,3,1,3,2,0,3,0,0,0,1,1,1,1,1,3,2,0,2,0,1,1,3,3,0,0,1,3,0,3,0,1,1,2,0,3], frameLength: 50 }]
                        ])

                    for [acornEntity, acorn, acornPosition] in @entityManager.iterateEntitiesAndComponents(['AcornComponent', 'GridPositionComponent'])
                        if acornPosition.col == firePosition.col and acornPosition.row == firePosition.row
                            @entityManager.remove(acornEntity)
                            break


class LevelLoaderSystem extends System
    constructor: (@cq, @entityManager, @eventManager, @assetManager) ->
        [player, __] = @entityManager.getFirstEntityAndComponents(['PlayerComponent'])
        @eventManager.subscribe 'next-level', player, =>
            [__, level] = @entityManager.getFirstEntityAndComponents(['CurrentLevelComponent'])
            level.level++

            # Cycle through the three levels
            levelIdx = ((level.level-1) % 3) + 1
            @loadLevel('level' + levelIdx + '.json')
        
    loadLevel: (tileDataUrl, speedFactor) ->
        # Clear out old layers
        oldEntities = []
        for [enemyEntity, __] in @entityManager.iterateEntitiesAndComponents(['EnemyComponent'])
            oldEntities.push(enemyEntity)
        for [layerEntity, __] in @entityManager.iterateEntitiesAndComponents(['TilemapVisibleLayerComponent'])
            oldEntities.push(layerEntity)
        for [collisionEntity, __] in @entityManager.iterateEntitiesAndComponents(['TilemapCollisionLayerComponent'])
            oldEntities.push(collisionEntity)
        for entity in oldEntities
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
        [player, __, playerPixelPosition, playerGridPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'PixelPositionComponent', 'GridPositionComponent'])
        playerGridPosition.col = 9
        playerGridPosition.row = 11
        playerPixelPosition.x = 9 * Game.GRID_SIZE
        playerPixelPosition.y = 11 * Game.GRID_SIZE

        # Set up acorns
        for tile, idx in objects.data
            if tile == 0
                col = (idx % objects.width)
                row = Math.floor(idx / objects.width)
                acorn = @entityManager.createEntityWithComponents([
                    ['AcornComponent', {}]
                    ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
                    ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
                    ['MultiStateSpriteComponent', { spriteUrl: 'acorn.png', frameWidth: 64, frameHeight: 64 }]
                    ['EyeHavingComponent', { offsetMax: 4, targetEntity: player, eyesImageUrl: 'acorn-eyes.png' }]
                ])
                break

        #for [col, row] in [[3, 3], [3, 16], [16, 3], [16, 16]]
        for [col, row] in [[3,16], [16,3]]
            fireEnemy = @entityManager.createEntityWithComponents([
                ['SpreadingFireComponent', {}]
                ['EnemyComponent', {}]
                ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
                ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
                ['CollidableComponent', {}]
                ['AnimationComponent', { currentAction: 'fire', spritesheetUrl: 'fire.png', frameWidth: 64, frameHeight: 76, offsetX: 0, offsetY: 12 }]
                ['AnimationActionComponent', { name: 'fire', row: 0, indices: [ 0,1,2,1,3,3,3,0,3,2,0,2,2,1,0,3,1,3,2,0,3,0,0,0,1,1,1,1,1,3,2,0,2,0,1,1,3,3,0,0,1,3,0,3,0,1,1,2,0,3], frameLength: 50 }]
            ])


        #[col, row] = _.sample([[3, 3], [3, 16], [16, 3], [16, 16]])
        for [col, row], i in [[3, 3], [16, 16]]
            dog = @entityManager.createEntityWithComponents([
                ['EnemyComponent', {}]
                ['GridPositionComponent', { col: col, row: row, gridSize: Game.GRID_SIZE }]
                ['PixelPositionComponent', { x: col * Game.GRID_SIZE, y: row * Game.GRID_SIZE }]
                ['DirectionComponent', { direction: 'right'}]
                ['ActionInputComponent', {}]
                ['AstarInputComponent', {}]
                ['ColorComponent', { color: 'red' }]
                ['GridMovementComponent', { speed: (i+1) * 0.1 }]
                ['CollidableComponent', {}]
                ['AnimationComponent', { currentAction: 'idle-right', spritesheetUrl: 'dog.png', frameWidth: 176, frameHeight: 176, offsetX: 56, offsetY: 56 }]
                ['AnimationActionComponent', {name: 'idle-right', row: 0, indices: [0], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'idle-left',  row: 1, indices: [0], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'idle-down',  row: 2, indices: [0], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'idle-up',    row: 3, indices: [0], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'walk-right', row: 0, indices: [0,1,2], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'walk-left',  row: 1, indices: [0,1,2], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'walk-down',  row: 2, indices: [0,1,2], frameLength: 100 }]
                ['AnimationActionComponent', {name: 'walk-up',    row: 3, indices: [0,1,2], frameLength: 100 }]
            ])

