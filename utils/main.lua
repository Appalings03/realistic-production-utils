local general = require("utils.general")

local main = {}
local PREFIX = "rp-"
local ITEM_TYPES = {
    ammo = true,
    armor = true,
    ["artillery-flare"] = true,
    ["artillery-shell"] = true,
    ["blueprint-book"] = true,
    blueprint = true,
    ["copy-paste-tool"] = true,
    capsule = true,
    ["deconstruction-item"] = true,
    ["item-with-entity-data"] = true,
    ["item-with-inventory"] = true,
    ["item-with-label"] = true,
    ["item-with-tags"] = true,
    item = true,
    module = true,
    ["rail-planner"] = true,
    ["selection-tool"] = true,
    ["spidertron-remote"] = true,
    tool = true,
}

local function assert_name(name, label)
    assert(type(name) == "string" and name ~= "", label .. " : nom manquant")
    return general.normalize_name(name)
end

local function qualify_item_name(name, item_type)
    name = assert_name(name, "replace_ingredient")
    if name:sub(1, #PREFIX) == PREFIX then return name end
    local prototypes = data.raw[item_type] or {}
    if prototypes[name] then return name end
    return PREFIX .. name
end

local function resolve_name(prototype_type, name)
    name = assert_name(name, prototype_type)
    local prototypes = data.raw[prototype_type]
    if prototypes and prototypes[name] then return name end
    if name:sub(1, #PREFIX) ~= PREFIX and prototypes and prototypes[PREFIX .. name] then
        return PREFIX .. name
    end
    error(prototype_type .. "/" .. name .. " introuvable")
end

local function recipe_uses(recipe, name, ingredient_type)
    for _, ingredient in ipairs(recipe.ingredients or {}) do
        local ingredient_name = type(ingredient) == "table" and
            (ingredient.name or ingredient[1]) or nil
        local kind = type(ingredient) == "table" and ingredient.type or nil
        if ingredient_name == name and (ingredient_type == nil or kind == ingredient_type) then
            return true
        end
    end
    return false
end

local function sorted_recipe_names()
    local names = {}
    for name in pairs(data.raw.recipe or {}) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local function recipe_ingredient_kind(ingredient)
    if type(ingredient) == "table" and ingredient.type then
        return ingredient.type
    end
    return "item"
end

local function validate_scale_product(product, factor, label)
    assert(type(product) == "table", label .. " doit être une table")
    local scaled = false
    for _, key in ipairs({"amount", "amount_min", "amount_max"}) do
        if product[key] ~= nil then
            assert(type(product[key]) == "number" and product[key] > 0 and
                product[key] < math.huge,
                label .. "." .. key .. " doit être un nombre positif fini")
            local result = product[key] * factor
            assert(result > 0 and result < math.huge,
                label .. "." .. key .. " produit une quantité non finie ou nulle")
            scaled = true
        end
    end
    assert(scaled, label .. " ne contient aucune quantité à ajuster")
end

local function scale_product(product, factor)
    for _, key in ipairs({"amount", "amount_min", "amount_max"}) do
        if product[key] ~= nil then
            product[key] = product[key] * factor
        end
    end
end

function main.remove_resource(name)
    local prototype_name = resolve_name("resource", name)
    data.raw.resource[prototype_name] = nil
    return true
end

function main.find_recipes_using(name, ingredient_type)
    name = assert_name(name, "find_recipes_using")
    assert(ingredient_type == nil or ingredient_type == "item" or ingredient_type == "fluid",
        "find_recipes_using : type doit être 'item', 'fluid' ou nil")
    local candidates = {name}
    if name:sub(1, #PREFIX) ~= PREFIX then
        candidates[#candidates + 1] = PREFIX .. name
    end

    local matches = {}
    for _, recipe_name in ipairs(sorted_recipe_names()) do
        local recipe = data.raw.recipe[recipe_name]
        for _, candidate in ipairs(candidates) do
            if recipe_uses(recipe, candidate, ingredient_type) then
                matches[#matches + 1] = recipe
                break
            end
        end
    end
    return matches
end

function main.replace_ingredient(old_name, new_ingredient, ingredient_type)
    old_name = assert_name(old_name, "replace_ingredient")
    assert(type(new_ingredient) == "string" or type(new_ingredient) == "table",
        "replace_ingredient : nouvel ingrédient invalide")
    assert(ingredient_type == nil or ingredient_type == "item" or ingredient_type == "fluid",
        "replace_ingredient : type doit être 'item', 'fluid' ou nil")

    local replacements = {old_name}
    if old_name:sub(1, #PREFIX) ~= PREFIX then
        replacements[#replacements + 1] = PREFIX .. old_name
    end
    local new_name, new_type
    if type(new_ingredient) == "string" then
        new_name = assert_name(new_ingredient, "replace_ingredient")
    else
        assert(type(new_ingredient.name) == "string" and new_ingredient.name ~= "",
            "replace_ingredient : nouvel ingrédient sans nom")
        new_name = assert_name(new_ingredient.name, "replace_ingredient")
        new_type = new_ingredient.type
        assert(new_type == nil or new_type == "item" or new_type == "fluid",
            "replace_ingredient : type du nouvel ingrédient invalide")
    end

    local changed = 0
    for _, recipe_name in ipairs(sorted_recipe_names()) do
        local recipe = data.raw.recipe[recipe_name]
        for _, ingredient in ipairs(recipe.ingredients or {}) do
            local existing_name = type(ingredient) == "table" and
                (ingredient.name or ingredient[1]) or nil
            local existing_type = recipe_ingredient_kind(ingredient)
            local matched = false
            for _, candidate in ipairs(replacements) do
                if existing_name == candidate and
                    (ingredient_type == nil or existing_type == ingredient_type) then
                    matched = true
                    break
                end
            end

            if matched then
                if type(ingredient) == "table" then
                    if ingredient.name ~= nil then
                        ingredient.name = qualify_item_name(new_name, new_type or existing_type)
                    else
                        ingredient[1] = qualify_item_name(new_name, new_type or existing_type)
                    end
                    if new_type then ingredient.type = new_type end
                    if type(new_ingredient) == "table" and new_ingredient.amount ~= nil then
                        ingredient.amount = new_ingredient.amount
                    end
                else
                    error("replace_ingredient : format d'ingrédient non pris en charge dans " ..
                        recipe_name)
                end
                changed = changed + 1
            end
        end
    end
    return changed
end

function main.hide_prototype(prototype_type, name)
    local prototype_name = resolve_name(prototype_type, name)
    local prototype = data.raw[prototype_type][prototype_name]
    if ITEM_TYPES[prototype_type] then
        prototype.flags = prototype.flags or {}
        for _, flag in ipairs(prototype.flags) do
            if flag == "hidden" then return false end
        end
        prototype.flags[#prototype.flags + 1] = "hidden"
    elseif prototype_type == "recipe" or prototype_type == "technology" then
        prototype.hidden = true
    else
        error("hide_prototype : type non pris en charge : " .. prototype_type)
    end
    return true
end

function main.remove_recipe(name)
    local prototype_name = resolve_name("recipe", name)
    data.raw.recipe[prototype_name] = nil
    return true
end

function main.remove_tech_effect(technology_name, effect_type, target)
    local prototype_name = resolve_name("technology", technology_name)
    assert(type(effect_type) == "string" and effect_type ~= "",
        "remove_tech_effect : type d'effet obligatoire")
    local technology = data.raw.technology[prototype_name]
    assert(type(technology.effects) == "table",
        "remove_tech_effect : la technologie n'a pas de table effects")

    local target_name
    if target ~= nil then
        target_name = assert_name(target, "remove_tech_effect")
    end
    local kept, removed = {}, 0
    for _, effect in ipairs(technology.effects) do
        local target_matches = target_name == nil
        if target_name then
            for _, field in ipairs({"recipe", "item", "technology", "entity", "fluid", "name"}) do
                if effect[field] == target_name or effect[field] == PREFIX .. target_name then
                    target_matches = true
                    break
                end
            end
        end
        local matches = effect.type == effect_type and target_matches
        if matches then
            removed = removed + 1
        else
            kept[#kept + 1] = effect
        end
    end
    technology.effects = kept
    return removed
end

function main.fix_prerequisites(removed_technology, replacement_technology)
    removed_technology = assert_name(removed_technology, "fix_prerequisites")
    local removed_names = {[removed_technology] = true}
    if removed_technology:sub(1, #PREFIX) == PREFIX then
        removed_names[removed_technology:sub(#PREFIX + 1)] = true
    else
        removed_names[PREFIX .. removed_technology] = true
    end
    local replacement_name
    if replacement_technology ~= nil then
        replacement_name = resolve_name("technology", replacement_technology)
        assert(not removed_names[replacement_name],
            "fix_prerequisites : une technologie ne peut pas se remplacer elle-même")
    end

    local changed = 0
    for technology_name, technology in pairs(data.raw.technology or {}) do
        local prerequisites = technology.prerequisites or {}
        local updated, seen, touched = {}, {}, false
        for _, prerequisite in ipairs(prerequisites) do
            local candidate = prerequisite
            if removed_names[prerequisite] then
                candidate = replacement_name
                touched = true
            end
            if candidate and candidate ~= technology_name and not seen[candidate] then
                updated[#updated + 1] = candidate
                seen[candidate] = true
            elseif candidate ~= nil then
                touched = touched or candidate ~= prerequisite
            end
        end
        if touched then
            technology.prerequisites = updated
            changed = changed + 1
        end
    end
    return changed
end

function main.scale_recipe(name, factor)
    local prototype_name = resolve_name("recipe", name)
    assert(type(factor) == "number" and factor > 0 and factor < math.huge,
        "scale_recipe : facteur doit être un nombre positif fini")
    local recipe = data.raw.recipe[prototype_name]
    assert(type(recipe.ingredients) == "table" and type(recipe.results) == "table",
        "scale_recipe : recette sans ingredients ou results")

    for index, ingredient in ipairs(recipe.ingredients) do
        validate_scale_product(ingredient, factor, "scale_recipe : ingredient #" .. index)
    end
    for index, result in ipairs(recipe.results) do
        validate_scale_product(result, factor, "scale_recipe : résultat #" .. index)
    end
    for _, ingredient in ipairs(recipe.ingredients) do
        scale_product(ingredient, factor)
    end
    for _, result in ipairs(recipe.results) do
        scale_product(result, factor)
    end
    return true
end

return main
