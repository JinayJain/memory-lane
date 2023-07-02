import io
import os
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from PIL import Image
import time
import logging
from matplotlib import pyplot as plt

import numpy as np
from inventory.model import zoedepth

from inventory.model import u2net

logging.basicConfig(level=logging.INFO)

MODEL_DIR = "saved-models"

# Initialize the Flask application
app = Flask(__name__)
CORS(app)


@app.route("/", methods=["GET"])
def hello():
    return "pong"


# Route http posts to this method
@app.route("/", methods=["POST"])
def run():
    start = time.time()

    # Convert string of image data to uint8
    if "data" not in request.files:
        return jsonify({"error": "missing file param `data`"}), 400
    data = request.files["data"].read()
    if len(data) == 0:
        return jsonify({"error": "empty image"}), 400

    # Convert string data to PIL Image
    img = Image.open(io.BytesIO(data))

    model_input = img.copy()
    model_input.thumbnail((1024, 1024))

    # Process Image
    res_segment = u2net.run(model_input, MODEL_DIR).resize(img.size)
    img.putalpha(res_segment)

    depth_img, mesh = zoedepth.run(model_input)

    bbox = res_segment.getbbox()

    if bbox is None:
        return jsonify({"error": "no object detected"}), 400

    img = img.crop(bbox)

    img.thumbnail((1024, 1024))

    # Save to buffer
    buff = io.BytesIO()
    img.save(buff, "PNG")
    buff.seek(0)

    # Print stats
    logging.info(f"Completed in {time.time() - start:.2f}s")

    # Return data
    # return send_file(buff, mimetype="image/png")

    return send_file(mesh, mimetype="model/gltf-binary")


if __name__ == "__main__":
    os.environ["FLASK_ENV"] = "development"
    port = int(os.environ.get("PORT", 8080))
    app.run(debug=True, host="0.0.0.0", port=port)
