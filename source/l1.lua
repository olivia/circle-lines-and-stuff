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
  local lookup = {}
  local drawList = { {}, {}, {} }
  for i = 0, (SH * SW) / (CD * RD) do
    if math.random() < 0.1 then
      local group = math.ceil(math.random() * 3)
      table.insert(drawList[group], i)
      table.insert(lookup, group)
    else
      table.insert(lookup, 0)
    end
  end
  return lookup, drawList
end

function drawLevel(a, highlightedGroup, arrPlayerPos)
  gfx.setLineWidth(2)
  gfx.setColor(bc)
  for _, v in ipairs(a) do
    for __, g in ipairs(v) do
      local colNum = SW / CD
      local padding = 4
      if _ == highlightedGroup and (g + 1) ~= arrPlayerPos then
        gfx.fillCircleInRect(padding + CD * (g % colNum), padding + RD * math.floor(g / colNum), CD - padding * 2,
          RD - padding * 2)
      end
      gfx.drawCircleInRect(padding + CD * (g % colNum), padding + RD * math.floor(g / colNum), CD - padding * 2,
        RD - padding * 2)
      gfx.setColor(bc)
    end
  end

  gfx.setLineWidth(1)
end
