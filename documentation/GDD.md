# GAME DESIGN DOCUMENT — Tactical RPG en Duos

## 1. Vision Générale

**Genre** : Tactical RPG narratif en tour par tour
**Plateforme cible** : PC (Godot)
**Inspirations** : Final Fantasy Tactics (GBA/DS), Tactics Ogre, Suikoden, Eiyuden Chronicle, The Witcher (choix moraux systémiques)

**Pitch** :
Un monde heroic-fantasy instable où la magie ne peut plus être canalisée seul sans risque. Les peuples ont inventé le combat en **duos** pour survivre. Le joueur incarne un humain marqué par un dieu ancien, dont les choix **ludiques** influencent l’équilibre cosmique entre Chaos, Stabilité, Magie et Temps.

---

## 2. Piliers de Design

* **Le duo comme unité fondamentale** (attaque impossible seul sauf Last Man Stand)
* **Choix par le gameplay**, pas par le dialogue
* **Narration systémique** (statistiques, légendes, menaces, réactions du monde)
* **Aucune solution moralement parfaite**
* **Monde réactif à la manière de jouer**

---

## 3. Univers & Cosmologie

### 3.1 Les Dieux

| Dieu       | Domaine          | Rôle                                 |
| ---------- | ---------------- | ------------------------------------ |
| Astraeon   | Stabilité, Ordre | Maintenait l’équilibre du monde      |
| Kharvûl    | Chaos            | Alimente le changement et la rupture |
| Myrr       | Magie            | Canalise et structure le mana        |
| **Etrius** | Temps, Vie, Mort | Observateur, archiviste du réel      |

### 3.2 La Dissociation

Un événement cataclysmique survenu au nord du continent :

* Explosion magique
* Cratère permanent
* Magie instable
* Blessure grave d’Astraeon par Kharvûl

Cause réelle :

* Explosion démographique humaine
* Nature chaotique humaine
* Déséquilibre cosmique

---

## 4. Religions & Géopolitique

### 4.1 Aurelia Sanctum (Humains)

* Religion dominante humaine
* Connaît la vérité sur la Dissociation
* Cache la cause réelle pour éviter un génocide humain
* Propage le **Dogme de la Concorde** : coopération, duos, discipline

### 4.2 Autres Races

* **Elfes** : soupçons sans preuve
* **Nains** : pragmatisme, containment
* **Beastkin** : adaptation instinctive
* **Anciens** : savent, refusent toute purge

---

## 5. Personnage Principal

### 5.1 Identité

**Nom** : Elior (modifiable)
**Race** : Humain
**Origine** : Orphelin

### 5.2 Marque d’Etrius

* Sceau divin visible
* Garantit protection sociale et éducation
* Neutralité religieuse imposée

### 5.3 Rôle Initial

* Scribe militaire
* Observateur stratégique
* Progression naturelle vers le commandement

### 5.4 Exception Unique

* Seul personnage pouvant :

  * Canaliser la magie seul
  * Utiliser tous les rôles (Leader / Support / Solo)
  * Choisir toutes les classes

---

## 6. Système de Duos

### 6.1 Règle Fondamentale

* Une attaque nécessite **2 unités adjacentes**
* Leader : utilise l’arme du duo
* Support : fournit le mana

### 6.2 Last Man Stand

* Si une unité est seule :

  * Vide son mana
  * Explosion sur 8 cases
  * Dégâts = (Dégâts / 8) × (1 + % mana restant)

---

## 7. Mana

### 7.1 Types de Mana (6 initiaux)

* Feu
* Vent
* Soin
* Terre
* Foudre
* Ombre

Une unité = un seul type de mana.

### 7.2 Instabilité

* Mana seul = instable
* Mana en duo = stabilisé

---

## 8. Armes & Compositions

### 8.1 Principe

* Les armes physiques sont obsolètes
* Le duo génère un **Conduit**

### 8.2 Définition d’une arme

Une arme dépend de :

* Classes des deux unités
* Races
* Nations
* Type de mana (teinte / effet)

### 8.3 Exemples

* Guerrier + Archer → Lance à portée linéaire 2 cases
* Archer + Archer → Arc long (2–3 cases)
* Mage + Tank → Canon à mana directionnel

---

## 9. Types d’Armes (Gameplay)

* Lances (ligne)
* Arcs courts (CàC + courte portée)
* Arcs longs (courte + moyenne portée)
* Arbalètes (moyenne portée, ignore armure)
* Canons à mana (zone)
* Fouets énergétiques (traction)
* Marteaux de flux (repoussement)
* Lames résonantes (cône)

---

## 10. Brisure de Duos

### 10.1 Mécaniques

* Attraction
* Repoussement
* Téléportation courte
* Zones instables

Objectif : casser l’adjacence

---

## 11. Statistiques

### 11.1 Stats Unité

* PV
* Mana
* Force
* Magie
* Défense
* Résistance
* Vitesse
* Volonté

### 11.2 Stats Duo (log persistant)

* Nombre d’attaques
* Victoires / Échecs
* Évitements cumulés
* Déplacements (total + par terrain)
* Kills
* MVP
* Menace
* Légende

---

## 12. Système de Menace & Légende

* Duo MVP par mission
* Accumulation = Menace
* Menace déclenche :

  * Focus ennemi
  * Embuscades
  * Micro-combats narratifs

---

## 13. Titres & Récompenses

* Seuils de kills
* Donnent :

  * Barks
  * Bonus passifs
  * Scènes uniques

---

## 14. Système Divin (Gameplay = Foi)

| Action du joueur | Points donnés        |
| ---------------- | -------------------- |
| Magie solo       | Chaos (Kharvûl)      |
| Leader duo       | Stabilité (Astraeon) |
| Support          | Magie (Myrr)         |
| Non-action       | Temps (Etrius)       |

Impact : monde, ennemis, fins.

---

## 15. Ville & Château (Meta)

* Base évolutive façon Suikoden
* Débloquée par personnages, duos, titres
* Bâtiments liés aux stats globales

---

## 16. Carte du Monde

* Spots façon FFT
* Pays multiples
* Nord instable (Cratère de la Dissociation)

---

## 17. Structure Narrative

* Aucun choix binaire
* Conséquences différées
* Révélations progressives

---

## 18. Fins Possibles

* Retour d’Astraeon par discipline
* Domination du Chaos
* Monde figé
* Équilibre fragile

---

## 19. Roadmap Prototype

1. Combat duo basique
2. Stats persistantes
3. Menace
4. Carte du monde
5. Ville
6. Vertical Slice

---

## 20. Thème Central

> « L’ordre ne revient pas par la vérité seule, mais par les actes répétés. »

