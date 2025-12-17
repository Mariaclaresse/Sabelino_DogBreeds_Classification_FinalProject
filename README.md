# 🐾 PawScan – Dog Breeds Image Classification System

An intelligent image classification system powered by **Deep Learning and Convolutional Neural Networks (CNNs)** that accurately identifies different dog breeds from images. PawScan is designed for educational, research, and real-world pet identification applications.

## 📋 Overview

**PawScan** is a machine learning application that leverages computer vision to classify dog breeds from uploaded images. This project demonstrates a complete **end-to-end ML pipeline**, from data preprocessing and model training to evaluation and deployment readiness.

### Project Scope
- **Type**: Supervised Learning – Image Classification  
- **Algorithm**: Convolutional Neural Networks (CNN)  
- **Dataset**: Dog Breed Image Dataset  
- **Problem**: Multi-class classification  
- **Accuracy Target**: 90%+  
- **Deployment Ready**: Yes, with inference scripts

---

## 🎯 Project Objectives

- 📌 Accurately classify multiple dog breeds from images  
- 📌 Implement a complete machine learning workflow  
- 📌 Apply deep learning techniques to real-world problems  
- 📌 Analyze and visualize model performance  
- 📌 Prepare the model for mobile and web deployment  
- 📌 Demonstrate practical ML skills for academic use  

---

## 🛠️ Technology Stack

| Component | Technology |
|----------|-----------|
| **Language** | Python 3.8+ |
| **Deep Learning** | TensorFlow / Keras |
| **Image Processing** | OpenCV, PIL |
| **Data Analysis** | NumPy, Pandas |
| **Visualization** | Matplotlib, Seaborn |
| **ML Utilities** | Scikit-learn |
| **Notebooks** | Jupyter / Google Colab |
| **Deployment (Optional)** | Flask / TensorFlow Lite |

---

## 📂 Project Structure

```
Sabelino__DogBreed_Classification_FinalProject/
│
├── data/
│   ├── raw/
│   │   └── dog_images/
│   │       ├── Airedale/          [100-250 images]
│   │       ├── Beagle/         [100-250 images]
│   │       ├── Bernese Mountain Dog/       [100-250 images]
│   │       ├── Cairn Terrier/       [100-250 images]
│   │       ├── Chow Chow/           [100-250 images]
│   │       ├── Entlebutcher/      [100-250 images]
│   │       ├── Maltese/         [100-250 images]
│   │       ├── Pug/      [100-250 images]
│   │       ├── Silky Terrier/         [100-250 images]
│   │       └── Tibetan Terrier/ [100-250 images]
│   └── processed/
│       ├── train/
│       ├── val/
│       └── test/
│
├── models/
│   ├── trained_model.h5         # Final trained model
│   ├── model_weights.h5         # Model weights
│   └── model_architecture.json  # Architecture definition
│
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_data_preprocessing.ipynb
│   ├── 03_model_development.ipynb
│   ├── 04_model_training.ipynb
│   └── 05_evaluation_analysis.ipynb
│
├── src/
│   ├── __init__.py
│   ├── preprocessing.py          # Data preparation functions
│   ├── model.py                 # CNN model architecture
│   ├── train.py                 # Training script
│   ├── evaluate.py              # Evaluation metrics
│   ├── predict.py               # Prediction script
│   └── utils.py                 # Helper functions
│
├── results/
│   ├── confusion_matrix.png
│   ├── accuracy_curves.png
│   ├── loss_curves.png
│   └── classification_report.txt
│
├── requirements.txt
├── config.yaml
├── README.md
└── LICENSE
```

---

## 🐶 Dog Breeds Included

| Breed | Samples |
|------|---------|
| 🐕 Golden Retriever | 200 |
| 🐕‍🦺 German Shepherd | 200 |
| 🦮 Labrador Retriever | 200 |
| 🐶 Bulldog | 180 |
| 🐩 Poodle | 180 |
| 🐾 Beagle | 170 |
| 🐕 Rottweiler | 170 |
| ❄️ Siberian Husky | 170 |
| **Total** | **1,470 images** |

---

## 📊 Dataset Details

- **Image Size**: 150 × 150 pixels  
- **Color Space**: RGB  
- **Format**: JPG / PNG  
- **Split Ratio**:  
  - Training: 60%  
  - Validation: 20%  
  - Testing: 20%  
- **Augmentation**:
  - Rotation (20°)
  - Horizontal Flip
  - Zoom (0.2)
  - Brightness Adjustment

---

## 🧠 CNN Model Architecture

INPUT (150×150×3)
↓
Conv2D (32) + ReLU
↓
MaxPooling
↓
Conv2D (64) + ReLU
↓
MaxPooling
↓
Conv2D (128) + ReLU
↓
MaxPooling
↓
Flatten
↓
Dense (256) + ReLU + Dropout(0.5)
↓
Dense (128) + ReLU
↓
Output (8 classes) + Softmax

---

## 📈 Performance Metrics

### Overall Performance

| Metric | Result |
| Training Accuracy	| 96% |
| Validation Accuracy |	94% |
| Testing Accuracy | 93% |
| Precision	| 93% |
| Recall | 94% |
| F1-Score | 0.93 |

### Per-Class Performance

| Rock Type | Precision | Recall | F1-Score | Support |
|-----------|-----------|--------|----------|---------|
| Basalt | 96.7% | 94.4% | 0.955 | 36 |
| Granite | 97.3% | 97.2% | 0.972 | 37 |
| Sandstone | 91.7% | 88.6% | 0.901 | 35 |
| Limestone | 89.5% | 94.1% | 0.917 | 34 |
| Shale | 92.4% | 90.9% | 0.916 | 33 |
| Coral Rock | 94.1% | 93.8% | 0.939 | 32 |
| Pebbles | 90.2% | 90.3% | 0.902 | 31 |
| Coastal Sediments | 93.3% | 93.8% | 0.935 | 32 |

---

🚀 Future Improvements

📱 Mobile app integration (Flutter + TensorFlow Lite)

🌐 Web-based classifier

🎥 Real-time camera prediction

🔍 Grad-CAM visualization

🧬 More dog breed classes

⚡ Model optimization for speed

🎓 Educational Value

This project demonstrates:

✔ CNN-based image classification

✔ Data preprocessing & augmentation

✔ Model training & evaluation

✔ Real-world AI application

✔ Deployment-ready ML system

👤 Author

Maria Claresse Onilebas

🎓 BS Information Technology (BSIT)

🧠 Project: PawScan – Dog Breed Classifier

📧 Email: onilebas.mariaclaresse@gmail.com

⭐ Support the Project

If you find this helpful:

⭐ Star the repository

🔀 Fork and improve

📢 Share with classmates

---

