"""Loads config/label_map.json and resolves it against Fashionpedia names."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

DEFAULT_LABEL_MAP = Path(__file__).resolve().parent.parent / "config" / "label_map.json"

# Codes the app accepts (packages/wardrobe_domain/lib/src/taxonomy/taxonomy.dart).
APP_CATEGORIES = {"TOP", "BOTTOM", "ONE_PIECE", "OUTERWEAR", "FOOTWEAR", "ACCESSORY"}
APP_PATTERNS = {"SOLID", "STRIPED", "CHECKED", "FLORAL", "GRAPHIC", "DOTTED", "ANIMAL", "OTHER"}
APP_SUBCATEGORIES = {
    "T_SHIRT", "SHIRT", "BLOUSE", "POLO", "SWEATER", "HOODIE", "TANK", "OTHER_TOP",
    "JEANS", "TROUSERS", "CHINOS", "SHORTS", "SKIRT", "LEGGINGS", "OTHER_BOTTOM",
    "DRESS", "JUMPSUIT", "OVERALL", "OTHER_ONE_PIECE",
    "JACKET", "BLAZER", "COAT", "CARDIGAN", "VEST", "OTHER_OUTERWEAR",
    "SNEAKERS", "BOOTS", "DRESS_SHOES", "LOAFERS", "SANDALS", "HEELS", "FLATS",
    "OTHER_FOOTWEAR",
    "BAG", "HAT", "SCARF", "BELT", "TIE", "OTHER_ACCESSORY",
}


class LabelMapError(ValueError):
    """The label map is malformed or does not match the annotation file."""


@dataclass(frozen=True)
class TypeClass:
    label: str
    fashionpedia: str
    category: str
    subcategory: str | None


@dataclass(frozen=True)
class LabelMap:
    classes: tuple[TypeClass, ...]
    excluded: frozenset[str]
    pattern_supercategory: str
    pattern_rules: tuple[tuple[str, tuple[str, ...]], ...]
    pattern_classes: tuple[str, ...]

    @property
    def type_labels(self) -> list[str]:
        return [c.label for c in self.classes]

    def pattern_code_for(self, attribute_name: str) -> str:
        """App pattern code for a Fashionpedia pattern attribute name."""
        name = attribute_name.lower()
        for code, keywords in self.pattern_rules:
            if any(k in name for k in keywords):
                return code
        return "OTHER"

    def labels_json(self) -> dict:
        """The labels file shipped next to the model (output index order)."""
        return {
            "schemaVersion": 1,
            "inputs": {"image": "float32 [1,224,224,3] RGB, 0-255"},
            "outputs": {
                "type": [
                    {"label": c.label, "category": c.category, "subcategory": c.subcategory}
                    for c in self.classes
                ],
                "pattern": list(self.pattern_classes),
            },
        }


def load(path: Path = DEFAULT_LABEL_MAP) -> LabelMap:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    if raw.get("schemaVersion") != 1:
        raise LabelMapError("unsupported label map schemaVersion")
    classes = []
    seen_labels: set[str] = set()
    seen_names: set[str] = set()
    for entry in raw["classes"]:
        c = TypeClass(
            label=entry["label"],
            fashionpedia=entry["fashionpedia"],
            category=entry["category"],
            subcategory=entry.get("subcategory"),
        )
        if c.category not in APP_CATEGORIES:
            raise LabelMapError(f"{c.label}: unknown category {c.category}")
        if c.subcategory is not None and c.subcategory not in APP_SUBCATEGORIES:
            raise LabelMapError(f"{c.label}: unknown subcategory {c.subcategory}")
        if c.label in seen_labels or c.fashionpedia in seen_names:
            raise LabelMapError(f"duplicate class {c.label} / {c.fashionpedia}")
        seen_labels.add(c.label)
        seen_names.add(c.fashionpedia)
        classes.append(c)
    pattern_classes = tuple(raw["patternClasses"])
    if set(pattern_classes) != APP_PATTERNS:
        raise LabelMapError("patternClasses must be exactly the app's pattern codes")
    rules = tuple(
        (r["code"], tuple(k.lower() for k in r["keywords"])) for r in raw["patternRules"]
    )
    for code, _ in rules:
        if code not in APP_PATTERNS:
            raise LabelMapError(f"unknown pattern code {code}")
    return LabelMap(
        classes=tuple(classes),
        excluded=frozenset(raw.get("excluded", [])),
        pattern_supercategory=raw["patternSupercategory"],
        pattern_rules=rules,
        pattern_classes=pattern_classes,
    )
