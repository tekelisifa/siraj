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
| Menu | Lampe, titre, carnet de mots arabes, choix de la langue (français pour l'instant) |
| La veillée | Un vieil homme raconte à un enfant, près du feu. Au dernier épisode, on découvrira que c'est Selim |
| La Mecque, an 610 | Selim (10 ans) marche dans les ruelles, salue la voisine, découvre les mots *As-salâmu ʿalaykum*, *Bismillâh*, *Iqraʾ*… et entend parler de la grotte de Hira |
| Médine, an 1 de l'Hégire | Selim (22 ans) monte sur le toit à l'aube. Le premier adhan s'élève au loin, le ciel s'éclaircit, les contrôles se figent |

Transitions : la lumière se referme en étoile à 8 branches, avec des intertitres (« Douze ans plus tard… »).

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

## Sons à ajouter

Les ambiances (vent, feu, rumeur de la ville) sont générées par le jeu en attendant de vrais enregistrements.
Les fichiers ci-dessous sont lus automatiquement s'ils sont présents :

| Fichier | Contenu | À prévoir |
|---|---|---|
| `audio/adhan.ogg` | Un adhan complet, style traditionnel du Hijaz | Enregistré par un muezzin, avec une autorisation écrite d'utilisation |

Les sous-titres de l'adhan se calent sur la durée du fichier.

## Points à faire valider par le relecteur

- [ ] Faire entendre l'adhan dans la scène de Bilal (radiyAllâhu ʿanhu) : certains savants sont réservés sur l'imitation de la voix d'un Compagnon. Ici, l'adhan est présenté comme « tel que Bilal l'a appelé », pas comme sa voix.
- [ ] La scène se passe à l'aube : faut-il ajouter *As-salâtu khayrun min an-nawm* au premier adhan ?
- [ ] Les paroles de la voisine (fictive) sur la grotte de Hira et le mot *Iqraʾ*.
- [ ] Les dates de la frise (570, 610, 622, 632) et l'ordre des prophètes présentés.
- [ ] Le nom du relecteur, à mettre à la place de `[NOM DU RELECTEUR]` dans le menu.

## Prochaines étapes

- Voix du conteur enregistrée, en français, turc et arabe
- Traductions turque et arabe de l'interface et des dialogues
- Épisodes suivants : l'année de l'Éléphant racontée à la veillée, Al-Amîn, l'Hégire, l'arrivée à Médine…
- Coffret de souvenirs (objets trouvés en explorant)

## Licences

Polices Amiri et Work Sans : SIL Open Font License (voir `fonts/`).
