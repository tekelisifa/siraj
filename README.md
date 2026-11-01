# Sirâj — Le voyage de Selim

سِرَاج · *« une lampe qui éclaire »* (Coran, sourate al-Ahzâb, 33:46)

Jeu narratif éducatif pour Android sur la vie du Prophète Muhammad ﷺ.
On suit **Selim**, un témoin fictif qui grandit au fil de l'histoire, de la Mecque à Médine.
Le jeu s'adresse aux enfants (gestes simples, rien d'impossible à réussir) comme aux adultes (frise, dates, lieux, vocabulaire arabe).

## Règles de respect de la tradition

Ces règles sont la base du projet. Toute contribution doit les respecter.

- **Aucune représentation** du Prophète ﷺ, des autres prophètes (paix sur eux), de sa famille ni des Compagnons : ni visage, ni silhouette, ni voix, ni paroles inventées. Sa présence est suggérée par la lumière et par le récit.
- Le joueur vit **à côté** de l'Histoire, jamais à sa place : ses choix ne concernent que la vie de Selim et ne modifient jamais les faits.
- Seuls des faits et des hadiths **authentiques**, avec leurs références, sont utilisés. Tout contenu est relu par une personne qualifiée avant publication.
- L'adhan et le Coran ne sont jamais utilisés comme simples effets sonores. Pendant l'adhan, les contrôles se figent.
- Ambiance sonore : voix, nachîds vocaux et bruits naturels, sans instruments.

## Ce que contient cette première version

| Écran | Ce qui s'y passe |
|---|---|
| Ouverture | Ciel étoilé et lampe, puis la frise des prophètes d'Âdam à Muhammad ﷺ, zoom sur sa vie (570-632), puis zoom sur « Tu es ici » : la Mecque, an 610 |
| Son | Au premier lancement, invitation à mettre le casque (ou à garder les sous-titres) |
| Menu | Lampe, titre, carnet de mots arabes, réglage de la voix (conteur IA, voix du téléphone, coupée), choix de la langue (français pour l'instant) |
| La veillée | Un vieil homme raconte à un enfant, près du feu (fumée, étincelles, étoiles filantes). Au dernier épisode, on découvrira que c'est Selim |
| La Mecque, an 610 | Une ruelle à explorer, plus large que l'écran. Passants qui saluent, marchand, chat, chameau, linge au vent, poussière dorée. Petites lumières à toucher : Jabal an-Nour, la Kaaba, le marché, le puits, le chameau. La colombe guide Selim (10 ans) jusqu'à la voisine, Oumm Nour, qui lui parle de la grotte de Hira |
| Médine, an 1 de l'Hégire | Le conteur raconte la mosquée, la question de l'appel à la prière et le rêve de ʿAbdallâh ibn Zayd. En journée (les sources ne précisent pas l'heure du premier appel), Selim (22 ans) regarde la mosquée d'origine (briques de terre, troncs de palmiers, toit de palmes). L'adhan s'élève du toit de la maison la plus haute (pas encore de minaret) ; les habitants convergent vers la mosquée et y entrent. Les contrôles se figent, les sous-titres suivent la voix du muezzin |

Transitions : la lumière se referme en étoile à 8 branches, avec des intertitres (« Douze ans plus tard… »).

Dans chaque scène :
- **un bandeau d'arrivée** indique le lieu, l'année et l'âge de Selim, puis un rappel reste en haut de l'écran ;
- **un menu de pause** (bouton en haut à droite) : reprendre, recommencer la scène, revenir au menu, voix, et la frise de la vie du Prophète ﷺ avec « Tu es ici ». Il est masqué pendant l'adhan.

## Installer sur ton téléphone

À chaque mise à jour de `main`, GitHub compile automatiquement l'APK et le publie dans la release **Aperçu** :

1. Sur ton téléphone, ouvre la page *Releases* du dépôt, puis **Aperçu (dernière version)**.
2. Télécharge `siraj.apk` et ouvre-le.
3. Si Android le demande, autorise l'installation depuis cette source.

C'est un APK de test, signé avec une clé de debug.

## Lancer le projet

1. Installer [Godot 4.3](https://godotengine.org/download) (version standard, pas .NET).
2. Ouvrir Godot, cliquer sur **Importer**, choisir le fichier `project.godot` de ce dépôt.
3. Appuyer sur **F5** pour jouer. La fenêtre est au format téléphone (portrait).

## Exporter vers Android

1. Dans Godot : **Éditeur › Paramètres de l'éditeur › Export › Android**, renseigner le chemin du SDK Android et d'un keystore de debug.
2. **Projet › Installer le modèle de compilation Android**.
3. **Projet › Exporter › Ajouter… › Android**, cocher *Use Gradle Build*, mettre l'orientation en portrait, et la permission `VIBRATE` pour les vibrations.
4. Brancher le téléphone (débogage USB activé) et cliquer sur l'icône Android en haut à droite de l'éditeur pour l'installer directement.

## Organisation du code

```
project.godot            réglages (720×1280 portrait, rendu compatible tous Android)
scenes/                  une scène par écran
scripts/autoload/
  game.gd                palette, polices, thème, carnet de mots, sauvegarde
  transition.gd          transition « lanterne » entre les scènes, intertitres
  audio.gd               ambiances (vent, feu, ville) et lecture des fichiers audio
scripts/ui/
  art.gd                 dessins vectoriels : lanternes, colombe, palmiers, personnages fictifs
  dialogue_box.gd        dialogues : texte progressif, mots arabes à toucher, choix
  ui.gd                  boutons, textes, mise en page
scripts/scenes/          la logique et le décor de chaque écran
shaders/iris.gdshader    effet de la transition
fonts/                   Amiri (arabe, titres) et Work Sans (texte), licence OFL
audio/                   enregistrements à ajouter (voir ci-dessous)
```

Tous les décors sont dessinés en code : pas d'images à gérer pour l'instant, et le rendu reste net sur tous les écrans.

## Voix et sons

### Les voix des personnages

Chaque réplique est lue à voix haute, dans cet ordre de priorité :

1. **Un fichier de voix** existe pour la réplique (`audio/voix/<identifiant>.ogg`) : le jeu le joue.
2. **Sinon**, la voix de synthèse du téléphone la lit. Le conteur utilise l'une des 3 voix retenues (la 3ᵉ par défaut), avec une hauteur et un rythme propres à chaque personnage.

Le réglage « Voix » (menu ou pause) passe de *conteur IA* (fichiers de voix) à *téléphone* (toujours la synthèse du téléphone) puis *coupée*.

Les mots arabes sont réécrits « à la française » pour être bien prononcés (`data/phonetique.json`). Les indications de jeu entre parenthèses ne sont pas lues.

### Génération automatique des voix (Chatterbox)

GitHub génère tout seul les fichiers de voix avec [Chatterbox](https://github.com/resemble-ai/chatterbox), un modèle open source (licence MIT) :

- **À chaque changement** des dialogues, de la phonétique ou des voix de référence, seules les répliques nouvelles ou modifiées sont générées. Puis l'APK est recompilé.
- **Lecture franco-arabe** : les expressions arabes (*As-salâmu ʿalaykum*, *Bismillâh*, la formule ﷺ…) sont lues en mode arabe, à partir du vrai texte arabe.
- **Régénérer une voix** depuis le téléphone : onglet *Actions* › *Voix (Chatterbox)* › *Run workflow*, puis indiquer `tout`, un personnage (`Le conteur`), ou des identifiants de [`audio/voix/SCRIPT.md`](audio/voix/SCRIPT.md).
- **Voix de référence** : déposer un extrait de 10 à 20 secondes (une personne qui lit un texte, avec son accord) dans `audio/voix/reference/`, nommé `conteur`, `selim`, `enfant`, `voisine` ou `passant` (`.wav`, `.mp3` ou `.ogg`). Toutes les répliques du personnage sont régénérées avec ce timbre.
- **Le conteur** a une voix de référence : `audio/voix/reference/conteur.wav` (voix de vieil homme, posée). Ses répliques et la narration sont accélérées de 8 % (`vitesse` dans `tools/generer_voix.py`), sans changer la hauteur.
- Sans voix de référence (Selim, l'enfant, la voisine, les passants pour l'instant), c'est la voix par défaut de Chatterbox, sans transposition.
- **Un vrai enregistrement** déposé à la main sous le nom d'une réplique n'est jamais écrasé.

La première génération prend du temps (les serveurs gratuits de GitHub n'ont pas de carte graphique). Les suivantes ne concernent que les changements.

Pour lancer la génération sur son propre ordinateur : `pip install chatterbox-tts`, puis `cd tools && python3 generer_voix.py`.

Chaque fichier généré par Chatterbox contient un filigrane audio inaudible (Resemble AI) qui l'identifie comme produit par IA.

### L'adhan

`audio/adhan.ogg` : adhan complet (1 min 37), en **Ogg Vorbis**. Godot ne lit pas l'Ogg Opus, même si l'extension est la même : convertir avec
`ffmpeg -i entree.ogg -af highpass=f=70 -ac 1 -ar 44100 -c:a libvorbis -q:a 5 audio/adhan.ogg`.

Les sous-titres suivent la position réelle de la lecture. Les débuts des 12 phrases ont été mesurés sur les respirations du muezzin (`PHRASE_TIMES` dans `scripts/scenes/medine.gd`) : à mettre à jour si l'enregistrement change.

L'adhan n'est jamais lu par une voix de synthèse ni généré par une IA.

### Les autres sons

Les ambiances (vent, feu, rumeur de la ville) et les bruitages (pas dans le sable, ailes de la colombe) sont générés par le jeu en attendant de vrais enregistrements.

## Points à faire valider par le relecteur

- [ ] Faire entendre l'adhan dans la scène de Bilal (radiyAllâhu ʿanhu) : certains savants sont réservés sur l'imitation de la voix d'un Compagnon. Ici, l'adhan est présenté comme « tel que Bilal l'a appelé », pas comme sa voix.
- [ ] Le premier adhan est placé en journée, sans heure précise : le hadith de ʿAbdallâh ibn Zayd (Abu Dawud, Ahmad, ad-Dârimî) dit seulement qu'il raconta son rêve au matin.
- [ ] Le récit du conteur : la mosquée (briques de terre, troncs de palmiers, palmes), la cloche et la corne proposées, le rêve, et la réponse du Prophète ﷺ rapportée au style indirect.
- [ ] Bilal sur le toit de la maison d'une femme des Banû an-Najjâr (Abu Dawud 519, hasan selon al-Albânî ; le hadith parle de son habitude, pas spécifiquement du premier appel) ; pas de minaret à l'époque.
- [ ] Les textes des lieux à découvrir à la Mecque (Jabal an-Nour, la Kaaba, le marché, Zamzam, le chameau).
- [ ] Les paroles de la voisine (fictive, Oumm Nour) sur la grotte de Hira et le mot *Iqraʾ*.
- [ ] Les dates de la frise (570, 610, 622, 632) et l'ordre des prophètes présentés.
- [ ] Le nom du relecteur, à mettre à la place de `[NOM DU RELECTEUR]` dans le menu.

## Prochaines étapes

- Voix enregistrées (voir `audio/voix/SCRIPT.md`), puis en turc et en arabe
- Traductions turque et arabe de l'interface et des dialogues
- Épisodes suivants : l'année de l'Éléphant racontée à la veillée, Al-Amîn, l'Hégire, l'arrivée à Médine…
- Coffret de souvenirs (objets trouvés en explorant)

## Licences

Polices Amiri et Work Sans : SIL Open Font License (voir `fonts/`).
