import "CoreLibs/graphics"
local gfx <const> = playdate.graphics
local cursorImg = nil
local cursorSprite = nil

function setInitCursorPos()
    cursorSprite:moveTo(CD / 2, RD / 2) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
end

function initCursor()
    local lw = 3
    cursorImg = gfx.image.new(CD + 3, RD + 3)
    cursorSprite = gfx.sprite.new(cursorImg)
    setInitCursorPos()
    gfx.pushContext(cursorImg)
    gfx.setLineWidth(lw)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(lw, lw, CD - lw / 2, RD - lw / 2)
    gfx.setLineWidth(1)
    gfx.popContext()
    gfx.sprite.add(cursorSprite)
end

function paintCursor(drawMode, isBlinkOn)
    gfx.pushContext(cursorImg)
    if drawMode or isBlinkOn then
        gfx.setColor(bc)
    else
        gfx.setColor(cc)
    end
    gfx.popContext()
    gfx.sprite.redrawBackground()
end

function getCursorPosition()
    return cursorSprite:getPosition()
end

function moveCursorTo(x, y)
    return cursorSprite:moveTo(x, y)
end

function moveCursor(x, y)
    return cursorSprite:moveBy(x, y)
end
