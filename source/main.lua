import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/timer"
import "CoreLibs/math"
import "constants"
import "utils"
import "cursor"
import "blink"
import "level"
import "victory"


-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local synth <const> = playdate.sound.synth

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local drawMode = false
local level, levelWithSegments, groups, linesegs = initLevel()
local synthSound = synth.new(sound.kWaveNoise)

function myGameSetUp()
    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.
    initCursor()
    initBlinker()
    startBlinkLoop()
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.
    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            -- gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
            -- gfx.setColor(bc)
            -- gfx.clearClipRect()                  -- clear so we don't interfere with drawing that comes after this
            -- gfx.drawRect(20, 20, 360, 200)
            drawGrid()
        end
    )
end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()
local prevx, prevy = getCursorPosition()

function retryLevel()
    drawMode = false
    level, levelWithSegments, groups, linesegs = initLevel()
    setInitCursorPos()
    prevx, prevy = getCursorPosition()
    gfx.sprite.redrawBackground()
end

local menu = playdate.getSystemMenu()
menu:addMenuItem("Retry Level", retryLevel)

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

function checkEdge(x, y)
    local ydiff, xdiff = y - prevy, x - prevx
    local iternum = math.max(math.abs(ydiff), math.abs(xdiff)) // CD
    local xDelta = CD * getSignDelta(prevx, x)
    local yDelta = RD * getSignDelta(prevy, y)
    local group = math.max(levelWithSegments[getPrevArrayPos()].group, level[getPrevArrayPos()].group)
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        local currGroup = math.max(levelWithSegments[arrayIdx].group, level[arrayIdx].group)
        if (currGroup ~= 0 and currGroup ~= group) then
            return false
        end
    end
    return true
end

function walkEdge(x, y)
    local ydiff, xdiff = y - prevy, x - prevx
    local iternum = math.max(math.abs(ydiff), math.abs(xdiff)) // CD
    local xDelta = CD * getSignDelta(prevx, x)
    local yDelta = RD * getSignDelta(prevy, y)
    local group = math.max(levelWithSegments[getPrevArrayPos()].group, level[getPrevArrayPos()].group)
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        levelWithSegments[arrayIdx] = { group = group }
    end
end

function deleteEdge(prevx, prevy, x, y)
    local ydiff, xdiff = y - prevy, x - prevx
    local iternum = math.max(math.abs(ydiff), math.abs(xdiff)) // CD
    local xDelta = CD * getSignDelta(prevx, x)
    local yDelta = RD * getSignDelta(prevy, y)
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        levelWithSegments[arrayIdx] = { group = 0 }
    end
end

function getArrayPos()
    return getPosToArrayPos(getCursorPosition())
end

function getPrevArrayPos()
    return getPosToArrayPos(prevx, prevy)
end

function getPosToArrayPos(x, y)
    return 1 + math.floor((x // CD) + YD * math.floor(y // RD))
end

function isOnGroup()
    return (level[getArrayPos()].group > 0) or (levelWithSegments[getArrayPos()].group > 0)
end

function canStartSegment()
    return isOnGroup() and not drawMode
end

function canEndSegment(x, y)
    local lineseg = playdate.geometry.lineSegment.new(prevx, prevy, x, y)
    local xdiff, ydiff = x - prevx, y - prevy

    if ((math.abs(xdiff) ~= math.abs(ydiff)) and (xdiff ~= 0) and (ydiff ~= 0)) or (not drawMode) or (not checkEdge(x, y)) then
        return false
    end

    for _, v in pairs(linesegs) do
        local intersection, ls = lineseg:intersectsLineSegment(v)
        if intersection and (ls:distanceToPoint(playdate.geometry.point.new(x, y)) > 5) and (ls:distanceToPoint(playdate.geometry.point.new(prevx, prevy)) > 5) then
            return false
        end
    end
    return true
end

function playdate.update()
    -- Poll the d-pad and move our player accordingly.
    -- (There are multiple ways to read the d-pad; this is the simplest.)
    -- Note that it is possible for more than one of these directions
    -- to be pressed at once, if the user is pressing diagonally.
    updateBlinks()
    if (shouldRepaintBlink) then
        paintCursor(drawMode, isBlinkOn())
        updateBlinkState()
    end
    if playdate.buttonJustReleased(playdate.kButtonA) then
        local x, y = getCursorPosition()
        if canStartSegment() then
            prevx, prevy = x, y
            drawMode = not drawMode
            synthSound:playNote("Db3", 1, 0.1)
        elseif canEndSegment(x, y) then
            walkEdge(x, y)
            linesegs[1 + #linesegs] = playdate.geometry.lineSegment.new(prevx, prevy, x, y)
            drawMode = not drawMode
            synthSound:playNote("Eb3", 1, 0.1)
        end
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonB) then
        local lineseg = table.remove(linesegs, #linesegs)
        if lineseg ~= nil then
            deleteEdge(lineseg:unpack())
        end
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonUp) then
        if (canMoveCursor(0, -RD)) then
            moveCursor(0, -RD)
            gfx.sprite.redrawBackground()
        end
    end
    if playdate.buttonJustReleased(playdate.kButtonRight) then
        if (canMoveCursor(CD, 0)) then
            moveCursor(CD, 0)
            gfx.sprite.redrawBackground()
        end
    end
    if playdate.buttonJustReleased(playdate.kButtonDown) then
        if (canMoveCursor(0, RD)) then
            moveCursor(0, RD)
            gfx.sprite.redrawBackground()
        end
    end
    if playdate.buttonJustReleased(playdate.kButtonLeft) then
        if (canMoveCursor(-CD, 0)) then
            moveCursor(-CD, 0)
            gfx.sprite.redrawBackground()
        end
    end

    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)

    gfx.sprite.update()
    playdate.timer.updateTimers()
end

gfx.sprite.setBackgroundDrawingCallback(
    function(_x, _y, width, height)
        gfx.setLineWidth(2)
        for i, v in ipairs(linesegs) do
            gfx.drawLine(v)
        end
        if drawMode then
            local x, y = getCursorPosition()
            gfx.drawLine(prevx, prevy, x, y)
        end
        gfx.setLineWidth(1)
    end
)

gfx.sprite.setBackgroundDrawingCallback(
    function(_x, _y, width, height)
        local arrPlayerPos, highlightedGroup
        if isBlinkOn() and drawMode then
            arrPlayerPos = getPrevArrayPos()
            highlightedGroup = level[arrPlayerPos].group
        elseif isBlinkOn() then
            arrPlayerPos = getArrayPos()
            highlightedGroup = level[arrPlayerPos].group
        else
            arrPlayerPos = -1
            -- this seems wrong
            highlightedGroup = level
        end
        drawLevel(groups, highlightedGroup, arrPlayerPos)
    end
)
