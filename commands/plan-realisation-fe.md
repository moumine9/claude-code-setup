---
allowed-tools: Bash(git log:*), Bash(git diff:*), Read, Glob, Grep
description: Analyse le probleme courant et genere un plan de realisation en 3 sections (Problematique, Solution, Caveat) en francais
---

## Ta tache

Tu dois analyser le contexte actuel (branche, commits, diff, code) pour comprendre le probleme en cours et generer un document en **markdown** structure en 3 sections.

### Etapes

1. Identifie la branche parente en executant `git log --oneline origin/develop..HEAD` et `git log --oneline origin/develop2..HEAD` (celle avec le moins de commits est la branche parente).
2. Recupere les commits avec `git log <base>..HEAD --oneline`.
3. Recupere le diff avec `git diff <base>...HEAD -- frontend/`.
4. Lis les fichiers modifies si necessaire pour comprendre le contexte.

### Format de sortie

Genere le document suivant en markdown (syntaxe markdown) et en **francais** :

```
## Problematique

Bref resume du probleme identifie. 2-3 phrases maximum. Va droit au but.

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
- La section Solution est une liste a puces, pas des paragraphes
- La section Caveat peut etre vide si aucun effet de bord n'est identifie (dans ce cas, ecris "Aucun caveat identifie.")
- N'inclus pas les changements de configuration Claude (`.claude/`)
- Tout le contenu doit etre en francais
