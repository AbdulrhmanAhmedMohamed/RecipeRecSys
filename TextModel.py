# Textmodel.py

import pandas as pd
import string
import re
import numpy as np
import spacy
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)

# Load the spaCy model
nlp = spacy.load('en_core_web_md')

# Load the dataset
file_path = 'updated_cleaned_dataset.csv'
df = pd.read_csv(file_path)

# Combine relevant fields into a single text column
df['text'] = df['Recipe Name'] + ' ' + df['Ingredient 1'] + ' ' + df['Ingredient 2'] + ' ' + \
             df['Ingredient 3'] + ' ' + df['Ingredient 4'] + ' ' + df['Ingredient 5'] + ' ' + \
             df['Preparation Method']

# Convert text to lowercase and remove punctuation
df['text'] = df['text'].str.lower().apply(lambda x: x.translate(str.maketrans('', '', string.punctuation)))

# Tokenize text
df['tokens'] = df['text'].apply(lambda x: re.split('\W+', x))

# Identify and remove stopwords
default_stopwords = set([
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours',
    'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers',
    'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
    'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are',
    'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does',
    'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until',
    'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through',
    'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out',
    'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when',
    'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other',
    'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
    's', 't', 'can', 'will', 'just', 'don', 'should', 'now'
])
recipe_specific_stopwords = {'cup', 'tablespoon', 'teaspoon', 'grams', 'ml', 'minutes', 'hours', 'ounce', 'pound', 'lb',
                             'oz', 'g', 'kg'}  # Add more if necessary
stop_words = default_stopwords.union(recipe_specific_stopwords)
df['tokens'] = df['tokens'].apply(lambda x: [word for word in x if word not in stop_words])


# Lemmatization using spaCy
def lemmatize(tokens):
    doc = nlp(' '.join(tokens))
    return [token.lemma_ for token in doc]


df['tokens'] = df['tokens'].apply(lemmatize)


# Generate embeddings for each recipe by averaging word vectors
def get_embedding(tokens, model):
    vectors = [model.vocab[token].vector for token in tokens if token in model.vocab]
    return np.mean(vectors, axis=0) if vectors else np.zeros(model.vocab.vectors.shape[1])


df['embedding'] = df['tokens'].apply(lambda x: get_embedding(x, nlp))


# Helper function to calculate similarity
def calculate_similarity(embedding1, embedding2):
    norm1 = np.linalg.norm(embedding1)
    norm2 = np.linalg.norm(embedding2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return np.dot(embedding1, embedding2) / (norm1 * norm2)


# Convert 'Cooking Time' to string to ensure compatibility with .str methods
df['Cooking Time'] = df['Cooking Time'].astype(str)

# Extract numerical values from 'Cooking Time' and convert to float
df['Cooking Time (min)'] = df['Cooking Time'].str.extract('(\d+)').astype(float)

# Create additional features
df['num_ingredients'] = df[
    ['Ingredient 1', 'Ingredient 2', 'Ingredient 3', 'Ingredient 4', 'Ingredient 5']].notna().sum(axis=1)
df['difficulty'] = df['num_ingredients'] / df['Cooking Time (min)']  # Simplified difficulty metric


# Define the prediction function to include preparation method, cooking time, and servings
def predict_recipes_with_full_details(ingredients, top_n=5):
    # Ensure exactly 5 ingredients
    if len(ingredients) != 5:
        raise ValueError("Please provide exactly 5 ingredients.")

    logging.info(f"Received ingredients for prediction: {ingredients}")

    # Preprocess the input ingredients (tokenize, remove stopwords, lemmatize)
    ingredients_tokens = []
    for ingredient in ingredients:
        words = ingredient.lower().split()
        words = [token.lemma_ for token in nlp(' '.join(words)) if token.lemma_ not in stop_words]
        ingredients_tokens.extend(words)

    logging.info(f"Preprocessed ingredients tokens: {ingredients_tokens}")

    # Get the embedding for the input ingredients
    ingredients_embedding = np.mean([nlp.vocab[token].vector for token in ingredients_tokens if token in nlp.vocab],
                                    axis=0)

    if ingredients_embedding is None or np.isnan(ingredients_embedding).any():
        raise ValueError("Could not generate a valid embedding for the provided ingredients.")

    # Calculate similarity scores between the input ingredients and all recipes
    df['similarity'] = df['embedding'].apply(lambda x: calculate_similarity(x, ingredients_embedding))

    # Sort recipes based on similarity scores
    sorted_df = df.sort_values(by='similarity', ascending=False)

    # Return the top N results with recipe name, preparation method, cooking time, and servings
    result = sorted_df.head(top_n)[['Cooking Time', 'Preparation Method','Recipe Name' ]]

    logging.info(f"{result}")

    return result


def load_data_and_model():
    # Preload the data and the model when the server starts
    logging.info("Loading data and model...")
    return df, nlp
