local gfx<const> = playdate.graphics
local victoryImg = gfx.image.new('Images/victory_screen.png')
local victorySprite = gfx.sprite.new(victoryImg)
local aboveCenterPoint = playdate.geometry.point.new(200, -120)
local centerPoint = playdate.geometry.point.new(200, 120)
SHOWING_VICTORY = false

function playVictoryScreen()
    local victoryA = gfx.animator.new(1000, aboveCenterPoint, centerPoint, playdate.easingFunctions.outBounce)
    victorySprite:moveTo(200, -120)
    victorySprite:add()
    victorySprite:setAnimator(victoryA)
    SHOWING_VICTORY = true
end

function stopVictoryScreen()
    victorySprite:removeAnimator()
    victorySprite:moveTo(200, -120)
    SHOWING_VICTORY = false
end
