---
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(acli jira workitem view:*), Read, Glob, Grep
description: Analyse le problème courant et génere un plan de realisation en 3 sections (Problématique, Solution, Caveat) en français
---

# Ta tâche

Tu dois analyser le contexte actuel (branche, commits, diff, code) **ainsi que le ticket Jira associé** pour comprendre le problème en cours et générer un document en **markdown** structuré en 3 sections.

## Étapes

### 1. Identifie le numéro de ticket Jira

- Si un numéro de ticket est fourni en argument (ex: `PV2-12345`), utilise-le.
- Sinon, tente de le détecter depuis le nom de la branche courante (`git branch --show-current`). Le numéro de ticket correspond au préfixe de la branche (ex: `PV2-12493` dans `PV2-12493-fix-something`).
- Si aucun ticket ne peut être identifié, demande-le à l'utilisateur avant de continuer.

### 2. Récupère le contexte Jira du ticket

Exécute la commande suivante pour obtenir les détails du ticket :

```bash
acli jira workitem view <KEY> --fields "key,issuetype,summary,status,assignee,description,acceptance-criteria,labels,priority"
```

Si la commande échoue ou que le ticket n'existe pas, continue sans le contexte Jira (note-le dans le document final).

### 3. Identifie la branche parente Git

Exécute `git log --oneline origin/develop..HEAD` et `git log --oneline origin/develop2..HEAD`. Celle avec le moins de commits est la branche parente.

### 4. Analyse le code

- Récupère les commits avec `git log <base>..HEAD --oneline`.
- Récupère le diff avec `git diff <base>...HEAD -- frontend/`.
- Lis les fichiers modifiés si nécessaire pour comprendre le contexte.

## Format de sortie

Génère le document suivant en markdown (syntaxe markdown) et en **français** :

```
## Problématique

Bref résumé du problème identifié. 2-3 phrases maximum. Va droit au but.
Intègre les informations du ticket Jira (summary, description, acceptance criteria) si disponibles.

## Solution

- Action concrète à réaliser
- Autre action concrète
- ...

Chaque point est une étape actionnable. Tu peux mentionner des noms de fichiers si cela aide à la compréhension mais reste concis. Pas de code, pas de détail d'implémentation.

## Caveat

- Effet de bord ou risque potentiel
- Autre point d'attention
- ...
```

## Règles

- Sois bref et concis : ce document est lu par un humain
- Utilise un langage direct et orienté action
- Priorise le contexte Jira (description, critères d'acceptation) sur le diff pour comprendre l'intention du ticket
- La section Solution est une liste à puces, pas des paragraphes
- La section Caveat peut être vide si aucun effet de bord n'est identifié (dans ce cas, écris « Aucun caveat identifié. »)
- N'inclus pas les changements de configuration Claude (`.claude/`)
- Tout le contenu doit être en français
