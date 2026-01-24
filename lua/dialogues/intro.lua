-- lua/dialogues/intro.lua
-- Dialogues d'introduction de la campagne

return {
    id = "intro",
    title = "Le Royaume en Péril",
    
    -- Configuration
    auto_advance = false,  -- Avancer automatiquement après X secondes
    auto_advance_delay = 3.0,
    skippable = true,
    
    -- Séquences de dialogue
    sequences = {
        -- Scène 1 : Narration d'ouverture
        {
            id = "opening_narration",
            type = "narration",
            background = "res://assets/backgrounds/kingdom_overview.png",
            music = "res://audio/music/intro_dramatic.ogg",
            
            lines = {
                {
                    text = "Le royaume de Valoria connaît une ère de paix depuis trois générations...",
                    duration = 4.0
                },
                {
                    text = "Mais dans l'ombre de la Forêt Noire, une menace grandit.",
                    duration = 4.0
                },
                {
                    text = "Des créatures autrefois paisibles deviennent agressives.",
                    duration = 4.0
                },
                {
                    text = "Les villages frontaliers envoient des appels à l'aide désespérés.",
                    duration = 4.0
                }
            }
        },
        
        -- Scène 2 : Salle du trône
        {
            id = "throne_room",
            type = "conversation",
            background = "res://assets/backgrounds/throne_room.png",
            music = "res://audio/music/royal_theme.ogg",
            
            participants = {
                {
                    id = "king",
                    name = "Roi Alderon",
                    portrait = "res://assets/portraits/king_alderon.png",
                    position = "left",
                    color = {r = 0.8, g = 0.7, b = 0.3, a = 1.0}
                },
                {
                    id = "gaheris",
                    name = "Sir Gaheris",
                    portrait = "res://assets/portraits/gaheris.png",
                    position = "right",
                    color = {r = 0.2, g = 0.3, b = 0.8, a = 1.0}
                }
            },
            
            lines = {
                {
                    speaker = "king",
                    text = "Sir Gaheris, la situation devient critique. Les gobelins attaquent nos villages.",
                    emotion = "worried"
                },
                {
                    speaker = "king",
                    text = "Ils semblent organisés, comme si quelqu'un les dirigeait...",
                    emotion = "thoughtful"
                },
                {
                    speaker = "gaheris",
                    text = "Votre Majesté, donnez-moi vos ordres. Je protégerai le royaume.",
                    emotion = "determined"
                },
                {
                    speaker = "king",
                    text = "Prends avec toi Elara et le Père Aldric. Enquêtez sur ces attaques.",
                    emotion = "serious"
                },
                {
                    speaker = "king",
                    text = "Commencez par le village de Fernwood. Ils ont signalé une embuscade hier.",
                    emotion = "concerned"
                },
                {
                    speaker = "gaheris",
                    text = "Ce sera fait, Sire. Nous découvrirons ce qui se trame.",
                    emotion = "confident",
                    action = "salute"
                }
            }
        },
        
        -- Scène 3 : Départ du groupe
        {
            id = "party_departs",
            type = "conversation",
            background = "res://assets/backgrounds/castle_gates.png",
            music = "res://audio/music/adventure_begins.ogg",
            
            participants = {
                {
                    id = "gaheris",
                    name = "Sir Gaheris",
                    portrait = "res://assets/portraits/gaheris.png",
                    position = "left"
                },
                {
                    id = "elara",
                    name = "Elara l'Archère",
                    portrait = "res://assets/portraits/elara.png",
                    position = "center"
                },
                {
                    id = "aldric",
                    name = "Père Aldric",
                    portrait = "res://assets/portraits/aldric.png",
                    position = "right"
                }
            },
            
            lines = {
                {
                    speaker = "elara",
                    text = "Fernwood est à deux jours de marche. Nous devrions nous mettre en route.",
                    emotion = "ready"
                },
                {
                    speaker = "aldric",
                    text = "Que la lumière divine guide nos pas et protège les innocents.",
                    emotion = "solemn",
                    action = "pray"
                },
                {
                    speaker = "gaheris",
                    text = "En route, mes amis. L'aventure nous attend !",
                    emotion = "determined",
                    action = "forward"
                }
            }
        }
    },
    
    -- Choix de dialogue (optionnel)
    choices = {
        {
            id = "accept_mission",
            prompt = "Accepter la mission du roi ?",
            options = {
                {
                    text = "Oui, je défendrai le royaume !",
                    next_sequence = "party_departs",
                    flags = {"mission_accepted"}
                },
                {
                    text = "Je dois me préparer d'abord...",
                    next_sequence = "preparation",
                    flags = {"needs_preparation"}
                }
            }
        }
    },
    
    -- Événements déclenchés
    events = {
        on_start = {
            {type = "set_flag", flag = "intro_started"},
            {type = "fade_in", duration = 2.0}
        },
        on_complete = {
            {type = "set_flag", flag = "intro_complete"},
            {type = "unlock_battle", battle_id = "tutorial"},
            {type = "fade_out", duration = 1.5}
        }
    }
}
