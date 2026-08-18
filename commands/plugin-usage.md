---
allowed-tools: Bash(bash /d/claude-code-setup/scripts/plugin-usage.sh:*)
description: Report plugin, command, and skill usage statistics
argument-hint: "[--days N] [--top N] [--no-skills]"
---

## Ta tache

Affiche les statistiques d'utilisation (plugins, commandes tapees, skills invoques, activite).

```bash
bash /d/claude-code-setup/scripts/plugin-usage.sh $ARGUMENTS
```

Affiche le rapport tel quel.

Ensuite, ajoute une courte analyse en francais : quels plugins/commandes/skills semblent
inutilises, et lesquels sont clairement actifs. Tiens compte de ces deux pieges :

- Les compteurs `pluginUsage` ne suivent pas un renommage. Un plugin repackage
  repart a zero sous son nouveau nom, donc deux entrees peuvent etre le meme outil
  (ex. `glab@inline` et `glab-skills@inline`) — additionne-les avant de conclure.
- Un compteur bas n'est pas une preuve d'abandon si l'outil vient d'etre installe.
  Verifie la date de derniere utilisation et l'historique git avant de proposer
  une suppression.

Ne supprime rien sans demander confirmation.
