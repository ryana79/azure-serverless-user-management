@echo off
echo Deploying Python application...

:: Create and activate virtual environment
python -m venv env
call env\Scripts\activate

:: Install dependencies
pip install -r requirements.txt

:: Create startup command file
echo python runserver.py > startup.txt

:: Deploy the application
echo Deployment completed. 