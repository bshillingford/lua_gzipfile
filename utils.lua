local utils = {}

-- based on the behaviour of PL
function utils.class(name)
    local class = {}
    class._class = class
    class._classname = name
    setmetatable(class, {
        __call = function(class_tbl, ...)
            local self = {}
            setmetatable(self, class)
            self:_init(...)
            return self
        end
    })
    class.__index = class
    return class
end

return utils
