import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/timer"
import "CoreLibs/math"
import "constants"
import "l1"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
local mth <const> = playdate.math

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local playerSprite = nil
local sandboxImg = nil
local imgOffsetX, imgOffsetY = 20, 20
local drawMode = false
local level, groups = makeLevel()
local blinker = gfx.animation.blinker.new(800, 800, true)
local cursorImg = nil
local cursorSprite = nil
local prevBlinkState = false
local linesegs = {}

function initCursor()
    gfx.pushContext(cursorImg)
    gfx.setColor(bc)
    gfx.fillCircleInRect(0, 0, 8, 8)
    gfx.popContext()
end

function paintCursor()
    if (prevBlinkState ~= blinker.on) then
        gfx.pushContext(cursorImg)
        if drawMode or blinker.on then
            gfx.setColor(bc)
        else
            gfx.setColor(cc)
        end
        -- gfx.fillCircleInRect(0, 0, 8, 8)
        prevBlinkState = blinker.on
        gfx.popContext()
        gfx.sprite.redrawBackground()
    end
end

function myGameSetUp()
    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    --local playerImage = gfx.image.new("Images/crosshair")
    --assert(playerImage) -- make sure the image was where we thought
    cursorImg = gfx.image.new(10, 10)
    sandboxImg = gfx.image.new(360, 200)

    playerSprite = gfx.sprite.new(cursorImg)
    playerSprite:moveTo(1 + CD / 2, 1 + RD / 2) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen


    initCursor()
    local sandboxSprite = gfx.sprite.new(sandboxImg)
    gfx.sprite.add(sandboxSprite)
    gfx.sprite.add(playerSprite)
    blinker:startLoop()
    --    gfx.sprite.add(cursorSprite)


    --sandboxSprite:moveTo(180 + imgOffsetX, 100 + imgOffsetY)
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new("Images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            print("Drawing frame")
            -- gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
            -- gfx.clearClipRect()                  -- clear so we don't interfere with drawing that comes after this
            -- gfx.setColor(bc)
            -- gfx.drawRect(20, 20, 360, 200)
            drawGrid()
        end
    )
end

function range(from, to, step)
    step = step or 1
    return function(_, lastvalue)
        local nextvalue = lastvalue + step
        if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
            step == 0
        then
            return nextvalue
        end
    end, nil, from - step
end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()
local prevx, prevy = playerSprite:getPosition()

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

local trailNum = 3
local spacingY = 7

function getArrayPos()
    return getPosToArrayPos(playerSprite:getPosition())
end

function getPrevArrayPos()
    return getPosToArrayPos(prevx, prevy)
end

function getPosToArrayPos(x, y)
    return 1 + math.floor((x // CD) + YD * math.floor(y // RD))
end

function isOnCircle()
    return level[getArrayPos()] > 0
end

function isPrevOnCircle()
    return level[getPrevArrayPos()] > 0
end

function drawGrid()
    for i in range(0, SW, CD) do
        gfx.drawLine(i, 0, i, SH)
    end
    for i in range(0, SH, RD) do
        gfx.drawLine(0, i, SW, i)
    end
end

function clearSandboxImg()
    gfx.pushContext(sandboxImg)
    gfx.setColor(cc)
    gfx.fillRect(0, 0, 360, 200)
    gfx.popContext()
end

function canStartSegment()
    return isOnCircle() and not drawMode
end

function canEndSegment(x, y)
    local lineseg = playdate.geometry.lineSegment.new(prevx, prevy, x, y)
    for _, v in pairs(linesegs) do
        local intersection, ls = lineseg:intersectsLineSegment(v)
        if intersection and (ls:distanceToPoint(playdate.geometry.point.new(x, y)) > 5) and (ls:distanceToPoint(playdate.geometry.point.new(prevx, prevy)) > 5) then
            return false
        end
    end
    return drawMode
end

function playdate.update()
    -- Poll the d-pad and move our player accordingly.
    -- (There are multiple ways to read the d-pad; this is the simplest.)
    -- Note that it is possible for more than one of these directions
    -- to be pressed at once, if the user is pressing diagonally.
    newTrailNum = math.floor(((450 + playdate.getCrankPosition()) % 360) / 45)

    gfx.animation.blinker.updateAll()
    paintCursor()

    if trailNum ~= newTrailNum then
        trailNum = newTrailNum
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonA) then
        local x, y = playerSprite:getPosition()
        if canStartSegment() then
            prevx, prevy = x, y
            drawMode = not drawMode
        elseif canEndSegment(x, y) then
            linesegs[1 + #linesegs] = playdate.geometry.lineSegment.new(prevx, prevy, x, y)
            drawMode = not drawMode
        end
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonB) then
        table.remove(linesegs, #linesegs)
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonUp) then
        playerSprite:moveBy(0, -RD)
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonRight) then
        playerSprite:moveBy(CD, 0)
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonDown) then
        playerSprite:moveBy(0, RD)
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonLeft) then
        playerSprite:moveBy(-CD, 0)
        gfx.sprite.redrawBackground()
    end

    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)

    gfx.sprite.update()
    playdate.timer.updateTimers()
end

gfx.sprite.setBackgroundDrawingCallback(
    function(_x, _y, width, height)
        if blinker.on and drawMode then
            local arrPlayerPos = getPrevArrayPos()
            local highlightedGroup = level[arrPlayerPos]
            drawLevel(groups, highlightedGroup, arrPlayerPos)
        elseif blinker.on then
            local arrPlayerPos = getArrayPos()
            local highlightedGroup = level[getArrayPos()]
            drawLevel(groups, highlightedGroup, arrPlayerPos)
        else
            drawLevel(groups, level, -1)
        end
    end
)

function retryLevel()
    linesegs = {}
    level, groups = makeLevel()
    drawMode = false
    playerSprite:moveTo(1 + CD / 2, 1 + RD / 2) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    gfx.sprite.redrawBackground()
end

local menu = playdate.getSystemMenu()

local menuItem, error = menu:addMenuItem("Retry Level", retryLevel)


gfx.sprite.setBackgroundDrawingCallback(
    function(_x, _y, width, height)
        gfx.setLineWidth(2)
        for i, v in ipairs(linesegs) do
            gfx.drawLine(v)
        end
        if drawMode then
            local x, y = playerSprite:getPosition()
            gfx.drawLine(prevx, prevy, x, y)
        end
        gfx.setLineWidth(1)
    end
)
