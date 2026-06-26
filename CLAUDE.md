# APAWCALYPSE

Projet de jeu Godot 4 (GDScript).

## Exploration du code — utiliser code-review-graph en premier

Ce projet expose un graphe de connaissance via le serveur MCP `code-review-graph`
(voir `.mcp.json`). Avant d'implémenter une feature ou un fix, oriente-toi avec ce
graphe **avant** de grep/lire les fichiers en masse :

- `semantic_search_nodes` — trouver le code pertinent par mots-clés / concept
- `query_graph` — tracer les relations entre symboles
- `get_impact_radius` — mesurer le blast radius avant de modifier un symbole
- `detect_changes` — revue à risque sur les changements en cours

Ensuite seulement, lis/édite les fichiers concrets identifiés. Le grep/lecture
directe reste OK pour modifier ou debugger des lignes précises une fois orienté,
ou pour les tâches triviales évidentes.

Le graphe se met à jour automatiquement à chaque `git commit` (hook post-commit).
Reconstruction complète si besoin : `code-review-graph build`.
