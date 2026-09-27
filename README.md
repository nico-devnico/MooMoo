# MooMoo

Application de traduction et d'apprentissage de la langue des signes, disponible sur le web, le mobile (Android, iOS) et le bureau (Windows, macOS, Linux).

> Ce document décrit l'état **réel** du dépôt. Ce qui n'est pas encore en place est signalé dans [Sécurité non implémentée et limites](#sécurité-non-implémentée-et-limites) et [Problèmes connus](#problèmes-connus).

---

## Sommaire

1. [Présentation](#présentation)
2. [Objectif](#objectif)
3. [Fonctionnalités](#fonctionnalités)
4. [Rôles et permissions](#rôles-et-permissions)
5. [Architecture](#architecture)
6. [Technologies](#technologies)
7. [Installation](#installation)
8. [Configuration](#configuration)
9. [Structure du projet](#structure-du-projet)
10. [Fonctionnement des principales fonctionnalités](#fonctionnement-des-principales-fonctionnalités)
11. [Gestion des données](#gestion-des-données)
12. [Authentification et autorisation](#authentification-et-autorisation)
13. [Sécurité implémentée](#sécurité-implémentée)
14. [Sécurité non implémentée et limites](#sécurité-non-implémentée-et-limites)
15. [Gestion des erreurs](#gestion-des-erreurs)
16. [Variables d'environnement](#variables-denvironnement)
17. [Déploiement](#déploiement)
18. [Tests](#tests)
19. [Maintenance et recommandations](#maintenance-et-recommandations)
20. [Problèmes connus](#problèmes-connus)

---

## Présentation

MooMoo réunit trois briques :

- **l'application Flutter** (`lib/`) : l'interface utilisateur pour toutes les plateformes ;
- **l'API Node.js / Express** (`backend/`) : les opérations qui ne doivent pas s'exécuter dans le client (création de comptes, administration, import du dictionnaire, relais vers le service de reconnaissance) ;
- **la plateforme ML Python** (`ml/`) : l'entraînement des modèles de reconnaissance des signes et l'API d'inférence.

Les données, l'authentification et le stockage des fichiers sont gérés par **Supabase** (PostgreSQL, Auth, Storage, Realtime).

## Objectif

Faciliter la communication entre personnes sourdes, malentendantes et entendantes :

- traduire des signes en texte (caméra) et du texte en signes (vidéos, personnage 3D) ;
- proposer un dictionnaire de signes consultable et enrichi par la communauté ;
- permettre l'apprentissage progressif de la langue des signes.

## Fonctionnalités

| Espace | Fonctionnalités |
|---|---|
| Accueil | Raccourcis, suggestions, accès rapide aux autres espaces |
| Traduire | Signes → texte via la caméra (nécessite le service ML) ; texte ou voix → signes |
| Dico | Recherche, catégories, fiche de signe avec vidéo, favoris, compteur de vues |
| Apprendre | Parcours d'unités et de leçons, exercices, progression, objectif quotidien |
| Profil | Informations personnelles, photo de profil, historique des traductions, favoris, contributions |
| Paramètres | Thème, langue de l'interface, langue des signes, vue par défaut, réglages 3D, accessibilité, mot de passe |
| Aide | Guide utilisateur intégré, centre d'aide (FAQ + contact), mentions légales |
| Espaces métier | Espace enseignant, espace expert, administration (voir ci-dessous) |

Langues de l'interface : **français** (langue de référence) et **anglais**.

## Rôles et permissions

Les rôles sont stockés dans la table `user_roles` (`admin`, `teacher`, `sign_expert`). Un utilisateur sans rôle est un utilisateur standard. Un compte peut cumuler plusieurs rôles.

| Rôle | Peut |
|---|---|
| Utilisateur | Traduire, consulter le dictionnaire, apprendre, gérer son profil, ses favoris et son historique, proposer des contributions (si elles sont ouvertes) |
| Enseignant (`teacher`) | Tout ce qui précède + gérer les contenus d'apprentissage, consulter le tableau de bord enseignant |
| Expert (`sign_expert`) | Tout ce qui précède pour l'utilisateur + créer et modifier des signes (sans les supprimer), relire les contributions, tableau de bord expert |
| Administrateur (`admin`) | Tout : utilisateurs (création, rôles, suspension, suppression), dictionnaire (y compris import et suppression), apprentissage, modèles ML, réglages de l'application (nom, logo, maintenance, ouverture des contributions) |

Les permissions sont appliquées **côté base de données** (politiques RLS et fonctions SQL `current_user_has_role`, `is_current_user_admin`, `current_user_can_edit_dictionary`, `current_user_can_edit_learning`) et **côté API** (`backend/src/lib/roles.js`). L'interface masque les écrans non autorisés, mais ce masquage n'est pas une protection en soi.

Un compte **suspendu** (`profiles.suspended_at`) ne peut plus écrire (fonction `current_user_is_active`).

## Architecture

```
┌────────────────────┐        HTTPS         ┌──────────────────────┐
│  Application       │ ───────────────────▶ │  Supabase            │
│  Flutter           │   (clé publique +    │  Postgres + RLS      │
│  (web/mobile/      │    JWT utilisateur)  │  Auth · Storage      │
│   desktop)         │                      │  Realtime            │
└─────────┬──────────┘                      └──────────▲───────────┘
          │ HTTP + JWT                                  │
          ▼                                             │ clé service / SQL direct
┌────────────────────┐   HTTP    ┌──────────────────┐   │
│  API Node/Express  │ ────────▶ │  API ML FastAPI  │   │
│  backend/ (:3001)  │           │  ml/ (:8000)     │   │
└─────────┬──────────┘           └──────────────────┘   │
          └─────────────────────────────────────────────┘
                         Worker ML (file d'attente SQL)
```

- Le client lit et écrit **directement** dans Supabase pour les opérations courantes ; la RLS garantit que chacun n'accède qu'à ce qui lui est permis.
- L'API Node sert aux opérations privilégiées. Elle vérifie le JWT Supabase de l'appelant puis ses rôles.
- Le worker ML consomme les tâches d'entraînement écrites en base par l'administration.

Côté Flutter, le code suit une séparation en couches : `core` (thème, routes, erreurs, mise en page), `data` (modèles, repositories, services), `domain` (providers Riverpod, logique d'apprentissage), `presentation` (écrans et widgets).

## Technologies

| Domaine | Technologies |
|---|---|
| Client | Flutter (Dart ≥ 3.9), Riverpod 3, go_router, supabase_flutter, gen-l10n (ARB) |
| Médias | camera, image_picker, file_picker, video_player / chewie, model_viewer_plus (3D), speech_to_text, flutter_tts |
| API | Node.js (modules ES), Express 4, @supabase/supabase-js, pg, multer, fast-xml-parser |
| Données | Supabase : PostgreSQL, Auth, Storage, Realtime |
| ML | Python, FastAPI, MediaPipe Holistic, TensorFlow / Keras, export TFLite (voir `ml/README.md`) |

## Installation

### Prérequis

- Flutter SDK compatible Dart 3.9 ou supérieur ;
- Node.js 18 ou supérieur (npm) ;
- Python 3 (uniquement pour la reconnaissance des signes) ;
- un projet Supabase.

### Application Flutter

```bash
flutter pub get
flutter gen-l10n
flutter run -d chrome        # ou windows, android, etc.
```

### API Node

```bash
cd backend
npm install
cp .env.example .env         # puis compléter les valeurs
npm run migrate              # applique supabase/migrations (nécessite SUPABASE_DB_URL)
npm start                    # ou npm run dev (rechargement automatique)
```

### Plateforme ML (optionnelle)

Voir [`ml/README.md`](ml/README.md). Sans elle, l'application fonctionne mais la traduction signes → texte affiche « reconnaissance indisponible ».

## Configuration

- **Supabase côté client** : `lib/core/constants/supabase_constants.dart` contient l'URL du projet et la **clé publique** (publishable/anon). Cette clé est prévue pour être publique ; la sécurité repose sur la RLS.
- **URL de l'API** : `lib/core/constants/api_config.dart`, valeur par défaut `http://127.0.0.1:3001`, surchargeable à la compilation :

  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001   # émulateur Android
  ```

- **API Node** : fichier `backend/.env` (voir [Variables d'environnement](#variables-denvironnement)).
- **Réglages de l'application** (nom, logo, maintenance, contributions) : modifiables par un administrateur dans *Administration > Paramètres* ; stockés dans la table `app_settings`.

## Structure du projet

```
MooMoo/
├── lib/
│   ├── core/            # constantes, erreurs (user_error.dart), layout, routes, thème
│   ├── data/            # modèles, repositories (Supabase, Storage), services (api_client)
│   ├── domain/          # providers Riverpod, logique d'apprentissage
│   ├── l10n/            # app_fr.arb (référence), app_en.arb, code généré
│   └── presentation/    # écrans (screens/) et composants partagés (widgets/)
├── backend/
│   ├── src/
│   │   ├── index.js     # application Express, CORS, gestionnaire d'erreurs
│   │   ├── lib/         # errors.js, roles.js, settings.js, import du dictionnaire
│   │   ├── middleware/  # authentification JWT
│   │   └── routes/      # auth, admin, dictionary, models, infer, health
│   └── scripts/         # migrations et tests
├── ml/                  # entraînement, worker, API d'inférence (FastAPI)
├── supabase/migrations/ # schéma SQL, RLS, fonctions, buckets
├── test/                # tests Flutter
└── android/ ios/ web/ windows/ macos/ linux/
```

## Fonctionnement des principales fonctionnalités

### Navigation

- **Web, tablette et bureau** (à partir de 600 px de large) : barre en haut avec le logo à gauche, les liens **Accueil | Dico | Apprendre | Traduire** centrés, et la photo de l'utilisateur à l'extrême droite, qui ouvre le profil.
- **Mobile** : barre flottante en bas avec **Accueil, Dico, [bouton Traduire], Apprendre, Profil**. Le bouton rond central (logo de l'app) ouvre la traduction ; un second appui démarre ou arrête la capture.
- **Espaces admin / enseignant / expert sur mobile** : la barre du bas affiche au plus 4 éléments. Au-delà (espace admin), les 3 premières rubriques restent visibles et les autres sont regroupées dans **Menu** (icône hamburger), avec le retour à l'application.

Les routes sont définies dans `lib/core/router/`.

### Traduction

- **Signes → texte** : la caméra capture les images, les points clés sont envoyés à `POST /api/infer`, qui relaie vers l'API ML. Sans modèle en production pour la langue choisie, l'API répond 503 et l'interface affiche un message clair.
- **Texte → signes** : le texte (saisi ou dicté) est associé aux signes du dictionnaire, affichés en vidéo ou via le personnage 3D.
- Les traductions d'un utilisateur connecté sont enregistrées dans son historique.

### Dictionnaire

Consultation directe dans Supabase. Les experts et les administrateurs modifient les signes. L'import en masse (CSV, JSON, XML) passe par l'API (`/api/dictionary/import/preview` puis `/import/commit`), est réservé aux administrateurs et comporte un aperçu, une validation ligne par ligne et une protection SSRF pour les médias distants.

### Apprentissage

Unités → leçons → signes. La fin d'une leçon passe par la fonction SQL `complete_lesson`, qui met à jour la progression et les statistiques.

### Photo de profil

1. L'utilisateur choisit une image (JPG, PNG, WebP, GIF, BMP ou TIFF, 25 Mo maximum).
2. Le client la décode, applique l'orientation EXIF, la réduit à 512 px de côté, pose un fond blanc sous la transparence et la ré-encode en JPEG (`lib/core/utils/avatar_image.dart`, dans un isolate). Une grande photo d'appareil ou un format refusé par le bucket passe donc sans erreur. Le résultat est revérifié : moins de 2 Mo et format réel correct d'après les premiers octets.
3. L'image est envoyée dans le bucket `avatars` sous `<id utilisateur>/avatar.<ext>`, puis les anciens fichiers de l'utilisateur sont supprimés.
4. `profiles.avatar_url` est mis à jour, avec un paramètre anti-cache, et la photo s'affiche partout aussitôt.
5. Pour supprimer la photo, l'URL du profil est effacée d'abord, puis les fichiers.

Le bucket impose les mêmes limites côté serveur (migration `20260927000013`).

### Maintenance

Quand un administrateur active la maintenance, les écritures sont refusées par la base (fonction `app_accepts_writes`) et l'API répond 503 ; les administrateurs ne sont pas bloqués. L'application affiche un écran de maintenance aux autres utilisateurs.

## Gestion des données

- **Base** : PostgreSQL Supabase. Le schéma est versionné dans `supabase/migrations/` et appliqué avec `npm run migrate`. Principales tables issues des migrations : `profiles`, `user_roles`, `signs`, `contributions`, `learning_units`, `learning_lessons`, `lesson_signs`, `lesson_completions`, `learner_stats`, `app_settings`, `ml_datasets`, `training_jobs`, `ml_models`, `ml_experiments`, `ml_epoch_metrics`, `training_logs`. S'y ajoutent les tables de référence et d'activité (langues, catégories, favoris, historique, notifications).
- **Fichiers** (Supabase Storage) : `avatars` (public, 2 Mo, JPG/PNG/WebP, un dossier par utilisateur), `sign-videos` et `sign-thumbnails` (médias du dictionnaire), `branding` (logo, 2 Mo).
- **Local** : préférences via `shared_preferences` ; session Supabase gérée par le SDK.
- **ML** : jeux de données, cache et artefacts dans `ml/data`, `ml/cache` et `ml/artifacts` (non versionnés).

## Authentification et autorisation

- Authentification **Supabase Auth** par e-mail et mot de passe, avec réinitialisation par e-mail.
- À la création d'un compte, un trigger (`handle_new_user`) crée le profil et une notification de bienvenue.
- Le client envoie le JWT de la session à l'API Node (`Authorization: Bearer`) ; le middleware `backend/src/middleware/auth.js` le vérifie auprès de Supabase.
- L'autorisation est vérifiée à trois niveaux : RLS en base, contrôle des rôles dans l'API, masquage des écrans dans l'interface.
- Les champs sensibles du profil (rôle, statut administrateur, suspension) sont protégés par le trigger `protect_profile_privileges` : un utilisateur ne peut pas s'attribuer de droits.

## Sécurité implémentée

- RLS sur les tables applicatives ; les anciennes politiques permissives ont été supprimées (migration `20260927000003`).
- Clé `service_role` et URL de connexion directe **uniquement côté serveur** (`backend/.env`, non versionné), jamais dans le client.
- Storage : écriture dans `avatars` limitée au dossier de l'utilisateur ; limites de taille et de type MIME fixées au niveau des buckets.
- Validation du type réel des images (premiers octets du fichier) avant l'envoi.
- Import du dictionnaire : réservé aux administrateurs, validé ligne par ligne, avec protection SSRF sur les URL de médias.
- **Messages d'erreur neutres** : ni l'API ni l'interface ne montrent de trace d'exécution, de requête SQL, de nom de table ou de bucket, ni de configuration aux utilisateurs (voir [Gestion des erreurs](#gestion-des-erreurs)).
- `/health` public réduit au strict minimum ; le détail (file ML, configuration) est réservé aux administrateurs.
- En-tête `X-Powered-By` désactivé sur l'API.
- Mode maintenance appliqué en base et dans l'API.
- Suspension de comptes.

## Sécurité non implémentée et limites

À traiter avant une mise en production publique :

- **Pas de limitation de débit** (rate limiting) sur l'API Node : les routes `/api/auth/login` et `/api/auth/signup` n'ont pas de protection contre la force brute propre à l'API (seules les limites de Supabase Auth s'appliquent).
- **CORS ouvert par défaut** (`CORS_ORIGIN=*`) : à restreindre aux domaines de l'application.
- **Pas d'en-têtes de sécurité HTTP** dédiés (type Helmet : CSP, HSTS…) sur l'API.
- **Bucket `avatars` public** : toute personne connaissant l'URL d'une photo peut la voir.
- **`complete_lesson`** n'applique pas le mode maintenance.
- **Journalisation** : les erreurs serveur sont écrites dans la console (pas d'outil centralisé ni d'alerte) ; côté client, certains échecs non bloquants sont tracés avec `debugPrint`.
- **Pas d'antivirus** ni d'analyse de contenu sur les fichiers envoyés.
- **Pas de pipeline CI/CD** : les tests se lancent manuellement.
- Pas d'authentification à deux facteurs ni de connexion via des comptes tiers.

## Gestion des erreurs

### Côté API (`backend/src/lib/errors.js`)

- Un gestionnaire global renvoie `{ ok: false, error: <code>, message: <texte lisible> }`.
- Le message est **générique par statut HTTP** (400, 401, 403, 404, 409, 413, 415, 422, 429, 500, 502, 503), sauf pour les erreurs volontairement destinées à l'utilisateur, créées avec `userError(status, message, code)`.
- Le détail technique complet (pile d'appels, message d'origine) est **journalisé côté serveur**.
- Pour un administrateur (`req.isAdmin`), la réponse contient en plus `detail` / `details`.
- Les routes inconnues renvoient un 404 JSON neutre.

### Côté client (`lib/core/errors/user_error.dart`)

- `classifyError` range toute exception dans une catégorie : réseau, service indisponible, maintenance, session expirée, droits insuffisants, introuvable, conflit, fichier trop volumineux, format non pris en charge, données invalides, inconnue.
- Chaque catégorie correspond à un message traduit (clés `err*` des ARB).
- `ref.userErrorText(error, l10n)` (`lib/domain/providers/error_text.dart`) ajoute le détail technique **uniquement pour un administrateur**.
- Les écrans d'administration ML affichent les journaux techniques des entraînements ; ils ne sont accessibles qu'aux administrateurs.

## Variables d'environnement

Fichier `backend/.env` (modèle : `backend/.env.example`), lu aussi par le worker ML.

| Variable | Obligatoire | Rôle |
|---|---|---|
| `PORT` | non (3001) | Port de l'API |
| `SUPABASE_URL` | oui | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | oui | Clé publique, utilisée pour vérifier les JWT et agir au nom de l'utilisateur |
| `SUPABASE_SERVICE_ROLE_KEY` | non | Administration des comptes ; à défaut, `SUPABASE_DB_URL` est utilisé. **Secret.** |
| `SUPABASE_DB_URL` | pour `migrate`, l'admin et le ML | Chaîne de connexion PostgreSQL. **Secret.** |
| `ML_SERVICE_URL` | non (`http://127.0.0.1:8000`) | URL de l'API d'inférence |
| `CORS_ORIGIN` | non (`*`) | Origines autorisées : **à restreindre en production** |
| `ML_DATA_DIR`, `ML_CACHE_DIR`, `ML_ARTIFACTS_DIR`, `ML_ARTIFACT_BUCKET`, `ML_STALE_JOB_SECONDS`, `ML_MAX_JOB_ATTEMPTS` | non | Réglages du worker ML |

Côté Flutter : `API_BASE_URL` via `--dart-define`.

Ne jamais versionner de fichier `.env`.

## Déploiement

Aucune configuration de déploiement n'est fournie dans le dépôt. Étapes à prévoir :

1. **Base** : `npm run migrate` sur le projet Supabase cible.
2. **API Node** : hébergement Node (conteneur, VM ou PaaS) avec les variables d'environnement ci-dessus, derrière HTTPS, avec `CORS_ORIGIN` restreint.
3. **API ML** (optionnelle) : `uvicorn main:app` et le worker, accessibles uniquement par l'API Node (réseau privé).
4. **Web** : `flutter build web --dart-define=API_BASE_URL=https://<api>`, puis hébergement statique.
5. **Mobile / bureau** : `flutter build apk|appbundle|ios|windows|macos|linux` avec le même `--dart-define`.
6. Dans Supabase Auth, configurer les URL de redirection (réinitialisation du mot de passe, confirmation d'e-mail).

## Tests

```bash
flutter analyze lib test
flutter test

cd backend
npm run test:import    # import du dictionnaire (hors ligne)
npm run test:live      # parcours réels sur le projet Supabase (rôles, RLS, photo de profil, import, maintenance) : crée puis supprime des comptes de test
npm run test:api       # test rapide d'une API démarrée

cd ml
.venv\Scripts\python -m pytest tests -q
```

`test:live` active brièvement la maintenance (quelques secondes) puis la désactive : à ne pas lancer sur une production utilisée.

## Maintenance et recommandations

- **Schéma** : toute modification passe par une nouvelle migration datée dans `supabase/migrations/` ; ne jamais modifier une migration déjà appliquée.
- **Traductions** : ajouter les clés d'abord dans `app_fr.arb`, puis dans `app_en.arb`, lancer `flutter gen-l10n`, puis vérifier avec `node backend/scripts/check_arb.mjs`.
- **Erreurs** : dans l'API, utiliser `userError()` pour tout message destiné à l'utilisateur ; dans l'interface, afficher les erreurs via `ref.userErrorText(...)`, jamais `e.toString()`.
- **Secrets** : faire tourner le mot de passe de la base et la clé `service_role` en cas de doute ; ils ne doivent exister que dans `backend/.env` et l'hébergement.
- **Prioritaire avant production** : limitation de débit, CORS restreint, en-têtes de sécurité, journalisation centralisée, CI exécutant analyse et tests.

## Problèmes connus

- La traduction signes → texte n'est disponible que si l'API ML tourne et qu'un modèle de la langue choisie est en production.
- Après une mise à jour de l'API ou des migrations, l'API Node doit être redémarrée. Sur le web, un rechargement complet de l'application peut être nécessaire.
- Les contenus du dictionnaire et de l'apprentissage dépendent des données présentes dans la base : un projet neuf est vide.
- La synthèse et la reconnaissance vocales dépendent de la prise en charge du navigateur ou de l'appareil.
