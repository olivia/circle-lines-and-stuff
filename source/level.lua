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
function initLevel()
  local lookup = {}
  local lookupWithSegments = {}
  local drawList = { {}, {}, {} }
  for i = 0, (SH * SW) / (CD * RD) do
    if math.random() < 0.1 then
      local group = math.ceil(math.random() * 3)
      table.insert(drawList[group], i)
      table.insert(lookup, group)
    else
      table.insert(lookup, 0)
    end
    table.insert(lookupWithSegments, 0)
  end
  return lookup, lookupWithSegments, drawList, {}
end

function drawLevel(a, highlightedGroup, arrPlayerPos)
  gfx.setLineWidth(2)
  gfx.setColor(bc)
  local drawingFns = { drawCircle, drawTriangle, drawDiamond }
  local fnArrLength = #drawingFns
  for _, v in ipairs(a) do
    for __, g in ipairs(v) do
      drawingFns[1 + (_ - 1) % fnArrLength](g, _ == highlightedGroup and (g + 1) ~= arrPlayerPos)
    end
  end

  gfx.setLineWidth(1)
end

function drawCircle(idx, shouldHighlight)
  local colNum = SW / CD
  local padding = 4
  local xStart = padding + CD * (idx % colNum)
  local yStart = padding + RD * math.floor(idx / colNum)
  local rectWidth = CD - padding * 2
  local rectHeight = RD - padding * 2
  if not shouldHighlight then
    gfx.setColor(wc)
  end
  gfx.fillCircleInRect(xStart, yStart, rectWidth, rectHeight)
  gfx.setColor(bc)
  gfx.drawCircleInRect(xStart, yStart, rectWidth, rectHeight)
end

function drawTriangle(idx, shouldHighlight)
  local colNum = SW / CD
  local padding = 4
  local xStart = padding + CD * (idx % colNum)
  local yStart = padding + RD * math.floor(idx / colNum)
  local rectWidth = CD - padding * 2
  local rectHeight = RD - padding * 2
  if not shouldHighlight then
    gfx.setColor(wc)
  end
  gfx.fillTriangle(xStart, yStart + rectHeight, xStart + rectWidth / 2, yStart, xStart + rectWidth,
    yStart + rectHeight)
  gfx.setColor(bc)
  gfx.drawTriangle(xStart, yStart + rectHeight, xStart + rectWidth / 2, yStart, xStart + rectWidth,
    yStart + rectHeight)
end

function drawDiamond(idx, shouldHighlight)
  local colNum = SW / CD
  local padding = 4
  local xStart = padding + CD * (idx % colNum)
  local yStart = padding + RD * math.floor(idx / colNum)
  local rectWidth = CD - padding * 2
  local rectHeight = RD - padding * 2
  if not shouldHighlight then
    gfx.setColor(wc)
  end
  gfx.fillPolygon(xStart, yStart + rectHeight / 2, xStart + rectWidth / 2, yStart, xStart + rectWidth,
    yStart + rectHeight / 2, xStart + rectWidth / 2, yStart + rectHeight)
  gfx.setColor(bc)
  gfx.drawPolygon(xStart, yStart + rectHeight / 2, xStart + rectWidth / 2, yStart, xStart + rectWidth,
    yStart + rectHeight / 2, xStart + rectWidth / 2, yStart + rectHeight)
end
