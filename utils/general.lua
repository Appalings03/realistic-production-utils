local gen_utils = {}

function gen_utils.normalize_name(name)
    return (string.lower(name):gsub(" ", "-"))
end

-- utils/general.lua : remplace l'ancien gen_utils.icon_path (et gen_utils.trancate, à supprimer)

local ASSETS_ROOT = "__realistic_production_assets__/graphics/"

-- Tailles disponibles dans graphics/dev/ (<taille>_item.png en 64x64, <taille>_picture.png en 256x256)
local DEV_SIZES = { ["1x1"] = true, ["2x2"] = true, ["3x3"] = true, ["3x5"] = true }

--- Chemin d'un PNG du mod assets.
--- @param name string  nom du prototype (normalisé automatiquement)
--- @param opts table?  { folder = "items", dev = false, size = "1x1", picture = false }
---   folder  : sous-dossier de graphics/ (défaut "items")
---   dev     : true -> image de test commune (graphics/dev/), `name` est ignoré
---   size    : taille de l'image de test ("1x1", "2x2", "3x3", "3x5")
---   picture : true -> version 256x256 (entités) au lieu de l'icône 64x64
function gen_utils.icon_path(name, opts)
    opts = opts or {}

    if opts.dev then
        local size = opts.size or "1x1"
        assert(DEV_SIZES[size], "icon_path : taille de test inconnue : " .. tostring(size))
        return ASSETS_ROOT .. "dev/" .. size .. (opts.picture and "_picture" or "_item") .. ".png"
    end

    assert(name, "icon_path : name manquant")
    local folder = opts.folder or "items"
    return ASSETS_ROOT .. folder .. "/" .. gen_utils.normalize_name(name) .. ".png"
end

--- Table `icons` prête à mettre dans un prototype (avec teinte optionnelle).
--- @param name string
--- @param opts table? mêmes options que icon_path + { tint = {r=,g=,b=,a=} }
function gen_utils.icons(name, opts)
    opts = opts or {}
    local layer = {
        icon = gen_utils.icon_path(name, opts),
        icon_size = 64,
    }
    if opts.tint then layer.tint = opts.tint end
    return { layer }
end

-- Utilisation côté ore (le setting est lu par ore, pas par utils) :
--   local dev = gen_utils.get_settings("rp-placeholder-icons")
--   icons = gen_utils.icons(item.name, { dev = dev, folder = "items", tint = TINTS[item.kind] })

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
