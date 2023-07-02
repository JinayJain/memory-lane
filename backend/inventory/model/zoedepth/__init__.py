from io import BytesIO
import tempfile
import matplotlib
import numpy as np
import pyrender
import torch
import os
from PIL import Image
from torchvision.transforms import ToTensor
import trimesh

from inventory.model.zoedepth.geometry import (
    create_triangles,
    depth_edges_mask,
    depth_to_points,
)

from .misc import colorize

net = None
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def load_model():
    repo = "isl-org/ZoeDepth"
    # Zoe_N
    net = torch.hub.load(repo, "ZoeD_N", pretrained=True).to(device)

    net.eval()

    return net


def run(img: Image) -> Image:
    global net

    if net is None:
        net = load_model()

    with torch.no_grad():
        img_tensor = pil_to_tensor(img)
        depth = net.infer(img_tensor)
        depth = depth.squeeze().cpu().numpy()

    colorized_depth = colorize(depth)
    colorized_depth = Image.fromarray(colorized_depth)

    # Use the depth map to convert to points
    pts3d = depth_to_points(depth[None])
    pts3d = pts3d.reshape(-1, 3)

    image = np.array(img)
    triangles = create_triangles(
        image.shape[0], image.shape[1], mask=~depth_edges_mask(depth, threshold=0.2)
    )
    vertex_colors = image.reshape(-1, 3)

    mesh = trimesh.Trimesh(vertices=pts3d, faces=triangles, vertex_colors=vertex_colors)

    glb_file = tempfile.NamedTemporaryFile(suffix=".glb")
    print(glb_file.name)
    mesh.export(glb_file.name)

    return colorized_depth, glb_file


def pil_to_tensor(img):
    img = ToTensor()(img).unsqueeze(0).to(device)
    return img
