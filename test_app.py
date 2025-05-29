import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_route(client):
    """Test the home route returns correct response"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome to the Flask Azure DevOps Demo!' in response.data

def test_status_route(client):
    """Test the status API route returns correct JSON"""
    response = client.get('/api/status')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert 'version' in data
    assert 'environment' in data 