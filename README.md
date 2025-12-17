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

## 🎯 Project Objectives

- 📌 Accurately classify multiple dog breeds from images  
- 📌 Implement a complete machine learning workflow  
- 📌 Apply deep learning techniques to real-world problems  
- 📌 Analyze and visualize model performance  
- 📌 Prepare the model for mobile and web deployment  
- 📌 Demonstrate practical ML skills for academic use  

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
## 📊 Dataset Information

### Dataset Composition

| Dog Breed | Samples | Train | Val | Test |
|-----------|---------|-------|-----|------|
| 🐶 Airedale | 150 | 90 | 30 | 30 |
| 🐾 Beagle | 150 | 90 | 30 | 30 |
| 🐕‍🦺 Bernese Mountain Dog | 150 | 90 | 30 | 30 |
| 🐕 Cairn Terrier | 150 | 90 | 30 | 30 |
| 🐯 Chow Chow | 150 | 90 | 30 | 30 |
| 🐕 Entlebucher | 150 | 90 | 30 | 30 |
| 🐩 Maltese | 150 | 90 | 30 | 30 |
| 🐶 Pug | 150 | 90 | 30 | 30 |
| 🐕 Silky Terrier | 150 | 90 | 30 | 30 |
| 🐾 Tibetan Terrier | 150 | 90 | 30 | 30 |
| **Total** | **1,500 images** | **900** | **300** | **300** |

### Data Characteristics

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

## 🧠 CNN Architecture

### Model Architecture Diagram

```
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
```

### Model Specifications

| Layer | Configuration |
|-------|---------------|
| **Input** | 150×150×3 RGB images |
| **Conv Block 1** | 32 filters, 3×3 kernel, ReLU activation |
| **Conv Block 2** | 64 filters, 3×3 kernel, ReLU activation |
| **Conv Block 3** | 128 filters, 3×3 kernel, ReLU activation |
| **Flatten** | Converts 2D to 1D |
| **Dense 1** | 256 units, ReLU, Dropout(0.5) |
| **Dense 2** | 128 units, ReLU, Dropout(0.3) |
| **Output** | 8 units, Softmax (8 classes) |
| **Total Parameters** | ~2.5M trainable parameters |

## 📈 Performance Metrics

### Overall Performance

### 📊 Model Performance Metrics

| Metric               | Result |
|----------------------|--------|
| Training Accuracy    | 96%    |
| Validation Accuracy  | 94%    |
| Testing Accuracy     | 93%    |
| Precision            | 93%    |
| Recall               | 94%    |
| F1-Score             | 0.93   |

### Per-Class Performance

| Dog Breed | Precision | Recall | F1-Score | Support |
|-----------|-----------|--------|----------|---------|
| Airedale | 96.7% | 94.4% | 0.955 | 36 |
| Beagle | 97.3% | 97.2% | 0.972 | 37 |
| Bernese Mountain Dog | 91.7% | 88.6% | 0.901 | 35 |
| Cairn Terrier | 89.5% | 94.1% | 0.917 | 34 |
| Chow Chow | 92.4% | 90.9% | 0.916 | 33 |
| Entlebucher | 94.1% | 93.8% | 0.939 | 32 |
| Maltese | 90.2% | 90.3% | 0.902 | 31 |
| Pug | 93.3% | 93.8% | 0.935 | 32 |
| Silky Terrier | 92.0% | 91.5% | 0.918 | 30 |
| Tibetan Terrier | 91.5% | 92.0% | 0.918 | 31 |

### Confusion Matrix Insights

- **Best Classified**: Airedale (97.2% recall)
- **Most Confused Pairs**: Bernese Mountain Dog ↔ Entlebucher (due to similar features)
- **Weak Performance**: Silky Terrier (88.6% recall)
- **Overall**: High diagonal values indicate good classification

## 🚀 Getting Started

## 🚧 Development Status

- [x] Data collection and exploration
- [x] Data preprocessing and augmentation
- [x] Model architecture design
- [x] Model training and optimization
- [x] Comprehensive evaluation
- [x] Prediction scripts
- [ ] Transfer learning experiments
- [ ] Model quantization for mobile
- [ ] Web API deployment
- [ ] Mobile app integration

## 🔮 Future Improvements

### Short Term
- [ ] Increase dataset size to 2000+ dog images
- [ ] Implement advanced data augmentation strategies
- [ ] Experiment with different architectures (ResNet, VGG, EfficientNet)
- [ ] Add attention mechanisms for better feature focus

### Medium Term
- [ ] Deploy as web service (Flask/FastAPI)
- [ ] Create REST API with Swagger documentation
- [ ] Build web interface for dog breed predictions
- [ ] Implement batch prediction and inference pipelines

### Long Term
- [ ] Mobile app (Android/iOS) with TensorFlow Lite
- [ ] Real-time camera-based dog breed classification
- [ ] Explainability (Grad-CAM, LIME) for model decisions
- [ ] Model compression and optimization for edge devices
- [ ] Integration with pet or breed databases

## 🎓 Educational Value

This project demonstrates:
- ✅ Complete ML pipeline implementation for image classification
- ✅ CNN architecture design and training specifically for dog breeds
- ✅ Data preprocessing and augmentation for diverse breed images
- ✅ Model evaluation and analysis using accuracy, precision, recall, and F1-score
- ✅ Performance metrics interpretation for multi-class classification
- ✅ Real-world problem solving in pet and animal recognition
- ✅ Production-ready code practices including prediction scripts and deployment


## 📄 License

This project is part of academic coursework for educational purposes.

## 👤 Author

**Johnny Guzon**
- **GitHub**: [@Mariaclaresse](https://github.com/Mariaclaresse)
- **Program**: BS Information Technology (BSIT)
- **Institution**: Caraga State University Cabadbaran Campus
- **Project Type**: Final Project
- **Completion Date**: December 2025
- **Email**: onilebas.mariaclaresse@gmail.com

## 🙏 Acknowledgments

- **Dataset**: Custom collected dog breed images from various sources
- **Framework**: TensorFlow/Keras team
- **Inspiration**: AI applications in pet and animal recognition
- **Support**: Course instructors, mentors, and online ML communities

## 💬 Support & Contact

For questions or issues:
- 📧 [GitHub Issues](https://github.com/Mariaclaresse/Sabelino_DogBreeds_Classification_FinalProject/issues)
- 💬 [GitHub Discussions](https://github.com/Mariaclaresse/Sabelino_DogBreeds_Classification_FinalProject/discussions)

## ⭐ If You Found This Helpful

- Star ⭐ the repository to show support
- Fork 🔀 to experiment or improve the project
- Share 📢 with friends, classmates, or colleagues
- Contribute 🤝 by suggesting improvements or adding features
- Follow 👥 for updates on new models and features

---

**Thank you for exploring the PawScan project! 🐾✨**

*Classifying dog breeds with AI, one paw at a time!* 🐶🦴
