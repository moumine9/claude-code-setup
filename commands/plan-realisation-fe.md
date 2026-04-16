---
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(acli jira workitem view:*), Read, Glob, Grep
description: Analyse le probleme courant et genere un plan de realisation en 3 sections (Problematique, Solution, Caveat) en francais
---

## Ta tache

Tu dois analyser le contexte actuel (branche, commits, diff, code) **ainsi que le ticket Jira associe** pour comprendre le probleme en cours et generer un document en **markdown** structure en 3 sections.

### Etapes

#### 1. Identifie le numero de ticket Jira

- Si un numero de ticket est fourni en argument (ex: `PV2-12345`), utilise-le.
- Sinon, tente de le detecter depuis le nom de la branche courante (`git branch --show-current`). Le numero de ticket correspond au prefixe de la branche (ex: `PV2-12493` dans `PV2-12493-fix-something`).
- Si aucun ticket ne peut etre identifie, demande-le a l'utilisateur avant de continuer.

#### 2. Recupere le contexte Jira du ticket

Execute la commande suivante pour obtenir les details du ticket :

```bash
acli jira workitem view <KEY> --fields "key,issuetype,summary,status,assignee,description,acceptance-criteria,labels,priority"
```

Si la commande echoue ou que le ticket n'existe pas, continue sans le contexte Jira (note-le dans le document final).

#### 3. Identifie la branche parente Git

Execute `git log --oneline origin/develop..HEAD` et `git log --oneline origin/develop2..HEAD`. Celle avec le moins de commits est la branche parente.

#### 4. Analyse le code

- Recupere les commits avec `git log <base>..HEAD --oneline`.
- Recupere le diff avec `git diff <base>...HEAD -- frontend/`.
- Lis les fichiers modifies si necessaire pour comprendre le contexte.

### Format de sortie

Genere le document suivant en markdown (syntaxe markdown) et en **francais** :

```
## Problematique

Bref resume du probleme identifie. 2-3 phrases maximum. Va droit au but.
Integre les informations du ticket Jira (summary, description, acceptance criteria) si disponibles.

## Solution

- Action concrete a realiser
- Autre action concrete
- ...

Chaque point est une etape actionnable. Tu peux mentionner des noms de fichiers si ca aide a la comprehension mais reste concis. Pas de code, pas de detail d'implementation.

## Caveat

- Effet de bord ou risque potentiel
- Autre point d'attention
- ...
```

### Regles

- Sois bref et concis : ce document est lu par un humain
- Utilise un langage direct et oriente action
- Priorise le contexte Jira (description, acceptance criteria) sur le diff pour comprendre l'intention du ticket
- La section Solution est une liste a puces, pas des paragraphes
- La section Caveat peut etre vide si aucun effet de bord n'est identifie (dans ce cas, ecris "Aucun caveat identifie.")
- N'inclus pas les changements de configuration Claude (`.claude/`)
- Tout le contenu doit etre en francais
