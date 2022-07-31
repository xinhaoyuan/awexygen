local keygrabber = {}

function keygrabber.run(cb)
    if keygrabber.callback == nil then
        keygrabber.callback = cb
    else
        error("keygrabber is already running")
    end
end

function keygrabber.stop()
    keygrabber.callback = nil
end

function keygrabber.isrunning()
    return keygrabber.callback ~= nil
end

return keygrabber
