local mousegrabber = {}

function mousegrabber.run(cb, _cursor)
    if mousegrabber.callback == nil then
        mousegrabber.callback = cb
    else
        error("mousegrabber is already running")
    end
end

function mousegrabber.handle(info)
    if mousegrabber.callback == nil then return end
    if not mousegrabber.callback(info) then
        mousegrabber.callback = nil
    end
end

function mousegrabber.stop()
    mousegrabber.callback = nil
end

function mousegrabber.isrunning()
    return mousegrabber.callback ~= nil
end

return mousegrabber
