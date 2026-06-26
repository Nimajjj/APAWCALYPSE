#!/usr/bin/env python3
"""Setup code-review-graph pour un nouveau clone du projet.

A lancer une fois apres avoir clone le repo :

    python scripts/setup_code_review_graph.py

Ce que le script fait (idempotent — on peut le relancer sans risque) :
  1. Verifie qu'on est bien a la racine d'un repo git.
  2. S'assure que le CLI `code-review-graph` est installe (sinon `pip install`).
  3. Enregistre le serveur MCP + les hooks via `code-review-graph install`.
  4. (Re)installe le hook git post-commit qui met a jour le graphe a chaque commit.
  5. Construit la base de connaissance locale (`graph.db`) si elle manque.
  6. Affiche le statut final.

Le graphe (`.code-review-graph/graph.db`) et le hook ne sont pas versionnes :
ils contiennent des chemins absolus et doivent etre regeneres sur chaque machine.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

PACKAGE = "code-review-graph"
CLI = "code-review-graph"
DB_PATH = Path(".code-review-graph") / "graph.db"

POST_COMMIT_HOOK = """\
#!/bin/sh
# Auto-genere par setup_code_review_graph.py — met a jour le graphe a chaque commit.
if command -v code-review-graph >/dev/null 2>&1; then
    code-review-graph update 2>/dev/null || true
fi
"""


def log(step: str, msg: str) -> None:
    print(f"\033[1;36m[{step}]\033[0m {msg}")


def warn(msg: str) -> None:
    print(f"\033[1;33m[warn]\033[0m {msg}")


def fail(msg: str) -> None:
    print(f"\033[1;31m[erreur]\033[0m {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    print(f"  $ {' '.join(cmd)}")
    return subprocess.run(cmd, **kw)


def find_repo_root() -> Path:
    """Racine git, sinon racine du script (scripts/ -> parent)."""
    res = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    if res.returncode == 0:
        return Path(res.stdout.strip())
    # Fallback : on suppose que le script vit dans <repo>/scripts/
    return Path(__file__).resolve().parent.parent


def ensure_cli() -> str:
    """Retourne le chemin du CLI, l'installe via pip s'il manque."""
    path = shutil.which(CLI)
    if path:
        log("cli", f"{CLI} deja present ({path})")
        return CLI

    warn(f"{CLI} introuvable dans le PATH — installation via pip…")
    res = run([sys.executable, "-m", "pip", "install", "--upgrade", PACKAGE])
    if res.returncode != 0:
        fail(f"echec de l'installation de {PACKAGE}. Installe-le manuellement : "
             f"pip install {PACKAGE}")

    path = shutil.which(CLI)
    if not path:
        warn(f"{CLI} installe mais pas dans le PATH. "
             "Ajoute le dossier Scripts/bin de Python a ton PATH, puis relance.")
        # On peut tout de meme appeler via `python -m` si le module l'expose.
    return CLI


def crg_install(repo: Path) -> None:
    """Enregistre le MCP + hooks. --no-instructions : CLAUDE.md les contient deja."""
    log("install", "enregistrement MCP + hooks (code-review-graph install)…")
    res = run(
        [CLI, "install", "--repo", str(repo),
         "--platform", "claude-code", "--no-instructions", "-y"],
    )
    if res.returncode != 0:
        warn("`code-review-graph install` a renvoye une erreur — "
             "on continue (le hook est reinstalle manuellement juste apres).")


def install_post_commit_hook(repo: Path) -> None:
    """(Re)ecrit le hook post-commit — non versionne, donc absent au clone."""
    hooks_dir = repo / ".git" / "hooks"
    if not hooks_dir.is_dir():
        warn(f"{hooks_dir} absent — pas un clone git complet ? Hook ignore.")
        return

    hook = hooks_dir / "post-commit"
    hook.write_text(POST_COMMIT_HOOK, encoding="utf-8", newline="\n")
    try:
        hook.chmod(0o755)  # no-op sous Windows, utile sous Unix
    except OSError:
        pass
    log("hook", f"post-commit installe -> {hook}")


def build_graph(repo: Path) -> None:
    db = repo / DB_PATH
    if db.exists():
        log("build", f"graph.db deja present ({db.stat().st_size // 1024} Ko) — "
                     "mise a jour incrementale.")
        run([CLI, "update", "--repo", str(repo)])
        return

    log("build", "construction initiale du graphe (peut prendre un moment)…")
    res = run([CLI, "build", "--repo", str(repo)])
    if res.returncode != 0:
        fail("echec de `code-review-graph build`. Verifie l'installation du CLI.")


def show_status(repo: Path) -> None:
    log("status", "etat du graphe :")
    run([CLI, "status", "--repo", str(repo)])


def main() -> None:
    repo = find_repo_root()
    log("repo", f"racine du projet : {repo}")

    ensure_cli()
    crg_install(repo)
    install_post_commit_hook(repo)
    build_graph(repo)
    show_status(repo)

    print()
    log("ok", "code-review-graph est pret. Redemarre Claude Code / ton "
              "IDE pour que le serveur MCP soit recharge.")


if __name__ == "__main__":
    main()
