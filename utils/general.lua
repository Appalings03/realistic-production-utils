local gen_utils = {}

function gen_utils.normalize_name(name)
    return (string.lower(name):gsub(" ", "_"))
end

function gen_utils.trancate(name)

end

function gen_utils.icon_path(name, mod)
    folder = folder or "graphics"
    return "__realistic_production_assets__/" .. folder .. "/"
        .. gen_utils.normalize_name(name) .. ".png"
end

function gen_utils.add_proto(proto)
    local existing = data.raw[proto.type] and data.raw[proto.type][proto.name]
    if existing then
        log("Prototype ignoré (doublon) : " .. proto.type .. "/" .. proto.name)
        return false
    end
    data:extend({ proto })
    return true -- if true need to directly modify the factorio prototype
end

function gen_utils.copy_proto(type, name, overrides)
    local source = data.raw[type] and data.raw[type][name]
    assert(source, "copy_proto : " .. type .. "/" .. name .. " introuvable")
    local copy = table.deepcopy(source)
    for k, v in pairs(overrides or {}) do copy[k] = v end
    return copy
end

function gen_utils.get_settings(name)
    local s = settings.startup[name]
    return s and s.value
end

return gen_utils
