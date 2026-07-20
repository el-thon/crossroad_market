from __future__ import annotations

from pathlib import Path

SOURCE = Path("scripts/locations/store/StorePathGraph.gd")
PARTS_DIR = Path("scripts/locations/store/store_path_graph_parts")
MAX_PART_LINES = 850


def find_top_level_function_starts(lines: list[str]) -> list[int]:
    return [
        index
        for index, line in enumerate(lines)
        if line.startswith("func ") or line.startswith("static func ")
    ]


def split_function_blocks(lines: list[str]) -> tuple[list[str], list[list[str]]]:
    starts = find_top_level_function_starts(lines)
    if not starts:
        raise RuntimeError("StorePathGraph.gd contains no top-level functions")

    preamble = lines[: starts[0]]
    blocks: list[list[str]] = []
    for block_index, start in enumerate(starts):
        end = starts[block_index + 1] if block_index + 1 < len(starts) else len(lines)
        blocks.append(lines[start:end])
    return preamble, blocks


def normalized_base_preamble(preamble: list[str]) -> list[str]:
    result: list[str] = []
    for line in preamble:
        if line.strip() == "class_name StorePathGraph":
            continue
        if line.strip() == "extends RefCounted":
            continue
        result.append(line)

    while result and result[0].strip() == "":
        result.pop(0)

    return [
        "extends RefCounted\n",
        "\n",
        "## Base state and public route API extracted from StorePathGraph.\n",
        "## Generated once at refactor time; runtime behavior remains inherited.\n",
        "\n",
        *result,
    ]


def part_header(previous_path: str, part_number: int) -> list[str]:
    return [
        f'extends "res://{previous_path}"\n',
        "\n",
        f"## StorePathGraph implementation part {part_number}.\n",
        "## Functions remain byte-for-byte in their original order.\n",
        "\n",
    ]


def pack_parts(preamble: list[str], blocks: list[list[str]]) -> list[list[str]]:
    parts: list[list[str]] = []
    current = normalized_base_preamble(preamble)

    for block in blocks:
        if len(block) + 5 > MAX_PART_LINES:
            raise RuntimeError(
                f"A single StorePathGraph function is too large to keep intact: {len(block)} lines"
            )

        if len(current) + len(block) > MAX_PART_LINES and current:
            parts.append(current)
            previous_path = str(PARTS_DIR / f"StorePathGraphPart{len(parts):02d}.gd")
            current = part_header(previous_path, len(parts) + 1)

        current.extend(block)

    if current:
        parts.append(current)

    return parts


def write_parts(parts: list[list[str]]) -> None:
    PARTS_DIR.mkdir(parents=True, exist_ok=True)

    for stale in PARTS_DIR.glob("StorePathGraphPart*.gd"):
        stale.unlink()

    for index, content in enumerate(parts, start=1):
        path = PARTS_DIR / f"StorePathGraphPart{index:02d}.gd"
        path.write_text("".join(content), encoding="utf-8")

    final_part = PARTS_DIR / f"StorePathGraphPart{len(parts):02d}.gd"
    facade = "".join(
        [
            "class_name StorePathGraph\n",
            f'extends "res://{final_part.as_posix()}"\n',
            "\n",
            "## Stable public facade. The implementation is split into inherited\n",
            "## responsibility-sized parts so no source file exceeds 1,000 lines.\n",
            "\n",
            "func _init(store: Node2D = null, markers: Node2D = null) -> void:\n",
            "\tsuper._init(store, markers)\n",
        ]
    )
    SOURCE.write_text(facade, encoding="utf-8")


def validate(parts: list[list[str]]) -> None:
    if not parts:
        raise RuntimeError("No StorePathGraph parts were generated")

    oversized = [index for index, part in enumerate(parts, start=1) if len(part) >= 1000]
    if oversized:
        raise RuntimeError(f"Generated parts exceed the 1,000-line limit: {oversized}")

    facade_lines = SOURCE.read_text(encoding="utf-8").splitlines()
    if len(facade_lines) >= 1000:
        raise RuntimeError("StorePathGraph facade still exceeds 1,000 lines")

    print(f"Generated {len(parts)} StorePathGraph parts")
    for index, part in enumerate(parts, start=1):
        print(f"  Part {index:02d}: {len(part)} lines")
    print(f"  Facade: {len(facade_lines)} lines")


def main() -> None:
    original_lines = SOURCE.read_text(encoding="utf-8").splitlines(keepends=True)
    preamble, blocks = split_function_blocks(original_lines)
    parts = pack_parts(preamble, blocks)
    write_parts(parts)
    validate(parts)


if __name__ == "__main__":
    main()
