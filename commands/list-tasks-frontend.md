---
allowed-tools: Bash(git log:*), Bash(git diff:*)
description: Génère la liste des tâches accomplies dans le frontend en français
---

## Ta tâche

1. Trouve la branche parente en exécutant `git log --oneline origin/develop..HEAD` et `git log --oneline origin/develop2..HEAD` pour identifier la base de la branche courante (celle qui donne le moins de commits correspond à la branche parente).
2. Récupère les commits avec `git log <base>..HEAD --oneline`.
3. Récupère le diff avec `git diff <base>...HEAD -- frontend/`.
4. Génère une liste concise en français de ce qui a été accompli dans le dossier `frontend/`.

Regroupe les éléments en trois sections distinctes (omets une section si elle est vide) :

### Fonctionnalités
- Liste des nouvelles fonctionnalités ajoutées

### Correctifs
- Liste des bugs et problèmes corrigés

### Optimisations
- Liste des améliorations de performance, refactorisations et ajustements techniques

Règles :
- Chaque point doit être court (une ligne max)
- Utilise un langage orienté résultat (ex. : « Ajout de… », « Correction de… », « Remplacement de… »)
- Ne mentionne pas les noms de fichiers sauf si c'est essentiel à la compréhension
- N'inclus pas les changements de configuration Claude (`.claude/`)
