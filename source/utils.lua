function range(from, to, step)
    step = step or 1
    return function(_, lastvalue)
        local nextvalue = lastvalue + step
        if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
            step == 0
        then
            return nextvalue
        end
    end, nil, from - step
end

function getSignDelta(prev, curr)
    return (prev < curr) and 1 or ((prev > curr) and -1 or 0)
end
