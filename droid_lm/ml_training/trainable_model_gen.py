import tensorflow as tf
import numpy as np
import os

# Constants for Model Architecture
FEATURE_DIM = 34 # Daily behavior features
WINDOW_SIZE = 3  # Sliding window size (Days)
INPUT_DIM = FEATURE_DIM * WINDOW_SIZE # 102 Features (Flattened Temporal Window)
OUTPUT_DIM = 2 # [HabitualityScore, DistractionScore]

class TrainableModel(tf.Module):
    def __init__(self):
        super(TrainableModel, self).__init__()
        # Input: Flattened Temporal Window Vector (102 floats)
        # Why Temporal Windows?
        # By feeding a sequence (Day T-2, T-1, T) as a single flat vector,
        # the model can learn transition patterns (e.g., Increasing Screen Time -> High Distraction).
        # This increases capacity to detect "Momentum" and "Accumulation" effects compared to single-day inputs.
        
    def __init__(self):
        super(TrainableModel, self).__init__()
        # Input: Flattened Temporal Window Vector (102 floats)
        # Architecture: 
        #   Input(102) 
        #   -> Dense(64, ReLU)   [Latent Feature Extraction]
        #   -> Dense(64, ReLU)   [Pattern Consolidation]
        #   -> Dense(32, ReLU)   [Bottleneck / Compression]
        #   -> Dense(2, Linear)  [Projection]
        #   -> Sigmoid           [Normalization 0-1]
        
        # Latent Representation Learning:
        # The deeper stack (64->64) allows the model to map raw usage signals (Volume, Time)
        # into abstract concepts like "Focus State" or "Doomscrolling Routine"
        # before making the final Habituality/Distraction classifications.
        
        # Why Multi-Target Learning?
        # Predicting both Habituality and Distraction simultaneously forces the shared layers
        # (w1, w2, w3) to learn a robust representation of "User State" that is useful for ALL tasks.
        # This regularization prevents overfitting to one specific metric and improves generalization.

        # Layer 1: 102 -> 64
        self.w1 = tf.Variable(tf.random.normal([INPUT_DIM, 64], stddev=0.1), name='w1')
        self.b1 = tf.Variable(tf.zeros([64]), name='b1')
        
        # Layer 2: 64 -> 64
        self.w2 = tf.Variable(tf.random.normal([64, 64], stddev=0.1), name='w2')
        self.b2 = tf.Variable(tf.zeros([64]), name='b2')
        
        # Layer 3: 64 -> 32
        self.w3 = tf.Variable(tf.random.normal([64, 32], stddev=0.1), name='w3')
        self.b3 = tf.Variable(tf.zeros([32]), name='b3')

        # Layer 4: 32 -> 2 (Output)
        self.w4 = tf.Variable(tf.random.normal([32, OUTPUT_DIM], stddev=0.1), name='w4')
        self.b4 = tf.Variable(tf.zeros([OUTPUT_DIM]), name='b4')

        # Optimization
        self.learning_rate = 0.01
        
    def __call__(self, x):
        # Forward pass
        # L1
        x = tf.matmul(x, self.w1) + self.b1
        x = tf.nn.relu(x)
        
        # L2
        x = tf.matmul(x, self.w2) + self.b2
        x = tf.nn.relu(x)
        
        # L3
        x = tf.matmul(x, self.w3) + self.b3
        x = tf.nn.relu(x)

        # L4 (Linear Projection)
        x = tf.matmul(x, self.w4) + self.b4
        
        # Final Activation (0-1 Score)
        return tf.nn.sigmoid(x)

    @tf.function(input_signature=[
        tf.TensorSpec(shape=[None, INPUT_DIM], dtype=tf.float32),  # x input (Batch, 102)
        tf.TensorSpec(shape=[None, OUTPUT_DIM], dtype=tf.float32)  # y target (Batch, 2)
    ])
    def train(self, x, y):
        with tf.GradientTape() as tape:
            prediction = self(x)
            # MSE Loss (Average over Batch and Output Dims)
            loss = tf.reduce_mean(tf.square(y - prediction))
            
        # Gradients
        vars_to_train = [
            self.w1, self.b1, 
            self.w2, self.b2, 
            self.w3, self.b3,
            self.w4, self.b4
        ]
        gradients = tape.gradient(loss, vars_to_train)
        
        # Manual SGD Update
        for var, grad in zip(vars_to_train, gradients):
            var.assign_sub(grad * self.learning_rate)
            
        return {
            "loss": loss, 
            "prediction": prediction
        }

    @tf.function(input_signature=[
        tf.TensorSpec(shape=[None, INPUT_DIM], dtype=tf.float32)
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
            "w3": self.w3, "b3": self.b3,
            "w4": self.w4, "b4": self.b4
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
