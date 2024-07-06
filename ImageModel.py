import os

import requests
from PIL import Image, ImageEnhance, ImageFilter
import pytesseract

from io import BytesIO

# Configure the path to the Tesseract executable (adjust according to your installation)
# image_path = "F:/backend/images/Screenshot 2024-06-17 002659.png"
# with Image.open(image_path) as img:
#     # Rotate the image 90 degrees clockwise
#     rotated_img = img.rotate(-90, expand=True)
#
#     # Path to save the rotated image
#     rotated_image_path = 'images/Screenshot 2024-06-17 002659.png'
#
#     # Save the rotated image
#     rotated_img.save(rotated_image_path)

# pytesseract.pytesseract.tesseract_cmd = 'C:/Program Files/Tesseract-OCR/tesseract.exe'
# print(pytesseract.image_to_string(Image.open(image_path)))


def clean_url(url):
    """Remove anything after .jpg in the URL."""
    folder_path = 'images'

    # Ensure the folder exists
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)

    # Path to save the image
    image_path = os.path.join(folder_path, 'downloaded_image.jpg')

    # Send a GET request to the image URL
    response = requests.get(url)

    # Check if the request was successful
    if response.status_code == 200:
        # Write the image content to a file
        with open(image_path, 'wb') as file:
            file.write(response.content)
        print(f"Image successfully saved to {image_path}")
    else:
        print("Failed to retrieve the image. Status code:", response.status_code)
    return image_path


def extract_text_from_image_url(image_url):
    """Extract text from an image URL using Tesseract OCR."""
    image_path = clean_url(image_url)
    print(image_path)
    result = pytesseract.image_to_string(Image.open(image_path))
    return result.split()


# try:
#     # Check if the URL points to an image file
#     if not check_image_content_type(image_url):
#         return None
#
#     # Fetch the image from the URL
#     response = requests.get(image_url)
#     response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
#
#     # Open the image using PIL
#     img = Image.open(BytesIO(response.content))
#
#     # Preprocess the image
#     img = preprocess_image(img)
#
#     # Extract text using pytesseract
#     text = pytesseract.image_to_string(img, config='--psm 6')  # Adjust psm as needed
#
#     return text.strip()

# except requests.exceptions.RequestException as e:
#     print(f"Failed to retrieve image from URL: {image_url}, error: {e}")
# except Exception as e:
#     print(f"An error occurred: {e}")
#
# return None


def check_image_content_type(image_url):
    try:
        response = requests.head(image_url)  # Send a HEAD request to get headers only
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)

        content_type = response.headers.get('Content-Type')
        if content_type is None:
            raise ValueError('Content-Type header is missing.')

        if 'image/jpeg' in content_type or 'image/png' in content_type:
            print(f"The URL '{image_url}' points to an image file with Content-Type: {content_type}")
            return True
        else:
            print(f"The URL '{image_url}' does not point to an image file (Content-Type: {content_type})")
            return False

    except requests.exceptions.RequestException as e:
        print(f"Failed to retrieve headers from URL: {image_url}, error: {e}")
        return False
    except Exception as e:
        print(f"An error occurred: {e}")
        return False


def preprocess_image(img):
    # Rotate the image to the correct orientation (adjust angle if necessary)
    img = img.rotate(270, expand=True)

    # Convert the image to grayscale
    img = img.convert('L')

    # Enhance contrast
    img = ImageEnhance.Contrast(img).enhance(2)

    # Apply median filter to reduce noise
    img = img.filter(ImageFilter.MedianFilter())

    return img
