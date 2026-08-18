---
allowed-tools: Bash(bash /d/claude-code-setup/scripts/set-model.sh:*)
description: Switch to the Sonnet model (default effort medium)
argument-hint: "[low|medium|high|xhigh|max]"
---

## Ta tache

Bascule la session sur le modele **sonnet**.

L'effort vient de `$ARGUMENTS` s'il est fourni, sinon `medium`.

```bash
bash /d/claude-code-setup/scripts/set-model.sh sonnet "$ARGUMENTS"
```

Affiche le resultat du script tel quel, sans le reformuler.
