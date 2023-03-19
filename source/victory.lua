local gfx <const> = playdate.graphics
local victoryImg = gfx.image.new('Images/victory_screen.png')
local victorySprite = gfx.sprite.new(victoryImg)

local aboveCenterPoint = playdate.geometry.point.new(200, -120)
local centerPoint = playdate.geometry.point.new(200, 120)

function playVictoryScreen()
    local victoryA = gfx.animator.new(1000, aboveCenterPoint, centerPoint, playdate.easingFunctions.outBounce)
    victorySprite:moveTo(200, -120)
    victorySprite:add()
    victorySprite:setAnimator(victoryA)
end
