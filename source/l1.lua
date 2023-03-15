import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "constants"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
function makeLevel()
  local a = {}
  for i=0, (SH * SW) /(CD*RD) do
    if math.random()<0.1 then
      a[i+1] = math.ceil(math.random()*3)
    else 
      a[i+1] = 0
    end
  end
  return a
end

function drawLevel(a)
  for i=0, (SH * SW) /(CD*RD) do
    local colNum = SW/CD
    local padding = 4
    if a[i+1]>0 then
      gfx.drawCircleInRect(padding + CD* (i % colNum),padding +  RD * math.floor(i/colNum), CD- padding*2, RD - padding*2)
    end
  end
end