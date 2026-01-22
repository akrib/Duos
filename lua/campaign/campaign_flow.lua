-- lua/campaign/campaign_flow.lua
-- Définit l'ordre des combats et la progression

return {
    chapters = {
        {
            id = 1,
            name = "Les Ombres de la Forêt",
            battles = {"tutorial", "forest_battle"}
        },
        {
            id = 2,
            name = "La Défense du Royaume",
            battles = {"village_defense"}
        },
        {
            id = 3,
            name = "Le Chef de Guerre",
            battles = {"boss_fight"}
        }
    }
}