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
