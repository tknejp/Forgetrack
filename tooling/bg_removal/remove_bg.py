from PIL import Image
import argparse
import math
from pathlib import Path


def clamp(v: float) -> int:
    return int(round(max(0, min(255, v))))


def build_output_path(input_path: str) -> str:
    path = Path(input_path)

    if "_input" not in path.stem:
        raise ValueError(
            f'Input filename must contain "_input" before the extension. '
            f'Example: "mage_set_input.png"'
        )

    output_stem = path.stem.replace("_input", "", 1)
    return str(path.with_name(output_stem + path.suffix))


def remove_chroma_key(
    input_path: str,
    output_path: str,
    #key_color=(0, 255, 0),
    key_color=(255, 0, 255),
    tolerance: float = 220.0,
    hard_cutoff: float = 35.0,
):
    """
    Removes magenta/chroma key background from an image.

    Example:
        mage_set_input.png -> mage_set.png
    """

    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()

    kr, kg, kb = key_color

    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]

            dist = math.sqrt(
                (r - kr) ** 2 +
                (g - kg) ** 2 +
                (b - kb) ** 2
            )

            # Pure / near-pure background -> fully transparent
            if dist <= hard_cutoff:
                pixels[x, y] = (0, 0, 0, 0)
                continue

            # Clearly not background -> keep unchanged
            if dist >= tolerance:
                continue

            # Anti-aliased edge:
            # Estimate alpha based on distance from key color.
            alpha = dist / tolerance

            if alpha <= 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue

            # Decontaminate color from magenta matte:
            # original = foreground * alpha + key_color * (1 - alpha)
            # foreground = (original - key_color * (1 - alpha)) / alpha
            nr = (r - (1 - alpha) * kr) / alpha
            ng = (g - (1 - alpha) * kg) / alpha
            nb = (b - (1 - alpha) * kb) / alpha

            pixels[x, y] = (
                clamp(nr),
                clamp(ng),
                clamp(nb),
                clamp(alpha * 255),
            )

    img.save(output_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input",
        help='Input image path. Filename must contain "_input", e.g. mage_set_input.png',
    )
    parser.add_argument("--tolerance", type=float, default=220.0)
    parser.add_argument("--hard-cutoff", type=float, default=35.0)

    args = parser.parse_args()

    output = build_output_path(args.input)

    remove_chroma_key(
        args.input,
        output,
        tolerance=args.tolerance,
        hard_cutoff=args.hard_cutoff,
    )

    print(f"Saved: {output}")