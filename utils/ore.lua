local general = require("utils.general")
local ore = {}

local PREFIX = "rp-"
local VANILLA_IDS = {
    item = {
        ["stone"] = true,
        ["iron-ore"] = true,
        ["copper-ore"] = true,
        ["uranium-ore"] = true,
        ["coal"] = true,
        ["iron-plate"] = true,
        ["copper-plate"] = true,
        ["steel-plate"] = true,
    },
    fluid = {
        ["crude-oil"] = true,
        ["water"] = true,
    },
    resource = {
        ["stone"] = true,
        ["iron-ore"] = true,
        ["copper-ore"] = true,
        ["uranium-ore"] = true,
        ["coal"] = true,
        ["crude-oil"] = true,
    },
}

-- Regarder pour par la suite (dernière phase ajouter les item/fluides/ressource de space age dans la liste) avec un if space-age then
-- cette condition sera placer dans un autre mod surement appeler realistic_production_space_age qui prendra le meme code que realistic_production_core
local INTERNAL_FIELDS = {
    associated_with = true,
    atomic = true,
    base = true,
    dev = true,
    extraction = true,
    form = true,
    ingredients = true,
    kind = true,
    level = true,
    name = true,
    name_en = true,
    name_fr = true,
    origin = true,
    picture = true,
    primary = true,
    prototype = true,
    size = true,
    symbol = true,
    tech = true,
    tint = true,
    type = true,
    vanilla = true,
    volatile = true,
    world = true,
}

local function assert_table(value, label)
    assert(type(value) == "table", label .. " doit être une table")
    return value
end

local function assert_name(name, label)
    assert(type(name) == "string" and name ~= "", label .. " : nom manquant")
    return general.normalize_name(name)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    if table.deepcopy then return table.deepcopy(value) end

    local result = {}
    for key, child in pairs(value) do
        result[copy(key)] = copy(child)
    end
    return result
end

local function copy_definition(definition)
    local prototype = copy(definition.prototype or {})
    for key, value in pairs(definition) do
        if key ~= "prototype" and not INTERNAL_FIELDS[key] then
            prototype[key] = copy(value)
        end
    end
    return prototype
end

local function prototype_name(name, prototype_type, vanilla)
    name = assert_name(name, prototype_type)
    if vanilla or name:sub(1, #PREFIX) == PREFIX then
        return name
    end
    return PREFIX .. name
end

local function qualify_reference(name, prototype_type)
    name = assert_name(name, prototype_type)
    local vanilla_ids = VANILLA_IDS[prototype_type]
    if name:sub(1, #PREFIX) == PREFIX or (vanilla_ids and vanilla_ids[name]) then
        return name
    end
    if data and data.raw and data.raw[prototype_type] and data.raw[prototype_type][name] then
        return name
    end
    return PREFIX .. name
end

local function use_dev_assets(definition)
    if definition.dev ~= nil then return definition.dev end
    if not settings or not settings.startup then return false end

    local setting = settings.startup["rp-dev-assets"] or settings.startup["Dev assets"]
    return setting and setting.value == true or false
end

local function register(prototype)
    assert(data and data.extend, "ore : l'API data:extend n'est pas disponible")
    return general.add_proto(prototype)
end

local function normalize_ingredient(entry, label)
    assert_table(entry, label)
    assert(type(entry.type) == "string" and entry.type ~= "", label .. " : type obligatoire")
    assert(entry.type == "item" or entry.type == "fluid", label .. " : type invalide")
    assert(type(entry.amount) == "number" and entry.amount > 0 and entry.amount < math.huge,
        label .. " : amount doit être un nombre positif fini")

    local result = copy(entry)
    result.name = qualify_reference(result.name, result.type)
    return result
end

local function normalize_result(entry, label)
    assert_table(entry, label)
    assert(type(entry.type) == "string" and entry.type ~= "", label .. " : type obligatoire")
    assert(entry.type == "item" or entry.type == "fluid", label .. " : type invalide")
    local has_exact_amount = type(entry.amount) == "number"
    local has_amount_range = type(entry.amount_min) == "number" and type(entry.amount_max) == "number"
    assert(has_exact_amount ~= has_amount_range,
        label .. " : amount ou amount_min/amount_max obligatoire")
    assert((entry.amount_min == nil) == (entry.amount_max == nil),
        label .. " : amount_min et amount_max doivent être fournis ensemble")
    assert((entry.amount == nil or entry.amount > 0) and
        (entry.amount_min == nil or entry.amount_min > 0) and
        (entry.amount_max == nil or entry.amount_max > 0) and
        (entry.amount == nil or entry.amount < math.huge) and
        (entry.amount_min == nil or entry.amount_min < math.huge) and
        (entry.amount_max == nil or entry.amount_max < math.huge),
        label .. " : les quantités doivent être positives")
    assert(entry.amount_min == nil or entry.amount_max == nil or entry.amount_min <= entry.amount_max,
        label .. " : amount_min doit être inférieur ou égal à amount_max")

    local result = copy(entry)
    result.name = qualify_reference(result.name, result.type)
    return result
end

local function normalize_recipe_fields(prototype)
    assert(type(prototype.ingredients) == "table", "create_recipe : ingredients obligatoires")
    assert(type(prototype.results) == "table", "create_recipe : results obligatoires")

    local ingredients, results = {}, {}
    for index, ingredient in ipairs(prototype.ingredients) do
        ingredients[index] = normalize_ingredient(ingredient, "create_recipe : ingredient #" .. index)
    end
    for index, result in ipairs(prototype.results) do
        results[index] = normalize_result(result, "create_recipe : résultat #" .. index)
    end
    prototype.ingredients = ingredients
    prototype.results = results
end

function ore.load_data(path)
    assert(type(path) == "string" and path ~= "", "load_data : chemin de module manquant")
    local definitions = require(path)
    assert(type(definitions) == "table", "load_data : " .. path .. " doit retourner une table")
    return definitions
end

function ore.make_icons(name, tint, opts)
    opts = copy(opts or {})
    if tint then opts.tint = tint end
    return general.icons(assert_name(name, "make_icons"), opts)
end

function ore.ing(name, amount, ingredient_type)
    assert(ingredient_type == "item" or ingredient_type == "fluid",
        "ing : type doit être 'item' ou 'fluid'")
    return normalize_ingredient({
        name = name,
        amount = amount,
        type = ingredient_type,
    }, "ing")
end

function ore.res(name, amount, result_type, options)
    assert(result_type == "item" or result_type == "fluid",
        "res : type doit être 'item' ou 'fluid'")
    assert(type(options) == "nil" or type(options) == "table", "res : options doit être une table")

    local result = copy(options or {})
    assert(result.name == nil and result.type == nil and result.amount == nil,
        "res : name, type et amount sont définis par les arguments")
    result.name = name
    result.amount = amount
    result.type = result_type
    return normalize_result(result, "res")
end

function ore.create_item(definition)
    assert_table(definition, "create_item")
    local name = assert_name(definition.name, "create_item")
    if definition.vanilla then return false end

    local prototype = copy_definition(definition)
    prototype.type = "item"
    prototype.name = prototype_name(name, "item", false)
    prototype.subgroup = prototype.subgroup and
        qualify_reference(prototype.subgroup, "item-subgroup") or nil
    if not prototype.icons and not prototype.icon then
        prototype.icons = ore.make_icons(prototype.name, definition.tint, {
            dev = use_dev_assets(definition),
            size = definition.size,
        })
    end
    prototype.icon_size = prototype.icon_size or 64
    prototype.stack_size = prototype.stack_size or definition.stack_size or 100
    assert(type(prototype.stack_size) == "number" and prototype.stack_size > 0 and
        prototype.stack_size % 1 == 0, "create_item : stack_size doit être un entier positif")
    return register(prototype)
end

function ore.create_fluid(definition)
    assert_table(definition, "create_fluid")
    local name = assert_name(definition.name, "create_fluid")
    if definition.vanilla then return false end
    assert(type(definition.base_color) == "table", "create_fluid : base_color obligatoire")
    assert(type(definition.flow_color) == "table", "create_fluid : flow_color obligatoire")
    for _, color in ipairs({definition.base_color, definition.flow_color}) do
        for _, channel in ipairs({"r", "g", "b"}) do
            assert(type(color[channel]) == "number" and color[channel] >= 0 and color[channel] <= 1,
                "create_fluid : les composantes RGB doivent être comprises entre 0 et 1")
        end
    end

    local prototype = copy_definition(definition)
    prototype.type = "fluid"
    prototype.name = prototype_name(name, "fluid", false)
    if prototype.default_temperature == nil then
        prototype.default_temperature = 15
    end
    assert(type(prototype.default_temperature) == "number" and
        prototype.default_temperature == prototype.default_temperature and
        prototype.default_temperature > -math.huge and
        prototype.default_temperature < math.huge,
        "create_fluid : default_temperature doit être un nombre fini")
    prototype.subgroup = prototype.subgroup and
        qualify_reference(prototype.subgroup, "item-subgroup") or nil
    if not prototype.icons and not prototype.icon then
        prototype.icons = ore.make_icons(prototype.name, definition.tint, {
            dev = use_dev_assets(definition),
        })
    end
    prototype.icon_size = prototype.icon_size or 64
    return register(prototype)
end

function ore.create_group(definition)
    assert_table(definition, "create_group")
    local name = assert_name(definition.name, "create_group")
    local prototype = copy_definition(definition)
    prototype.type = "item-group"
    prototype.name = prototype_name(name, "item-group", false)
    if not prototype.icon and not prototype.icons then
        prototype.icon = general.icon_path(prototype.name, {
            dev = use_dev_assets(definition),
            size = definition.size,
        })
    end
    prototype.icon_size = prototype.icon_size or 64
    return register(prototype)
end

function ore.create_subgroup(definition)
    assert_table(definition, "create_subgroup")
    local name = assert_name(definition.name, "create_subgroup")
    assert(type(definition.group) == "string" and definition.group ~= "",
        "create_subgroup : groupe parent obligatoire")

    local prototype = copy_definition(definition)
    prototype.type = "item-subgroup"
    prototype.name = prototype_name(name, "item-subgroup", false)
    prototype.group = qualify_reference(definition.group, "item-group")
    return register(prototype)
end

function ore.create_resource(definition)
    assert_table(definition, "create_resource")
    local name = assert_name(definition.name, "create_resource")
    if definition.world ~= nil then
        assert(type(definition.world) == "boolean",
            "create_resource : world doit être un booléen")
    end
    if definition.vanilla or definition.world == false then return false end

    local prototype = copy_definition(definition)
    prototype.type = "resource"
    prototype.name = prototype_name(name, "resource", false)
    prototype.category = prototype.category and
        qualify_reference(prototype.category, "resource-category") or nil
    assert(type(prototype.minable) == "table", "create_resource : minable obligatoire")
    assert(type(prototype.minable.results) == "table",
        "create_resource : minable.results obligatoire (Factorio 2.x)")
    assert(#prototype.minable.results > 0, "create_resource : minable.results ne peut pas être vide")
    assert(type(prototype.stages) == "table", "create_resource : stages obligatoire")
    assert(type(prototype.map_color) == "table", "create_resource : map_color obligatoire")

    local results = {}
    for index, result in ipairs(prototype.minable.results) do
        results[index] = normalize_result(result, "create_resource : minable.results #" .. index)
    end
    prototype.minable.results = results
    return register(prototype)
end

function ore.create_recipe(definition)
    assert_table(definition, "create_recipe")
    local name = assert_name(definition.name, "create_recipe")
    local prototype = copy_definition(definition)
    prototype.type = "recipe"
    prototype.name = prototype_name(name, "recipe", false)
    prototype.ingredients = copy(definition.ingredients)
    prototype.category = prototype.category and
        qualify_reference(prototype.category, "recipe-category") or nil
    normalize_recipe_fields(prototype)
    if prototype.main_product then
        local product_type = "item"
        for _, result in ipairs(prototype.results) do
            if result.name == prototype.main_product or
                result.name == qualify_reference(prototype.main_product, result.type) then
                product_type = result.type
                break
            end
        end
        prototype.main_product = qualify_reference(prototype.main_product, product_type)
    end
    return register(prototype)
end

function ore.create_technology(definition)
    assert_table(definition, "create_technology")
    local name = assert_name(definition.name, "create_technology")
    local prototype = copy_definition(definition)
    prototype.type = "technology"
    prototype.name = prototype_name(name, "technology", false)
    assert(type(prototype.unit) == "table", "create_technology : unit obligatoire")
    if not prototype.icons and not prototype.icon then
        prototype.icons = ore.make_icons(prototype.name, definition.tint, {
            dev = use_dev_assets(definition),
        })
    end
    prototype.icon_size = prototype.icon_size or 64

    if prototype.prerequisites then
        assert(type(prototype.prerequisites) == "table",
            "create_technology : prerequisites doit être une table")
        local prerequisites = {}
        for index, prerequisite in ipairs(prototype.prerequisites) do
            prerequisites[index] = qualify_reference(prerequisite, "technology")
        end
        prototype.prerequisites = prerequisites
    end

    if prototype.effects then
        assert(type(prototype.effects) == "table", "create_technology : effects doit être une table")
        for _, effect in ipairs(prototype.effects) do
            assert(type(effect) == "table", "create_technology : effet invalide")
            if effect.type == "unlock-recipe" then
                effect.recipe = qualify_reference(effect.recipe, "recipe")
            end
        end
    end
    return register(prototype)
end

return ore
