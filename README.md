# Realistic Production Utils

Shared helpers for the Realistic Production Factorio mods.

## Using `utils.general`

Require the module from another mod with its Factorio mod name:

```lua
local general = require("__realistic_production_utils__.utils.general")

local name = general.normalize_name("Stainless Steel") -- "stainless-steel"
local icon = general.icons("rp-hematite")
```

`normalize_name` lowercases text and replaces spaces and underscores with hyphens. It does not add the `rp-` prefix.

## Prototype names

- Use lowercase names with hyphens; do not use underscores.
- Prefix every prototype created by Realistic Production with `rp-` (for example, `rp-hematite`).
- Keep vanilla prototype IDs unchanged when reusing them (for example, `iron-ore`).
- Keep source data names short and unprefixed; the data-stage loader is responsible for adding `rp-` to non-vanilla prototype IDs.

The prefix belongs to the prototype ID, so a normal icon lookup for `rp-hematite` resolves to `graphics/items/rp-hematite.png`.

## Ore prototype helpers

The ore helper module is loaded with:

```lua
local ore = require("__realistic_production_utils__.utils.ore")
local resources = ore.load_data("__realistic_production_ore__.prototypes.resources.resources_data")

ore.create_item(resources[1])
```

Data rows keep their short names. The constructors add `rp-` to new prototype IDs, prefix subgroup and group references, and leave the seven configured vanilla resource IDs unchanged. Mark vanilla rows with `vanilla = true` so `create_item`, `create_fluid`, and `create_resource` skip creating duplicates.

Recipes use Factorio 2.x ingredient/result records, each with an explicit `type`:

```lua
ore.create_recipe{
    name = "crushing-hematite",
    category = "rp-crushing",
    ingredients = { ore.ing("hematite", 1, "item") },
    results = { ore.res("iron-ore", 1, "item") },
    energy_required = 2,
}
```

`create_recipe` preserves the supplied `ingredients` field while filtering data-only fields from the prototype.

`create_fluid` requires `base_color` and `flow_color`; `default_temperature` defaults to 15 and can be overridden in the definition. Unless `dev` is explicitly provided, item, fluid, recipe, and technology icons follow the `rp-dev-assets` startup setting. `create_resource` requires complete `minable.results`, `stages`, and `map_color` definitions; callers provide their intended autoplace settings. It skips vanilla resources and rows marked `world = false`, which represent products rather than deposits. `create_technology` requires a `unit` and prefixes custom prerequisite technology and unlocked recipe references. Item groups use development placeholders by default until group art is supplied.

Constructors return `true` when the prototype was registered and `false` when an existing prototype caused it to be skipped (with the skip logged by the shared helper).

## Asset helpers

```lua
local assets = require("__realistic_production_utils__.utils.assets")

local sound = assets.sound_path("crusher-running")
local sprite = assets.sprite("crusher", {width = 128, height = 128})
local animation = assets.animation("crusher-working", {
    width = 128, height = 128, frame_count = 8, line_length = 4,
})
```

Paths resolve inside the shared assets mod (`sounds/` for sound files and `graphics/sprites/` for sprites by default). Pass `folder` and `extension` to select another subfolder or file type. `sprite` and `animation` return prototype field tables; they do not register prototypes.

## Building helpers

```lua
local building = require("__realistic_production_utils__.utils.building")

building.create_recipe_category("crushing")
local boxes = building.fluid_boxes({
    {production_type = "input", pipe_connections = {{flow_direction = "input", direction = defines.direction.north, position = {0, -2}}}},
})
building.create_machine{
    name = "jaw-crusher",
    crafting_categories = {"crushing"},
    crafting_speed = 1,
    energy_source = {type = "electric", usage_priority = "secondary-input"},
    energy_usage_kw = 90,
    fluid_boxes = boxes,
}
```

`create_building` can copy an existing entity prototype with `base` and `entity_type`, then apply the remaining fields as overrides. `create_machine` creates an `assembling-machine` by default, requires crafting categories, speed, energy source and energy usage, prefixes custom categories and registers the prototype. Both helpers prefix newly created prototype IDs. `kw(n)` formats positive power values as Factorio strings such as `"90kW"`. `create_crafting_category` is an alias for `create_recipe_category`, since Factorio uses the `recipe-category` prototype type for both.

## Prototype cleanup helpers

```lua
local main = require("__realistic_production_utils__.utils.main")

local recipes = main.find_recipes_using("iron-ore", "item")
main.replace_ingredient("iron-ore", "rp-hematite", "item")
main.scale_recipe("rp-crushing-hematite", 2)
```

`find_recipes_using` returns matching recipe prototypes sorted by name. `replace_ingredient` replaces matching ingredient names in all recipes and returns the number changed; it preserves amounts unless a replacement table supplies a new `amount`. A replacement name is kept if it is already a prototype ID or vanilla item ID, otherwise it gets the `rp-` prefix. `scale_recipe` multiplies all ingredient and result amounts, but does not change crafting time. `remove_resource` and `remove_recipe` remove the named prototype from `data.raw`. `hide_prototype` supports item prototypes (via the `hidden` flag), recipes and technologies. `remove_tech_effect(technology, effect_type, target?)` removes matching effects. After deleting a technology, call `fix_prerequisites(removed, replacement?)` to remove its prerequisite references, optionally replacing them with an existing technology. Helpers that require a prototype fail explicitly when it is not found.
