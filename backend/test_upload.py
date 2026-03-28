import requests

url = "http://localhost:3000/api/crop-advice"
file_path = r"C:\Users\Lenovo\Downloads\leaff.jpg"

files = {"file": open(file_path, "rb")}

response = requests.post(url, files=files)

print("Status:", response.status_code)
print("Response:", response.text)
