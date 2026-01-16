# Diagrammes du Système de Chargement

## 1. Flux de Chargement de Scène

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant Scene as Scène Actuelle
    participant EB as EventBus
    participant GM as GameManager
    participant SL as SceneLoader
    participant SR as SceneRegistry
    participant NS as Nouvelle Scène

    User->>Scene: Clic sur bouton
    Scene->>EB: change_scene(BATTLE)
    EB->>GM: scene_change_requested(BATTLE)
    GM->>SR: get_scene_path(BATTLE)
    SR-->>GM: "res://scenes/battle/battle.tscn"
    GM->>SL: load_scene(path, transition=true)
    
    Note over SL: Fade out
    SL->>SL: _disconnect_scene_signals()
    SL->>Scene: queue_free()
    
    Note over SL: Chargement asynchrone
    SL->>SL: ResourceLoader.load_threaded_request()
    loop Progression
        SL->>EB: scene_loading_progress(0.5)
    end
    
    SL->>NS: instantiate()
    SL->>NS: add_child()
    SL->>SL: _auto_connect_signals()
    
    Note over SL: Fade in
    SL->>EB: scene_loaded(new_scene)
    SL->>EB: scene_transition_finished()
    
    NS->>EB: Connexions aux signaux
    EB-->>NS: Prêt à recevoir des événements
```

## 2. Auto-Connexion des Signaux

```mermaid
flowchart TD
    A[SceneLoader charge une scène] --> B{enable_auto_signal_connection?}
    B -->|Non| Z[Fin]
    B -->|Oui| C[Appel de _auto_connect_signals]
    
    C --> D{Scène a _get_signal_connections?}
    D -->|Non| Z
    D -->|Oui| E[Récupérer la liste des connexions]
    
    E --> F[Pour chaque connexion...]
    F --> G{Signal existe?}
    G -->|Non| H[Warning]
    H --> F
    
    G -->|Oui| I{Méthode existe?}
    I -->|Non| H
    I -->|Oui| J{Déjà connecté?}
    
    J -->|Oui| F
    J -->|Non| K[Connecter le signal]
    K --> L[Log si debug_mode]
    L --> F
    
    F --> Z[Fin]
```

## 3. Communication via EventBus

```mermaid
flowchart LR
    subgraph "Scène Combat"
        SC[BattleScene]
    end
    
    subgraph "EventBus Global"
        EB[EventBus<br/>Signaux Globaux]
    end
    
    subgraph "Scène UI"
        UI[UIPanel]
    end
    
    subgraph "Scène Stats"
        ST[StatsTracker]
    end
    
    SC -->|duo_formed.emit| EB
    SC -->|unit_attacked.emit| EB
    SC -->|divine_points_gained.emit| EB
    
    EB -.->|safe_connect| UI
    EB -.->|safe_connect| ST
    
    UI -.->|Affichage| U1[Notification]
    ST -.->|Tracking| S1[Base de données]
```

## 4. Architecture Globale

```mermaid
graph TB
    subgraph "Autoloads (Singletons)"
        EB[EventBus<br/>Communication]
        GM[GameManager<br/>Orchestration]
    end
    
    subgraph "Core Systems"
        SL[SceneLoader<br/>Chargement]
        SR[SceneRegistry<br/>Catalogue]
    end
    
    subgraph "Scènes Indépendantes"
        M[Menus]
        W[Monde]
        B[Combat]
        N[Narration]
    end
    
    GM --> SL
    GM --> SR
    GM --> EB
    
    SL -.->|Charge| M
    SL -.->|Charge| W
    SL -.->|Charge| B
    SL -.->|Charge| N
    
    M -.->|Communique| EB
    W -.->|Communique| EB
    B -.->|Communique| EB
    N -.->|Communique| EB
    
    EB -.->|Notifie| M
    EB -.->|Notifie| W
    EB -.->|Notifie| B
    EB -.->|Notifie| N
```

## 5. Cycle de Vie d'une Scène

```mermaid
stateDiagram-v2
    [*] --> Requested: EventBus.change_scene()
    Requested --> Loading: GameManager.load_scene_by_id()
    Loading --> FadeOut: SceneLoader démarre
    
    FadeOut --> Cleanup: Transition terminée
    Cleanup --> Destroyed: queue_free() ancienne scène
    Destroyed --> AsyncLoad: ResourceLoader.load_threaded_request()
    
    AsyncLoad --> Progress: Chargement...
    Progress --> Progress: Boucle (0% → 100%)
    Progress --> Instantiated: ResourceLoader.load_threaded_get()
    
    Instantiated --> Added: add_child()
    Added --> SignalsConnected: _auto_connect_signals()
    SignalsConnected --> Ready: _ready() de la scène
    Ready --> FadeIn: Transition d'entrée
    FadeIn --> Active: Scène active
    
    Active --> Requested: Nouvelle demande de changement
    Active --> [*]: Fin du jeu
```

## 6. Système de Foi Divine (Gameplay → Foi)

```mermaid
flowchart TD
    subgraph "Actions du Joueur"
        A1[Attaque Solo<br/>Last Man Stand]
        A2[Attaque en Duo<br/>Leader]
        A3[Support de Duo]
        A4[Tour passé<br/>sans action]
    end
    
    subgraph "EventBus"
        EB[EventBus.add_divine_points]
    end
    
    subgraph "Dieux"
        K[Kharvûl<br/>Chaos]
        AS[Astraeon<br/>Stabilité]
        M[Myrr<br/>Magie]
        E[Etrius<br/>Temps]
    end
    
    A1 -->|+3 pts| EB
    A2 -->|+2 pts| EB
    A3 -->|+1 pt| EB
    A4 -->|+1 pt| EB
    
    EB -->|Chaos| K
    EB -->|Stabilité| AS
    EB -->|Magie| M
    EB -->|Temps| E
    
    K -.->|Seuil atteint| EV1[Événements Chaos]
    AS -.->|Seuil atteint| EV2[Événements Ordre]
    M -.->|Seuil atteint| EV3[Événements Magie]
    E -.->|Seuil atteint| EV4[Événements Temps]
```

## 7. Exemple Concret : Formation d'un Duo

```mermaid
sequenceDiagram
    participant P as Joueur
    participant BS as BattleScene
    participant U1 as Unit A
    participant U2 as Unit B
    participant EB as EventBus
    participant UI as UIPanel
    participant ST as StatsTracker
    participant DS as DivineSystem

    P->>BS: Déplace Unit A près de Unit B
    BS->>BS: _are_units_adjacent(U1, U2)?
    
    alt Adjacent
        BS->>U1: Marque "in_duo"
        BS->>U2: Marque "in_duo"
        BS->>EB: duo_formed.emit(U1, U2)
        
        EB->>UI: Notification "Duo formé"
        EB->>ST: Incrémenter stats "duos_formed"
        EB->>DS: add_divine_points("Astraeon", 1)
        
        UI->>P: Affiche notification
        DS->>DS: Vérifier seuil
        
        opt Seuil atteint
            DS->>EB: divine_threshold_reached.emit()
            EB->>BS: Déclencher événement divin
        end
    else Pas adjacent
        BS->>UI: Affiche erreur
    end
```

---

## Utilisation des Diagrammes

Ces diagrammes peuvent être visualisés :
- Sur GitHub (support natif Mermaid)
- Dans VS Code (extension Markdown Preview Mermaid)
- Sur [mermaid.live](https://mermaid.live)
- Dans la documentation générée

Ils servent à comprendre rapidement :
1. Le flux de chargement des scènes
2. L'auto-connexion des signaux
3. La communication découplée
4. Le cycle de vie complet
5. Les interactions entre systèmes
