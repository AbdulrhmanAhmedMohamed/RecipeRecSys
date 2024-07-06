import ImageModel
import TextModel
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Preload data and model
df, nlp = TextModel.load_data_and_model()


@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    ingredients = data['ingredients']

    try:
        prediction = TextModel.predict_recipes_with_full_details(ingredients, top_n=5)
        result = prediction.to_dict(orient='records')
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

    return jsonify({'prediction': result})


@app.route('/predictImage', methods=['POST'])
def preditImage():
    print("test")
    data = request.json
    FirebaseLink = data['ImageURL']
    ingredients = ImageModel.extract_text_from_image_url(FirebaseLink)
    try:
        prediction = TextModel.predict_recipes_with_full_details(ingredients, top_n=5)
        result = prediction.to_dict(orient='records')
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

    return jsonify({'prediction': result})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
