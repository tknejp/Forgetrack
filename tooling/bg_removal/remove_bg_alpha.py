from PIL import Image
import argparse
import math


def chroma_to_alpha_only(
    input_path: str,
    output_path: str,
    key_color=(255, 0, 255),
    hard_cutoff: float = 45.0,
    soft_cutoff: float = 240.0,
    soft_edges: bool = True,
):
    """
    Remove magenta background by changing alpha only.
    RGB values are NEVER modified.

    hard_cutoff:
        Pixels very close to key color become fully transparent.

    soft_cutoff:
        Pixels between hard_cutoff and soft_cutoff can get partially transparent
        if soft_edges=True.

    soft_edges:
        True  -> anti-aliased alpha falloff near edges
        False -> only full alpha=0 for matched pixels, everything else unchanged
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

            # Full removal
            if dist <= hard_cutoff:
                pixels[x, y] = (r, g, b, 0)
                continue

            # Keep unchanged
            if not soft_edges or dist >= soft_cutoff:
                continue

            # Partial alpha only, RGB unchanged
            t = (dist - hard_cutoff) / (soft_cutoff - hard_cutoff)
            t = max(0.0, min(1.0, t))
            new_alpha = int(round(a * t))

            pixels[x, y] = (r, g, b, new_alpha)

    img.save(output_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--hard-cutoff", type=float, default=45.0)
    parser.add_argument("--soft-cutoff", type=float, default=240.0)
    parser.add_argument("--hard-only", action="store_true")

    args = parser.parse_args()

    chroma_to_alpha_only(
        args.input,
        args.output,
        hard_cutoff=args.hard_cutoff,
        soft_cutoff=args.soft_cutoff,
        soft_edges=not args.hard_only,
    )