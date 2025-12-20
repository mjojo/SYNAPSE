#!/usr/bin/env python3
"""
TITAN Neural Engine - Weight Exporter
Trains a simple MLP on MNIST and exports weights for TITAN inference.

Requirements: pip install torch torchvision numpy
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
import numpy as np
import os

# --- 1. Network Architecture (TITAN-compatible) ---
class TitanNet(nn.Module):
    def __init__(self):
        super(TitanNet, self).__init__()
        # Input 784 -> Hidden 128 -> Output 10
        self.fc1 = nn.Linear(784, 128)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = x.view(-1, 784)  # Flatten
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# --- 2. Load Data ---
print("📥 Loading MNIST dataset...")
transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize((0.5,), (0.5,))  # Normalize to [-1, 1]
])
train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
test_dataset = datasets.MNIST(root='./data', train=False, transform=transform)
train_loader = torch.utils.data.DataLoader(dataset=train_dataset, batch_size=64, shuffle=True)

# --- 3. Training ---
model = TitanNet()
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

print("💪 Training network (The Gym)...")
for epoch in range(3):  # 3 epochs is enough for ~97% accuracy
    total_loss = 0
    batches = 0
    for images, labels in train_loader:
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
        batches += 1
    print(f"   Epoch {epoch+1}/3 complete. Avg Loss: {total_loss/batches:.4f}")

# --- 4. Test Accuracy ---
print("\n📊 Testing accuracy...")
correct = 0
total = 0
with torch.no_grad():
    for images, labels in torch.utils.data.DataLoader(test_dataset, batch_size=1000):
        outputs = model(images)
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()
print(f"   Test Accuracy: {100 * correct / total:.2f}%")

# --- 5. Export for TITAN (Binary Float64) ---
print("\n💾 Exporting weights to Binary (Float64/Double)...")

def save_bin(name, tensor):
    """Save tensor as binary float64 file.
    
    Important: TITAN uses float64 (double).
    PyTorch stores weights as [Out, In], we need [In, Out] for MATMUL -> .T (Transpose)
    """
    if len(tensor.shape) == 2:
        # Weight matrix: transpose for row-major MATMUL
        data = tensor.detach().numpy().T.astype(np.float64)
    else:
        # Bias vector: no transpose needed
        data = tensor.detach().numpy().astype(np.float64)
    
    data.tofile(name)
    shape_str = str(data.shape)
    print(f"   Saved {name}: {shape_str:20s} -> {os.path.getsize(name):,} bytes")

# Save weights and biases
save_bin("w1.bin", model.fc1.weight)  # Will be 784x128
save_bin("b1.bin", model.fc1.bias)    # Will be 128
save_bin("w2.bin", model.fc2.weight)  # Will be 128x10
save_bin("b2.bin", model.fc2.bias)    # Will be 10

# --- 6. Export Test Image ---
# Find a good test image (look for different digits)
print(f"\n📸 Exporting test images...")

# Export a few test images with different digits
for test_idx in [0, 1, 2, 3, 7, 9, 15, 25, 33, 42]:
    img, label = test_dataset[test_idx]
    flat_img = img.view(-1).numpy().astype(np.float64)
    filename = f"digit_{label}_{test_idx}.bin"
    flat_img.tofile(filename)
    print(f"   Saved {filename} (Label: {label})")

# Save a default test image as img.bin
img, label = test_dataset[7]  # Usually a nice clear digit
flat_img = img.view(-1).numpy().astype(np.float64)
flat_img.tofile("img.bin")
print(f"\n   Default img.bin saved (Label: {label})")

# --- Summary ---
print("\n" + "="*50)
print("✅ READY FOR TITAN INFERENCE!")
print("="*50)
print("\nGenerated files:")
print(f"   w1.bin  - Layer 1 weights (784×128) = {784*128*8:,} bytes")
print(f"   b1.bin  - Layer 1 biases  (128)     = {128*8:,} bytes")
print(f"   w2.bin  - Layer 2 weights (128×10)  = {128*10*8:,} bytes")
print(f"   b2.bin  - Layer 2 biases  (10)      = {10*8:,} bytes")
print(f"   img.bin - Test image      (784)     = {784*8:,} bytes")
print(f"\nTotal weights: {(784*128 + 128 + 128*10 + 10) * 8:,} bytes (~{(784*128 + 128 + 128*10 + 10) * 8 / 1024:.0f} KB)")
print("\nRun: titan.exe neural_core.ttn")
