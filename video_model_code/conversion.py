import torch

# Load your PyTorch model
model = torch.load('best_model.pt')
model.eval()

# Example input (adjust shape to your model's expected input)
dummy_input = torch.randn(1, 3, 224, 224)

# Export to ONNX
torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    input_names=['input'],
    output_names=['output'],
    opset_version=11
)