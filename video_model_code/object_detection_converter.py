# convert_to_tflite.py
import os, sys, traceback, json
from pathlib import Path
import torch

OUT_DIR = Path("tflite_conversion")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Config
MODEL_PY = "action_model.py"      # path to your model definition file
CHECKPOINT = "best_model.pt"      # path to checkpoint
SEQ_LEN = 16                      # frames in clip used by your model
IMG_H, IMG_W = 112, 112           # spatial size used in preprocess
BATCH = 1

# Ensure module path
sys.path.append(os.getcwd())

def safe_import_action_model():
    try:
        from action_model import CNN_GRU
        return CNN_GRU
    except Exception as e:
        print("Failed to import CNN_GRU from action_model.py:")
        traceback.print_exc()
        raise

def load_pytorch_model(CNN_GRU_cls, checkpoint_path, device="cpu"):
    model = CNN_GRU_cls(num_classes=5, hidden_size=128)
    ckpt = torch.load(checkpoint_path, map_location=device)
    # Try common checkpoint formats
    try:
        if isinstance(ckpt, dict) and all(isinstance(k, str) for k in ckpt.keys()):
            model.load_state_dict(ckpt)
        else:
            # if full model object was saved
            model = ckpt
    except Exception:
        try:
            model.load_state_dict(ckpt.get('model_state_dict', ckpt))
        except Exception:
            print("Could not load checkpoint with common heuristics; examine checkpoint format.")
            raise
    model.to(device).eval()
    return model

def export_to_onnx(model, out_path, seq_len=SEQ_LEN):
    dummy = torch.randn(BATCH, seq_len, 3, IMG_H, IMG_W)
    print("Exporting to ONNX:", out_path)
    torch.onnx.export(
        model,
        dummy,
        out_path,
        opset_version=12,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch", 1: "seq_len"}, "output": {0: "batch"}},
        do_constant_folding=True
    )
    print("ONNX export done.")

def onnx_to_savedmodel(onnx_path, saved_model_dir):
    try:
        import onnx
        from onnx import load as onnx_load
        onnx_model = onnx_load(onnx_path)
    except Exception as e:
        print("onnx package not available or failed to load model.")
        raise

    # Try onnx-tf
    try:
        from onnx_tf.backend import prepare
        tf_rep = prepare(onnx_model)
        tf_rep.export_graph(str(saved_model_dir))
        print("SavedModel exported to:", saved_model_dir)
        return True
    except Exception:
        traceback.print_exc()
        print("onnx-tf failed. You can try `tf2onnx` or convert manually in TF.")
        return False

def savedmodel_to_tflite(saved_model_dir, tflite_path):
    import tensorflow as tf
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_dir))
    # Optional optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print("TFLite saved to:", tflite_path)

if __name__ == "__main__":
    try:
        CNN_GRU = safe_import_action_model()
    except Exception as e:
        print("Import error. Ensure torch & torchvision are installed and compatible.")
        sys.exit(1)

    if not os.path.exists(CHECKPOINT):
        print("Checkpoint not found:", CHECKPOINT)
        sys.exit(1)

    device = "cpu"
    try:
        model = load_pytorch_model(CNN_GRU, CHECKPOINT, device=device)
    except Exception:
        print("Failed loading PyTorch model.")
        sys.exit(1)

    onnx_path = OUT_DIR / "action_model.onnx"
    saved_model_dir = OUT_DIR / "saved_model"
    tflite_path = OUT_DIR / "action_model.tflite"
    try:
        export_to_onnx(model, str(onnx_path))
    except Exception:
        print("ONNX export failed. Check model forward signature and that opset_version is appropriate.")
        traceback.print_exc()
        sys.exit(1)

    # Try ONNX -> SavedModel
    ok = False
    try:
        ok = onnx_to_savedmodel(str(onnx_path), str(saved_model_dir))
    except Exception:
        ok = False

    if not ok:
        print("\nONNX->SavedModel failed. Two alternatives:")
        print("  1) Use tf2onnx: python -m tf2onnx.convert --input action_model.onnx --output saved_model_dir --opset 13")
        print("  2) Reimplement model in TF/Keras and load weights manually.")
    else:
        # Convert SavedModel -> TFLite
        try:
            savedmodel_to_tflite(str(saved_model_dir), str(tflite_path))
            print("All done. TFLite at:", tflite_path)
        except Exception:
            print("SavedModel -> TFLite conversion failed:")
            traceback.print_exc()
            sys.exit(1)
