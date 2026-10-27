local general = require("utils.general")

local assets = {}
local ASSETS_ROOT = "__realistic_production_assets__/"

local function copy(value)
    if type(value) ~= "table" then return value end
    if table.deepcopy then return table.deepcopy(value) end

    local result = {}
    for key, child in pairs(value) do
        result[copy(key)] = copy(child)
    end
    return result
end

local function asset_path(name, folder, extension)
    assert(type(name) == "string" and name ~= "", "assets : nom de fichier manquant")
    assert(type(folder) == "string" and folder ~= "", "assets : dossier manquant")
    name = general.normalize_name(name)
    if name:sub(-#extension) ~= extension then
        name = name .. extension
    end
    return ASSETS_ROOT .. folder .. "/" .. name
end

function assets.sound_path(name, opts)
    opts = opts or {}
    return asset_path(name, opts.folder or "sounds", opts.extension or ".ogg")
end

function assets.sprite(name, opts)
    opts = copy(opts or {})
    local folder = opts.folder or "graphics/sprites"
    local extension = opts.extension or ".png"
    local spec = {
        filename = asset_path(name, folder, extension),
    }

    for key, value in pairs(opts) do
        if key ~= "folder" and key ~= "extension" then
            spec[key] = value
        end
    end
    return spec
end

function assets.animation(name, opts)
    opts = copy(opts or {})
    local animation = assets.sprite(name, opts)
    animation.frame_count = animation.frame_count or 1
    animation.line_length = animation.line_length or animation.frame_count
    return animation
end

return assets
