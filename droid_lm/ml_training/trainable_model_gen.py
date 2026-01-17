import tensorflow as tf
import numpy as np
import os

class TrainableModel(tf.Module):
    def __init__(self):
        super(TrainableModel, self).__init__()
        # Input: 10 features
        # Architecture: Dense(32) -> ReLU -> Dense(16) -> ReLU -> Dense(1) -> Sigmoid
        
        # Layer 1: 10 -> 32
        self.w1 = tf.Variable(tf.random.normal([10, 32], stddev=0.1), name='w1')
        self.b1 = tf.Variable(tf.zeros([32]), name='b1')
        
        # Layer 2: 32 -> 16
        self.w2 = tf.Variable(tf.random.normal([32, 16], stddev=0.1), name='w2')
        self.b2 = tf.Variable(tf.zeros([16]), name='b2')
        
        # Layer 3: 16 -> 1
        self.w3 = tf.Variable(tf.random.normal([16, 1], stddev=0.1), name='w3')
        self.b3 = tf.Variable(tf.zeros([1]), name='b3')

        # Optimization
        self.learning_rate = 0.01
        
    def __call__(self, x):
        # Forward pass
        x = tf.matmul(x, self.w1) + self.b1
        x = tf.nn.relu(x)
        
        x = tf.matmul(x, self.w2) + self.b2
        x = tf.nn.relu(x)
        
        x = tf.matmul(x, self.w3) + self.b3
        return tf.nn.sigmoid(x)

    @tf.function(input_signature=[
        tf.TensorSpec(shape=[None, 10], dtype=tf.float32),  # x input
        tf.TensorSpec(shape=[None, 1], dtype=tf.float32)    # y target
    ])
    def train(self, x, y):
        with tf.GradientTape() as tape:
            prediction = self(x)
            # MSE Loss
            loss = tf.reduce_mean(tf.square(y - prediction))
            
        # Gradients
        vars_to_train = [self.w1, self.b1, self.w2, self.b2, self.w3, self.b3]
        gradients = tape.gradient(loss, vars_to_train)
        
        # Manual SGD Update (Simple & robust for TFLite)
        # optimizer.apply_gradients is complicated in TFLite due to resource variables specifics
        # Simple SGD: w = w - lr * grad
        for var, grad in zip(vars_to_train, gradients):
            var.assign_sub(grad * self.learning_rate)
            
        return {
            "loss": loss, 
            "prediction": prediction
        }

    @tf.function(input_signature=[
        tf.TensorSpec(shape=[None, 10], dtype=tf.float32)
    ])
    def infer(self, x):
        return {
            "output": self(x)
        }
    
    @tf.function(input_signature=[])
    def save(self):
        # Flattened weights
        return {
            "w1": self.w1, "b1": self.b1,
            "w2": self.w2, "b2": self.b2,
            "w3": self.w3, "b3": self.b3
        }

def create_and_convert():
    model = TrainableModel()
    
    # 1. Save as SavedModel
    saved_model_path = "saved_models/trainable_micro"
    tf.saved_model.save(
        model,
        saved_model_path,
        signatures={
            'train': model.train,
            'infer': model.infer,
            'save': model.save,
        }
    )
    print(f"SavedModel created at: {saved_model_path}")
    
    # 2. Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,  
        tf.lite.OpsSet.SELECT_TF_OPS 
    ]
    converter.experimental_enable_resource_variables = True
    
    tflite_model = converter.convert()
    
    tflite_path = "saved_models/trainable_micro_model.tflite"
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
        
    print(f"TFLite (Trainable) Model saved to: {tflite_path}")

if __name__ == "__main__":
    try:
        if not os.path.exists("saved_models"):
            os.makedirs("saved_models")
        
        create_and_convert()
        
    except ImportError:
        print("Error: TensorFlow not found. Please install: pip install tensorflow")
    except Exception as e:
        import traceback
        traceback.print_exc()
