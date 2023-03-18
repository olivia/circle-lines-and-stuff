local gfx <const> = playdate.graphics
local blinker, prevBlinkState

function initBlinker()
    blinker = gfx.animation.blinker.new(800, 800, true)
    prevBlinkState = blinker.on
end

function startBlinkLoop()
    blinker:startLoop()
end

function updateBlinks()
    gfx.animation.blinker.updateAll()
end

function isBlinkOn()
    return blinker.on
end

function shouldRepaintBlink()
    return prevBlinkState ~= blinker.on
end

function updateBlinkState()
    prevBlinkState = blinker.on
end
