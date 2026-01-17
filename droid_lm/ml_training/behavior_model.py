import tensorflow as tf
from tensorflow.keras import layers, Model
import numpy as np
import os

def create_behavior_model(input_shape=(10,)):
    """
    Creates a multi-head neural network for behavioral analysis.
    
    Architecture:
    - Input: 10 numeric features (normalized 0-1)
    - Encoder: Dense layers to extract latent habit embedding
    - Heads:
        1. Habituality (Binary): Is this behavior habitual?
        2. Distraction (Binary): Is the user distracted/doomscrolling?
        3. Stability (Categorical): Stable / Drifting / Chaotic
    """
    
    # --- Input Layer ---
    inputs = layers.Input(shape=input_shape, name='usage_features')
    
    # --- Encoder ---
    # Extracts hierarchical patterns from raw usage stats
    x = layers.Dense(32, activation='relu', name='encoder_1')(inputs)
    x = layers.Dense(24, activation='relu', name='encoder_2')(x)
    
    # Latent Habit Embedding
    # This layer represents the core behavioral signature of the user
    latent_embedding = layers.Dense(16, activation='relu', name='latent_habit_embedding')(x)
    
    # --- Head 1: Habituality ---
    # Binary classification: 0 (Novel/Random) <---> 1 (Habitual/Routine)
    habit_output = layers.Dense(1, activation='sigmoid', name='habit_head')(latent_embedding)
    
    # --- Head 2: Distraction ---
    # Binary classification: 0 (Focused) <---> 1 (Distracted/Doomscrolling)
    distraction_output = layers.Dense(1, activation='sigmoid', name='distraction_head')(latent_embedding)
    
    # --- Head 3: Stability ---
    # Multi-class classification:
    # 0: Stable (Routine is consistent)
    # 1: Drifting (Slowly changing habits)
    # 2: Chaotic (Erratic usage)
    stability_output = layers.Dense(3, activation='softmax', name='stability_head')(latent_embedding)
    
    # --- Model Definition ---
    model = Model(
        inputs=inputs, 
        outputs=[habit_output, distraction_output, stability_output],
        name='droid_lm_behavior_model'
    )
    
    return model

def compile_and_save_model():
    """
    Compiles the model and saves it. 
    Can be converted to TFLite for on-device inference later.
    """
    model = create_behavior_model()
    
    model.compile(
        optimizer='adam',
        loss={
            'habit_head': 'binary_crossentropy',
            'distraction_head': 'binary_crossentropy',
            'stability_head': 'sparse_categorical_crossentropy', # Sparse allows using integer labels (0, 1, 2)
        },
        metrics={
            'habit_head': ['accuracy'],
            'distraction_head': ['accuracy'],
            'stability_head': ['accuracy'],
        }
    )
    
    model.summary()
    
    # Ensure directory exists
    os.makedirs('saved_models', exist_ok=True)
    
    # Save Model
    save_path = 'saved_models/behavior_model.h5'
    model.save(save_path)
    print(f"\nModel saved to: {save_path}")

if __name__ == '__main__':
    # Verify environment (Requires tensorflow installed in your python env)
    try:
        print(f"TensorFlow Version: {tf.__version__}")
        compile_and_save_model()
    except ImportError:
        print("TensorFlow not installed. Run: pip install tensorflow")
