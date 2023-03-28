import "base64"
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

PUZZLES =
    {"MjQuMjAuMjMwLjIyMC42NC42OS4yMjEuNDUuODkuMjIyOjE1MC4xNy4zNi4xOS4xNzEuMTguNTUuMTEwLjE3My4xMzA6MTQ3LjIzMS40Mi43OS4xNC41NC45OC4zOS4xNjguMTUz",
     "MjM3LjIzOS4xOTkuMTk1LjIxOS4yMzUuMTk3LjIzNi4xNzYuMTk6MTcwLjIyNy4yLjEyOC4xMi4wLjIyMC4yMDAuMTA1LjEyMjoxMTQuMjM0LjE5OC4xMzQuMjE1LjIyOS4yMjguMTM1LjE4LjIzMQ==",
     "MjA2LjIyNy4yMjUuMjIwLjIzOS4yMzcuMjI2LjE5LjIyNC4xNTE6MTAyLjEwNi4xNDAuMjAwLjEwNy4xNjAuMjA1LjEwNS4yMDEuMTQzOjE4OC44LjAuMTI1LjE5Ny41MC4xMjAuMTgyLjE3LjE2Mw==",
     "MzIuMTEuMTkuOTUuMTIuNTEuMzEuMTQ2LjI2LjE5MDoyMTAuMzkuMjA0LjQuNTIuNTguMTAuMTMyLjIwOC4yMDM6ODIuMjIyLjIzOS4yLjU5LjIxMS4xNTUuMTU3LjE5Mi4z",
     "MjI0LjE1LjIxNS4xMzkuMjAzLjEwOC4xNzcuMTI4LjEzMS4xMzY6ODguODAuOTAuMjIxLjIyMy4yMjAuMTA3LjAuMTQuODoxMzAuMjM1LjE1OS4yMzkuMTUxLjU0LjExMS4xNzQuMTk5Ljky",
     "MTIuMTU5LjIzNS4yMTQuMTU0LjE5My4yMzkuMjMzLjIxMi4xNzM6MTQ1LjIyOS4xMTUuNS4xODcuMTI1LjExMi4xMTYuMjE1LjI4OjEzMi42LjE0Ni4yMDkuMTMzLjE2Ny4xMjcuMjYuMTEuMTEx",
     "MjA2LjIyNy4yMDEuMjA3LjIwMi4xMjEuMjM5LjE5LjU5LjE0MToxOTguMTguMTgyLjAuNjAuMjIuMzcuMTk3LjQwLjE3MDoxMDAuMjIwLjIyNS4yMjYuNDMuMTYzLjgwLjEwMi4xNDIuMTIy",
     "MTA2LjIyMC4yMzkuMjIxLjMwLjg3LjIwLjI4LjE2MS4xNDI6MjEzLjEzLjIxOS4yMDMuNzAuMTkwLjUxLjcyLjE4NS4yMDI6ODYuMTAuNDguMTIuNTIuMC4yLjEuMTYyLjEx",
     "MC4yMjAuMjM4LjU4LjIzNy4zOC40MC4xODkuNDUuNzg6MTkuMjM5LjIuNTkuMzkuMTkxLjc5LjMuMTQ5Ljk5OjIxMS4xLjIwMS4xNjkuMjAzLjk3Ljg3LjE0NC4xOTAuMTg0",
     "NTkuMjMwLjIzOS4yMjAuMTYwLjIwMi4xNTUuMjM1LjIwNy4xOTA6MTIuMTcyLjEzMi4xLjM5LjEwMS4yNS4xNTMuMTY3LjEyNToxNDUuMzEuMTQwLjAuMTAwLjIwOC4xNTAuMTIwLjI2LjQ3",
     "MjI1LjE2LjIzOS43Ni4yMzguNzcuMzYuNTguNzguNzQ6OTkuMTkuOTMuNTkuMTg4LjE5OC4xNzMuNTcuMTcuNzk6MjA3LjIxOS4yMTguMTE5LjIxNi4xMzkuMTE0LjE3Ni4xNzkuMTU0",
     "MTM1LjE1LjEuOTkuMjMwLjEzMC4yMzkuMjI1LjEzOS4zNjoxMDAuMC4xNDcuNTIuNDMuMTI4LjE4MC4xMjYuMTA2LjEwODoxMTAuMzQuMjI0LjIyMC4yMi4xMjUuMjAxLjEyMS4xNDIuMTM0",
     "MTE5LjE5LjUuNjguMTE0LjQ3LjIyOC4yMzMuNzcuMTkxOjU2LjIyNy41MS4yMjAuNzYuMTI1LjEyMC4zOC43OC41NDoxMDkuNC4yOS43MS4zNy4xMDAuNjcuMTg1LjY5Ljky",
     "MjA4LjQwLjU2LjU4Ljk0LjIxNC4yMDAuMTYyLjIxLjE4ODoxNy41OS4xNjkuOTcuMTY4LjE2Ny4wLjIwLjE5Ny4zNDo3Ni4yMzYuMTczLjE3OS4yMjAuMTk2LjE0NC4xODIuMTQyLjIzOQ==",
     "MTE3LjEyLjAuMTU5LjEyMC4xOTcuMTUyLjEyMy40MC4yOjE0Ni4xNDAuMjA2LjIwOS4xODAuNjIuODEuMjAwLjQxLjQ5OjIzMC4yMjAuMTgyLjMwLjIzOS4xNjMuMTg1LjIxLjE2NC4xNjU=",
     "MzAuMTAuMTkuMTEuMjM5LjY4LjIxOS4xMzQuMTMuMjE4LjI0OjIxMi4yLjkuMjMuMy4zMi4yMDIuMjA0LjIwMzozMy4yMzMuMjIwLjE5My4xMDYuMTI1LjIzOC4zOC4xMTQuMQ==",
     "NDIuMi4wLjE3MC4xMjIuNzUuMTAxLjEwLjE3MS44MToxNDIuMTQwLjIwLjE0OC4yMS4yMjAuMTQ0LjYxLjEwMC4yMDM6OTYuMjI5LjE2Ljc5LjE2OS4xMTUuMjMxLjExLjIyMS4xMTY=",
     "MTg5LjIyOS4xMzQuOS4yMzguMTM4LjIxNC4yMTAuMTMxLjEzNToxMTMuMTE5LjIzOS4xNTUuMTExLjEzOS4xMTQuMzUuMjE1Ljk4OjE1Ljk5Ljc4LjU3LjEwLjE5MC4xOS45NC45Ni4zOA==",
     "MTMxLjIzMS4yMjAuNDAuMjM5LjIzMy4xODcuMTEyLjEzNC4yMzU6MC4yMTAuMzAuMjAxLjE4OS44Ny4xNjguNzAuMTQ3LjUwOjIxOS4xOS4xLjUxLjIxMi4yMTMuMTk5LjE2OS42OS4xMjc=",
     "OTQuMTQuMC4xMTkuODQuMTk5LjE5NS4zMS4zMy4xNTk6MjM1LjIyMC4yMC44Ny4yMDAuMTkyLjE4My4yMzkuODUuMjM2OjE5My4yMTQuMTE0LjI1LjIxOS4yMDIuMTUxLjMwLjcyLjE3NA==",
     "MzguMjAuMS4wLjE2Ny40Ny4zNy4zNi4zNC4xMjcuMTM4OjE0OS43My4yMjUuNTMuNDguMTU4LjIxOC4yMDcuNTc6Mi4xOS4yMzkuMTcuMzkuMjI2LjE4LjE1LjE0LjU5"}

function createLevel(groups)
    local lookup = {}
    local lookupWithSegments = {}
    local drawList = {{}, {}, {}}

    for i = 1, (SH * SW) / (CD * RD) do
        table.insert(lookup, {
            group = 0
        })
        table.insert(lookupWithSegments, {
            group = 0,
            idx = i,
            edges = {}
        })
    end
    print(groups)
    for group, v in ipairs(groups) do
        print("parsing", groups[group])
        for str in string.gmatch(groups[group], "([^.]+)") do
            local i = tonumber(str) + 1
            table.insert(drawList[group], i)
            lookup[i] = {
                group = group
            }
            lookupWithSegments[i] = {
                group = group,
                idx = i,
                edges = {}
            }
        end
    end

    return lookup, lookupWithSegments, drawList, {}
end

function decodePuzzle(puzzle)
    local decodedB64 = base64.decode(puzzle)
    return createLevel(mysplit(decodedB64, ":"))
end

CURRENT_PUZZLE_IDX = 0

function getRandomPuzzle()
    local puzzleNum = #PUZZLES
    local idx = 1 + math.floor(math.random() * (puzzleNum - 1))
    CURRENT_PUZZLE_IDX = idx
    return getPuzzle(idx)
end

function getPuzzle(idx)
    return decodePuzzle(PUZZLES[idx])
end
