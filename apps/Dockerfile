# Use a lightweight Python base
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the current folder's content into the container
COPY . /app

# Install the web server
RUN pip install flask

# Tell the container to run our script
CMD ["python", "app.py"]