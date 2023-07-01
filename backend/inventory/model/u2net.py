import os
import torch
from torch.autograd import Variable
from torchvision import transforms

import numpy as np
from PIL import Image

from inventory.u2net.data_loader import RescaleT
from inventory.u2net.data_loader import ToTensorLab
from inventory.u2net.model import U2NET  # full size version 173.6 MB


net = None


def load_model(model_dir):
    net = U2NET(3, 1)
    net.load_state_dict(torch.load(os.path.join(model_dir, "u2net.pth")))
    if torch.cuda.is_available():
        net.cuda()
    net.eval()
    return net


def normPRED(d):
    ma = torch.max(d)
    mi = torch.min(d)
    dn = (d - mi) / (ma - mi)
    return dn


def preprocess(image):
    label_3 = np.zeros(image.shape)
    label = np.zeros(label_3.shape[0:2])

    if 3 == len(label_3.shape):
        label = label_3[:, :, 0]
    elif 2 == len(label_3.shape):
        label = label_3

    if 3 == len(image.shape) and 2 == len(label.shape):
        label = label[:, :, np.newaxis]
    elif 2 == len(image.shape) and 2 == len(label.shape):
        image = image[:, :, np.newaxis]
        label = label[:, :, np.newaxis]

    transform = transforms.Compose([RescaleT(320), ToTensorLab(flag=0)])
    sample = transform({"imidx": np.array([0]), "image": image, "label": label})

    return sample


def run(img: Image, model_dir: str):
    torch.cuda.empty_cache()

    global net
    if net is None:
        net = load_model(model_dir)

    sample = preprocess(np.array(img))
    inputs_test = sample["image"].unsqueeze(0)
    inputs_test = inputs_test.type(torch.FloatTensor)

    if torch.cuda.is_available():
        inputs_test = Variable(inputs_test.cuda())
    else:
        inputs_test = Variable(inputs_test)

    d1, d2, d3, d4, d5, d6, d7 = net(inputs_test)

    # Normalization.
    pred = d1[:, 0, :, :]
    predict = normPRED(pred)

    # Convert to PIL Image
    predict = predict.squeeze()
    predict_np = predict.cpu().data.numpy()
    im = Image.fromarray(predict_np * 255).convert("L")

    # Cleanup.
    del d1, d2, d3, d4, d5, d6, d7

    return im
