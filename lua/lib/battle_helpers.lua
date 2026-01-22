-- lua/lib/battle_helpers.lua
-- Fonctions réutilisables pour créer des données

local Helpers = {}

-- Créer une unité facilement
function Helpers.create_unit(name, x, y, hp, atk, def, mov, range, color)
    return {
        name = name,
        position = {x = x, y = y},
        stats = {
            hp = hp,
            attack = atk,
            defense = def,
            movement = mov,
            range = range
        },
        color = color or {r = 0.5, g = 0.5, b = 0.5, a = 1.0}
    }
end

-- Créer un gobelin standard
function Helpers.create_goblin(name, x, y)
    return Helpers.create_unit(
        name, x, y,
        60,  -- hp
        20,  -- attack
        10,  -- defense
        5,   -- movement
        1,   -- range
        {r = 0.7, g = 0.2, b = 0.2, a = 1.0}
    )
end

return Helpers