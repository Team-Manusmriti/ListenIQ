# quantization.py
def quantize_model(model_path, output_path, representative_dataset=None):
    """
    Quantize model for better mobile performance
    """
    converter = tf.lite.TFLiteConverter.from_saved_model(model_path)
    
    # Enable quantization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Optional: Representative dataset for better quantization
    if representative_dataset:
        converter.representative_dataset = representative_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8
    
    tflite_quantized_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_quantized_model)