-- lua/dialogues/intro_001.lua
return {
    id = "intro_001",
    category = "story",
    
    sequences = {
        {
            id = "opening",
            type = "dialogue",
            lines = {
                {
                    speaker = "Narrateur",
                    text = "Dans le monde de Tárnor, les héros ne combattent jamais seuls...",
                    emotion = "neutral"
                },
                {
                    speaker = "Narrateur",
                    text = "Les liens entre guerriers peuvent devenir des armes dévastatrices, ou la clé de la victoire.",
                    emotion = "serious"
                },
                {
                    speaker = "Narrateur",
                    text = "Votre aventure commence maintenant. Choisissez vos compagnons avec soin !",
                    emotion = "hopeful"
                }
            }
        }
    }
}
