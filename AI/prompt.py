"""Aexels's AI prompt, as Pequod adds it to the tray's requests (AexelsAI): the instructions, then the AI Reference,
every article in full, titled as the app titles it, and Joe's four papers in full, as their latest LaTeX in Vesper,
which is kept out of this repo (it's public). Printed; AI/publish.sh publishes it."""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VESPER = os.path.join(os.path.dirname(ROOT), "Vesper")
# in the series' order: each paper's title, and its file in Vesper
PAPERS = [
    ("A Shot in the Dark", "Shot in the Dark/A Shot in the Dark.tex"),
    ("Into the Light", "Into the Light/Into the Light - Claude.tex"),
    ("A Bridge Just Far Enough", "Bridge Just Far Enough/A Bridge Just Far Enough.tex"),
    ("A Little Give and Take", "Little Give and Take/A Little Give and Take.tex"),
]


def read(path: str) -> str:
    with open(path, encoding="utf-8") as file:
        return file.read()


def strings() -> dict:
    """The app's English strings, as Localizable.strings has them."""
    text = read(os.path.join(ROOT, "Resources/en.lproj/Localizable.strings"))
    escapes = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}
    unescape = lambda s: re.sub(r"\\(.)", lambda m: escapes.get(m.group(1), m.group(1)), s)
    return {unescape(k): unescape(v) for k, v in re.findall(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', text, re.S)}


def main() -> None:
    names = strings()
    folder = os.path.join(ROOT, "Resources/Articles")
    articles = []
    for file in sorted(f for f in os.listdir(folder) if f.endswith(".md")):
        stem = file[:-3]
        key = stem[0].lower() + stem[1:] + "_name"
        title = names.get(key, key).replace("\n", "")
        articles.append(f'<article title="{title}" file="{file}">\n{read(os.path.join(folder, file))}\n</article>')
    papers = []
    for number, (title, path) in enumerate(PAPERS, 1):
        if not os.path.exists(os.path.join(VESPER, path)):
            sys.exit(f"prompt.py: {title} isn't at Vesper/{path}")
        papers.append(f'<paper number="{number}" title="{title}">\n{read(os.path.join(VESPER, path))}\n</paper>')
    instructions = read(os.path.join(ROOT, "AI/instructions.md"))
    reference = read(os.path.join(ROOT, "AI/Reference.md"))
    sys.stdout.write(f"{instructions}\n<reference>\n{reference}\n</reference>\n\n<articles>\n" + "\n\n".join(articles)
                     + "\n</articles>\n\n<papers>\n" + "\n\n".join(papers) + "\n</papers>\n")


if __name__ == "__main__":
    main()
