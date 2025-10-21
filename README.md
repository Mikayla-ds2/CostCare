## CostCare
CostCare is a project that predicts annual medical insurance costs using personal health and demographic info. Built with scikit-learn Decision Tree Regressor, Python, and TensorFlow/Keras, and deployed with Gradio on Hugging Face Spaces. You input your age, BMI, smoker status, sex, number of children, and region. The model will then output your yearly insurance cost, prediction confidence, risk profile, and additional details. It achieved an accuracy of 89% (R² = 0.8982) and highlights high-risk profiles. 

Beyond just predictions, I uncovered serious failure modes — high-cost cases were underpredicted by thousands and regional pricing was way off. I built custom corrections to fix these blind spots, improving real-world accuracy. The biggest thing to overcome was the error analysis and found out the outlier errors (9%) account for over 63% of total prediction error. I also hate deploying machine learning models but the process helps clean up any errors that might pop up later. I did notice a data scarcity problem where all 3 models I used had a 28.3% failure rate on cases with higher than $20K.

## Model Performance Comparison
| Model           | MAE     | R²     | Best For                    |
|----------------|---------|--------|-----------------------------|
| Decision Tree ⭐ | $1,896  | 0.8982 | Production (best accuracy)  |
| Random Forest   | $2,247  | 0.8886 | General use                 |
| Neural Network  | $2,215  | 0.8897 | Bias calibration            |

[![Athena Award Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Faward.athena.hackclub.com%2Fapi%2Fbadge)](https://award.athena.hackclub.com?utm_source=readme)
