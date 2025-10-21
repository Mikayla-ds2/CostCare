import gradio as gr
import pickle
import numpy as np
import pandas as pd

with open('decision_tree_model.pkl', 'rb') as f:
    model = pickle.load(f)

with open('x_scaler.pkl', 'rb') as f:
    scaler_x = pickle.load(f)

with open('y_scaler.pkl', 'rb') as f:
    scaler_y = pickle.load(f)

with open('feature_names.pkl', 'rb') as f:
    featureNames = pickle.load(f)
    
# bias correction values based on error analysis
regionalCorrections = {
    'northeast': 2136,
    'northwest': 0,
    'southeast': 0,
    'southwest': 0
}

def predictInsuranceCost(age, bmi, children, smoker, sex, region):
    smoker_binary = 1 if smoker == "Yes" else 0
    
    features = {
        'age_squared': age ** 2,
        'log_bmi': np.log(bmi),
        'elderly_smoker': 1 if (age >= 39 and smoker_binary == 1) else 0,
        'obese_smoker': 1 if (bmi > 30 and smoker_binary == 1) else 0,
        'has_children': 1 if children > 0 else 0,
        'largeFamily': 1 if children >= 3 else 0,
        'northeast': 1 if region == "Northeast" else 0,
        'northwest': 1 if region == "Northwest" else 0,
        'southeast': 1 if region == "Southeast" else 0,
        'southwest': 1 if region == "Southwest" else 0,
        'female': 1 if sex == "Female" else 0,
        'male': 1 if sex == "Male" else 0,
        'no': 1 - smoker_binary,
        'yes': smoker_binary
    }
    
    missing = set(featureNames) - set(features.keys())
    if missing:
        raise ValueError(f"Missing expected features: {missing}")
    
    features_df = pd.DataFrame([features])[featureNames]
    features_scaled = scaler_x.transform(features_df)
    
    prediction_scaled = model.predict(features_scaled)[0]
    
    prediction_log = scaler_y.inverse_transform([[prediction_scaled]])[0][0]
    
    prediction_raw = np.expm1(prediction_log)
    
    if prediction_raw < 5000:
        tier_correction = 800
    elif prediction_raw < 10000:
        tier_correction = 800
    elif prediction_raw < 20000:
        tier_correction = -200
    else:
        tier_correction = 3000
    
    regional_correction = regionalCorrections.get(region.lower(), 0)
    
    prediction_corrected = prediction_raw + tier_correction + regional_correction
    prediction_corrected = max(prediction_corrected, 0)
    
    if prediction_raw > 20000:
        confidence = "⚠️ Lower Confidence (High-cost case - recommend manual review)"
    elif region == "northeast":
        confidence = "🟡 Moderate Confidence (Regional variation)"
    else:
        confidence = "✅ High Confidence (Typical case)"
        
    if features['obese_smoker'] or features['elderly_smoker']:
        risk = "🔴 High Risk Profile"
    else:
        risk = "🟢 Standard Risk Profile"
    
    return (
        f"${prediction_corrected:,.2f}",
        confidence,
        risk,
        f"Raw prediction: ${prediction_raw:,.2f}\nBias correction: +${tier_correction + regional_correction:,.2f}"
    )
    
demo = gr.Interface(
    fn=predictInsuranceCost,
    inputs=[
        gr.Slider(18, 100, value=35, label="Age", step=1),
        gr.Slider(15, 50, value=28, label="BMI", step=0.1),
        gr.Slider(0, 5, value=0, label="Number of Children", step=1),
        gr.Radio(["Yes", "No"], label="Smoker", value="No"),
        gr.Radio(["Male", "Female"], label="Sex", value="Male"),
        gr.Dropdown(["Northeast", "Northwest", "Southeast", "Southwest"], label="Region", value="Northeast")
    ],
    outputs=[
        gr.Textbox(label="💰 Predicted Annual Insurance Cost"),
        gr.Textbox(label="📊 Prediction Confidence"),
        gr.Textbox(label="🎯 Risk Profile"),
        gr.Textbox(label="ℹ️ Details")
    ],
    title="🏥 Insurance Cost Predictor",
    description="""
    Predicts annual medical insurance costs based on personal information.
    
    **Model:** Decision Tree with Bias Correction (MAE: $1,896, R²: 0.8982)
    
    **Note:** Predictions for high-cost cases (>$20k) and Northeast region have higher uncertainty.
    """,
    examples=[
        [35, 28.5, 2, "Yes", "Male", "Northeast"],
        [45, 32.0, 1, "Yes", "Female", "Southwest"],
        [25, 22.0, 0, "No", "Female", "Southeast"],
    ],
    theme=gr.themes.Soft()
)

if __name__ == "__main__":
    demo.launch(share=True)