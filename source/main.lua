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
import "puzzles"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx<const> = playdate.graphics
local sound<const> = playdate.sound
local synth<const> = playdate.sound.synth

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local drawMode = false
local level, levelWithSegments, groups, linesegs
local synthSound = synth.new(sound.kWaveSine)

function myGameSetUp()
    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.
    level, levelWithSegments, groups, linesegs = getRandomPuzzle()
    initCursor()
    initBlinker()
    startBlinkLoop()
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.
    gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
        -- gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
        -- gfx.setColor(bc)
        -- gfx.clearClipRect()                  -- clear so we don't interfere with drawing that comes after this
        -- gfx.drawRect(20, 20, 360, 200)
        drawGrid()
    end)
end

myGameSetUp()
local prevx, prevy = getCursorPosition()

function retryLevel()
    drawMode = false
    level, levelWithSegments, groups, linesegs = getPuzzle(CURRENT_PUZZLE_IDX)
    setInitCursorPos()
    prevx, prevy = getCursorPosition()
    gfx.sprite.redrawBackground()
    stopVictoryScreen()
end

function nextLevel()
    drawMode = false
    level, levelWithSegments, groups, linesegs = getRandomPuzzle()
    setInitCursorPos()
    prevx, prevy = getCursorPosition()
    gfx.sprite.redrawBackground()
    stopVictoryScreen()
end

local menu = playdate.getSystemMenu()
menu:addMenuItem("retry", retryLevel)
menu:addMenuItem("Next level", nextLevel)

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
    local prevNode = nil
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        local currNode = levelWithSegments[arrayIdx]
        currNode.group = group
        if (prevNode ~= nil and table.indexOfElement(currNode.edges, prevNode) == nil) then
            table.insert(currNode.edges, prevNode)
            table.insert(prevNode.edges, currNode)
            print("linking", prevNode.idx, currNode.idx)
        end
        prevNode = currNode
    end
end

function deleteEdge(prevx, prevy, x, y)
    local ydiff, xdiff = y - prevy, x - prevx
    local iternum = math.max(math.abs(ydiff), math.abs(xdiff)) // CD
    local xDelta = CD * getSignDelta(prevx, x)
    local yDelta = RD * getSignDelta(prevy, y)
    local prevNode = nil
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        local currNode = levelWithSegments[arrayIdx]
        if (prevNode ~= nil) then
            local cpIdx = table.indexOfElement(currNode.edges, prevNode)
            local pcIdx = table.indexOfElement(prevNode.edges, currNode)
            table.remove(currNode.edges, cpIdx)
            table.remove(prevNode.edges, pcIdx)
        end
        prevNode = currNode
    end
    for i in range(0, iternum, 1) do
        local arrayIdx = getPosToArrayPos(prevx + i * xDelta, prevy + i * yDelta)
        local currNode = levelWithSegments[arrayIdx]
        if (#currNode.edges == 0) then
            currNode.group = 0
        end
        prevNode = currNode
    end
end

-- is not an edge node
function isRealNode(node)
    if (level[node.idx].group ~= 0) then
        return true
    end
    return false
end

-- bfs
function traversePath(node, visitorList)
    if node == nil then
        return 0
    end
    local pathCount = 0
    visitorList[node.idx] = 1
    if isRealNode(node) then
        print("Index is real", node.idx, node.group)
        pathCount = 1
    end
    for _, v in pairs(node.edges) do
        if visitorList[v.idx] == 0 then
            print("Traversing", v.idx, pathCount, node.idx)
            pathCount = pathCount + traversePath(v, visitorList)
        end
    end
    return pathCount
end

function allPathsCompleted()
    for i, v in ipairs(groups) do
        print("attempting path", i)
        if (not pathIsCompleted(i)) then
            print("path is not completed", i)
            return false
        end
    end
    return true
end

function pathIsCompleted(groupNum)
    local groupPath = {}
    local visitorList = getVisitList()
    for i, v in ipairs(levelWithSegments) do
        if v.group == groupNum and isRealNode(v) then
            table.insert(groupPath, v)
        end
    end
    local pathLength = 0
    if #groupPath then
        pathLength = traversePath(groupPath[1], visitorList)
    end
    print(groupNum, #groupPath, pathLength)
    return #groupPath == pathLength
end

function currentPositionGroup()
    return levelWithSegments[getPosToArrayPos(getCursorPosition())].group
end

function getArrayPos()
    return getPosToArrayPos(getCursorPosition())
end

function getPrevArrayPos()
    return getPosToArrayPos(prevx, prevy)
end

function getPosToArrayPos(x, y)
    local pos = math.floor((x // CD) + YD * math.floor(y // RD))
    return pos + 1
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

    if ((math.abs(xdiff) ~= math.abs(ydiff)) and (xdiff ~= 0) and (ydiff ~= 0)) or (not drawMode) or
        (not checkEdge(x, y)) then
        return false
    end

    for _, v in pairs(linesegs) do
        local intersection, ls = lineseg:intersectsLineSegment(v)
        if intersection and (ls:distanceToPoint(playdate.geometry.point.new(x, y)) > 5) and
            (ls:distanceToPoint(playdate.geometry.point.new(prevx, prevy)) > 5) then
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
        if SHOWING_VICTORY then
            retryLevel()
        elseif canStartSegment() then
            prevx, prevy = x, y
            drawMode = not drawMode
            -- synthSound:playNote("Eb3", 1, 0.2)
        elseif canEndSegment(x, y) then
            walkEdge(x, y)
            table.insert(linesegs, playdate.geometry.lineSegment.new(prevx, prevy, x, y))
            drawMode = not drawMode
            -- synthSound:playNote("Eb3", 1, 0.2)

            if allPathsCompleted() then
                playVictoryScreen()
            end
        end
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonB) then
        if not drawMode then
            local lineseg = table.remove(linesegs, #linesegs)
            if lineseg ~= nil then
                deleteEdge(lineseg:unpack())
            end
        else
            drawMode = false
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

gfx.sprite.setBackgroundDrawingCallback(function(_x, _y, width, height)
    gfx.setLineWidth(2)
    for i, v in ipairs(linesegs) do
        gfx.drawLine(v)
    end
    if drawMode then
        local x, y = getCursorPosition()
        gfx.drawLine(prevx, prevy, x, y)
    end
    gfx.setLineWidth(1)
end)

gfx.sprite.setBackgroundDrawingCallback(function(_x, _y, width, height)
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
end)
