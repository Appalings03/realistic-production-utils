# TODO — fonctions du mod utils

Oct 9, 2026 · @Martin

## Général

À écrire en premier : toutes les autres fonctions appellent celles-ci.

- [X] `normalize_name(name)` : minuscules et `_` à la place des espaces
- [X] `icon_path(name)` : chemin de l'icône dans le mod assets
- [X] `add_prototype(proto)` : garde anti-doublons et `log` des prototypes ignorés
- [X] `copy_prototype(type, name, overrides)` : `deepcopy` d'un prototype vanilla, puis modifications
- [X] `get_setting(name)` : lecture des settings (densité, nodes purs)
- [ ] Need to change icon_path(name) into icon_path(name, path) with path being a global var for each mod

## Ore

Dans l'ordre où le mod ore en a besoin.

- [ ] `create_item{...}` : un seul générateur d'items, qui appelle `add_prototype`
- [ ] `create_fluid{...}` : gaz et saumures
- [ ] `create_group` et `create_subgroup` : onglets et familles du menu de craft
- [ ] `make_icons(name, tint)` : icône placeholder teintée par famille
- [ ] `create_resource{...}` : entité `resource` avec autoplace et densité
- [ ] `ing(name, amount, type)` et `res(...)` : ingrédients et résultats avec leur `type` (obligatoire en 2.0)
- [ ] `create_recipe{...}` : extraction, raffinage, séparation
- [ ] `create_technology{...}` : prérequis, recettes débloquées, coût en science

## Assets

Petits helpers, à écrire quand le mod assets contient des sons ou des sprites.

- [ ] `sound_path(name)` : chemin d'un son dans le mod assets
- [ ] Helper de sprites et d'animations pour les bâtiments, si le besoin se confirme

## Building

À écrire après la phase ore, quand tu passes aux machines.

- [ ] `create_building{base, ...}` : copie une machine vanilla, puis applique tes changements
- [ ] `create_recipe_category` et `create_crafting_category`
- [ ] `fluid_boxes(...)` : connexions de tuyaux
- [ ] `kw(n)` : convertit un nombre en `"nkW"` pour l'énergie
- [ ] `create_machine{...}` : item, entité et recette en un seul appel

## Main

Dernières à écrire : elles ne servent qu'à relier le mod au jeu de base.

- [ ] `remove_resource(name)` : retire l'autoplace d'un minerai vanilla
- [ ] `find_recipes_using(item)` : repère les recettes à adapter
- [ ] `replace_ingredient(recipe, old, new)`
- [ ] `hide_prototype` et `remove_recipe`
- [ ] `remove_tech_effect` et `fix_prerequisites`
- [ ] `scale_recipe(recipe, factor)` : équilibrage des quantités
