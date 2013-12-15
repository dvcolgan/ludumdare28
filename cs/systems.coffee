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

                    for [noop, collisionLayer] in @entityManager.iterateEntitiesAndComponents(['TilemapCollisionLayerComponent'])
                        tileIdx = (gridPosition.row+dy) * collisionLayer.tileData.width + (gridPosition.col+dx)
                        nextTile = collisionLayer.tileData.data[tileIdx]
                        if nextTile == 0
                            #canMove = true
                            #for [noop, otherGridPosition, _] in @entityManager.iterateEntitiesAndComponents(['GridPositionComponent', 'CollidableComponent'])
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
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

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
        for [entity, noop, input] in @entityManager.iterateEntitiesAndComponents(['KeyboardArrowsInputComponent', 'ActionInputComponent'])
            if input.enabled or value == off
                if value == off
                    if key == 'left'  then input.left = off
                    if key == 'right' then input.right = off
                    if key == 'up'    then input.up = off
                    if key == 'down'  then input.down = off
                    if key == 'z' or key == 'semicolon' then input.action = off
                    if key == 'x' or key == 'q'     then input.cancel = off
                else
                    # TODO MAKE A COFFEESCRIPT PRECOMPILER
                    #{% for dir in ['left', 'right', 'up', 'down'] %}
                    #    if key == '{{ dir }}' then if input.{{ dir }} == 'hit' then input.{{ dir }} = 'held' else input.{{ dir }} = 'hit'

                    if key == 'left'
                        if input.left  == 'hit' then input.left  = 'held' else input.left  = 'hit'
                    if key == 'right'
                        if input.right == 'hit' then input.right = 'held' else input.right = 'hit'
                    if key == 'up'
                        if input.up    == 'hit' then input.up    = 'held' else input.up    = 'hit'
                    if key == 'down'
                        if input.down  == 'hit' then input.down  = 'held' else input.down  = 'hit'

                    if key == 'z' or key == 'semicolon'
                        if input.action == 'hit' then input.action = 'held' else input.action = 'hit'
                    if key == 'x' or key == 'q'
                        if input.cancel == 'hit' then input.cancel = 'held' else input.cancel = 'hit'

# TODO make this generic for any key using a nice hash table
class RandomInputSystem extends System
    update: (delta) ->
        for [entity, noop, input] in @entityManager.iterateEntitiesAndComponents(['RandomArrowsInputComponent', 'ActionInputComponent'])
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
        [player, noop, playerPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent'])
        for [entity, noop, noop, input, enemyPosition] in @entityManager.iterateEntitiesAndComponents(['EnemyComponent', 'AstarInputComponent', 'ActionInputComponent', 'GridPositionComponent'])
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

                    console.log dx + ' ' + dy

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
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])
        [followee, noop, followeePosition] = @entityManager.getFirstEntityAndComponents(['CameraFollowsComponent', 'PixelPositionComponent'])

        [mapLayer, mapLayerComponent] = @entityManager.getFirstEntityAndComponents(['TilemapVisibleLayerComponent'])

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
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

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
        [playerEntity, noop, playerGridPosition, playerDirection, playerInput] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent', 'DirectionComponent', 'ActionInputComponent'])
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
                [playerEntity, noop, playerInput] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'ActionInputComponent'])
                playerInput.enabled = yes
                talkeeInput = @entityManager.getComponent(dialogBox.talkee, 'ActionInputComponent')
                if talkeeInput then talkeeInput.enabled = yes

            

    draw: (delta) ->
        [noop, dialogBox, dialogBoxText] = @entityManager.getFirstEntityAndComponents(['DialogBoxComponent', 'DialogBoxTextComponent'])
        
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
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

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
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])

        for [spriteEntity, sprite, position] in @entityManager.iterateEntitiesAndComponents(['StaticSpriteComponent', 'PixelPositionComponent'])
            screenX = Math.floor(position.x - cameraPosition.x)
            screenY = Math.floor(position.y - cameraPosition.y)
            @cq.drawImage(@assetManager.assets[sprite.spriteUrl], screenX, screenY)


class EyeFollowingSystem extends System
    draw: ->
        [camera, noop, cameraPosition] = @entityManager.getFirstEntityAndComponents(['CameraComponent', 'PixelPositionComponent'])
        for [eyeEntity, eyes, eyeHaverPosition] in @entityManager.iterateEntitiesAndComponents(['EyeHavingComponent', 'PixelPositionComponent'])
            #TODO cull the acorns offscreen
            targetPosition = @entityManager.getComponent(eyes.targetEntity, 'PixelPositionComponent')
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
        [player, noop, playerPosition] = @entityManager.getFirstEntityAndComponents(['PlayerComponent', 'GridPositionComponent'])
        [scoreEntity, score, acornsLeft] = @entityManager.getFirstEntityAndComponents(['ScoreComponent', 'AcornsLeftComponent'])

        for [acornEntity, acorn, acornPosition] in @entityManager.iterateEntitiesAndComponents(['AcornComponent', 'GridPositionComponent'])
            if acornPosition.col == playerPosition.col and acornPosition.row == playerPosition.row
                @entityManager.removeEntity(acornEntity)
                score.score++
                acornsLeft--
                if acornsLeft == 0
                    console.log 'WINNER'


class ScoreRenderingSystem extends System
    draw: ->
        [scoreEntity, score, acornsLeft, lives] = @entityManager.getFirstEntityAndComponents(['ScoreComponent', 'AcornsLeftComponent', 'LivesComponent'])

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

