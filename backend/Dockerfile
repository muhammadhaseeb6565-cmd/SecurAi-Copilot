FROM python:3.11-slim

# Create a non-root user (Required by Hugging Face Spaces)
RUN useradd -m -u 1000 user

# Set the working directory
WORKDIR /app

# Copy requirements and install them
COPY --chown=user:user requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your backend code
COPY --chown=user:user . .

# Switch to the non-root user
USER user

# Expose the default Hugging Face Spaces port
EXPOSE 7860

# Start the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
