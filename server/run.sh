#!/bin/bash

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Set Flask environment variables
export FLASK_APP=main.py
export FLASK_ENV=development

# Run the Flask server
flask run --host=0.0.0.0 --port=3000 --debug