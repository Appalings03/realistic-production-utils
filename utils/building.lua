local general = require("utils.general")
local ore = require("utils.ore")

local building = {}
local PREFIX = "rp-"

local function copy(value)
    if type(value) ~= "table" then return value end
    if table.deepcopy then return table.deepcopy(value) end

    local result = {}
    for key, child in pairs(value) do
        result[copy(key)] = copy(child)
    end
    return result
end

local function assert_name(name, label)
    assert(type(name) == "string" and name ~= "", label .. " : nom manquant")
    return general.normalize_name(name)
end

local function prototype_name(name)
    name = assert_name(name, "building")
    if name:sub(1, #PREFIX) == PREFIX then return name end
    return PREFIX .. name
end

local function register(prototype)
    assert(data and data.extend, "building : l'API data:extend n'est pas disponible")
    return general.add_proto(prototype)
end

local function build_from_definition(definition, default_type)
    assert(type(definition) == "table", "building : définition attendue")
    local name = prototype_name(definition.name)
    local entity_type = definition.entity_type or default_type or definition.type
    assert(type(entity_type) == "string" and entity_type ~= "",
        "building : entity_type obligatoire")

    local prototype
    if definition.base then
        assert(type(definition.base) == "string" and definition.base ~= "",
            "building : base doit être un nom de prototype")
        prototype = general.copy_proto(entity_type, definition.base)
    else
        prototype = copy(definition.prototype or {})
    end

    for key, value in pairs(definition) do
        if key ~= "base" and key ~= "entity_type" and key ~= "prototype" and
            key ~= "name" and key ~= "type" then
            prototype[key] = copy(value)
        end
    end
    prototype.type = entity_type
    prototype.name = name
    return prototype
end

function building.create_recipe_category(name, order)
    local prototype = {
        type = "recipe-category",
        name = prototype_name(name),
    }
    if order ~= nil then
        assert(type(order) == "string", "create_recipe_category : order doit être une chaîne")
        prototype.order = order
    end
    return register(prototype)
end

function building.create_crafting_category(name, order)
    return building.create_recipe_category(name, order)
end

function building.fluid_boxes(boxes)
    assert(type(boxes) == "table", "fluid_boxes : une table de fluid boxes est obligatoire")
    local result = {}
    for index, box in ipairs(boxes) do
        assert(type(box) == "table", "fluid_boxes : entrée #" .. index .. " invalide")
        assert(box.production_type == "input" or box.production_type == "output" or
            box.production_type == "input-output",
            "fluid_boxes : production_type invalide à l'entrée #" .. index)
        assert(type(box.pipe_connections) == "table" and #box.pipe_connections > 0,
            "fluid_boxes : pipe_connections obligatoire à l'entrée #" .. index)
        result[index] = copy(box)
    end
    return result
end

function building.kw(amount)
    assert(type(amount) == "number" and amount > 0 and amount < math.huge,
        "kw : la puissance doit être un nombre positif fini")
    return tostring(amount) .. "kW"
end

function building.create_building(definition)
    local prototype = build_from_definition(definition)
    assert(prototype.type ~= "item" and prototype.type ~= "recipe" and
        prototype.type ~= "technology",
        "create_building : type d'entité attendu")
    return register(prototype)
end

function building.create_machine(definition)
    assert(type(definition) == "table", "create_machine : définition attendue")
    local prototype = build_from_definition(definition, "assembling-machine")

    assert(type(prototype.crafting_categories) == "table" and
        #prototype.crafting_categories > 0,
        "create_machine : crafting_categories obligatoire")
    assert(type(prototype.crafting_speed) == "number" and
        prototype.crafting_speed > 0 and prototype.crafting_speed < math.huge,
        "create_machine : crafting_speed doit être positif")
    assert(type(prototype.energy_source) == "table",
        "create_machine : energy_source obligatoire")
    if prototype.energy_usage == nil and definition.energy_usage_kw ~= nil then
        prototype.energy_usage = building.kw(definition.energy_usage_kw)
    end
    assert(type(prototype.energy_usage) == "string" and prototype.energy_usage ~= "",
        "create_machine : energy_usage ou energy_usage_kw obligatoire")
    prototype.energy_usage_kw = nil

    for index, category in ipairs(prototype.crafting_categories) do
        assert(type(category) == "string" and category ~= "",
            "create_machine : crafting_categories invalide à l'entrée #" .. index)
        if category:sub(1, #PREFIX) ~= PREFIX and
            not (data.raw["recipe-category"] and data.raw["recipe-category"][category]) then
            prototype.crafting_categories[index] = PREFIX .. general.normalize_name(category)
        end
    end

    if prototype.fluid_boxes then
        prototype.fluid_boxes = building.fluid_boxes(prototype.fluid_boxes)
    end
    if not prototype.icons and not prototype.icon then
        prototype.icons = ore.make_icons(prototype.name, definition.tint, {
            dev = definition.dev,
            size = definition.size,
        })
    end
    prototype.icon_size = prototype.icon_size or 64
    return register(prototype)
end

return building
