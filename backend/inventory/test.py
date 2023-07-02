import sys
from PIL import Image
import pyrender
from inventory.model.zoedepth import run


def main():
    image_path = sys.argv[1]
    img = Image.open(image_path)
    img.thumbnail((1024, 1024))

    depth_img, mesh = run(img)

    depth_img.show()


if __name__ == "__main__":
    main()
