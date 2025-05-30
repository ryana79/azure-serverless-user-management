// Application state
let apiBaseUrl = '';
let usersCreatedCount = 0;
let refreshCount = 0;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    console.log('Azure Serverless User Management App initialized');
    
    // Set initial API URL from input
    const apiUrlInput = document.getElementById('apiUrl');
    apiBaseUrl = apiUrlInput.value;
    
    // Add event listeners
    setupEventListeners();
    
    // Load users on startup
    loadUsers();
});

function setupEventListeners() {
    // API URL change handler
    document.getElementById('apiUrl').addEventListener('change', function(e) {
        apiBaseUrl = e.target.value;
        console.log('API URL updated:', apiBaseUrl);
    });
    
    // User form submission
    document.getElementById('userForm').addEventListener('submit', function(e) {
        e.preventDefault();
        createUser();
    });
}

async function testConnection() {
    const statusDiv = document.getElementById('connectionStatus');
    
    if (!apiBaseUrl) {
        showStatus(statusDiv, 'error', 'Please enter an API URL first');
        return;
    }
    
    showStatus(statusDiv, 'loading', 'Testing connection...');
    
    try {
        const response = await fetch(`${apiBaseUrl}/api/users`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'X-Correlation-ID': generateCorrelationId()
            }
        });
        
        if (response.ok) {
            showStatus(statusDiv, 'success', '✅ Connection successful! API is responding.');
        } else {
            showStatus(statusDiv, 'error', `❌ Connection failed with status: ${response.status}`);
        }
    } catch (error) {
        console.error('Connection test failed:', error);
        showStatus(statusDiv, 'error', '❌ Connection failed. Please check the URL and network connectivity.');
    }
}

async function createUser() {
    const form = document.getElementById('userForm');
    const resultDiv = document.getElementById('createResult');
    const formData = new FormData(form);
    
    const userData = {
        name: formData.get('name').trim(),
        email: formData.get('email').trim()
    };
    
    // Validate input
    if (!userData.name || !userData.email) {
        showStatus(resultDiv, 'error', 'Please fill in all required fields');
        return;
    }
    
    if (!apiBaseUrl) {
        showStatus(resultDiv, 'error', 'Please configure the API URL first');
        return;
    }
    
    showStatus(resultDiv, 'loading', 'Creating user...');
    
    try {
        const response = await fetch(`${apiBaseUrl}/api/user`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Correlation-ID': generateCorrelationId()
            },
            body: JSON.stringify(userData)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showStatus(resultDiv, 'success', `✅ User "${userData.name}" created successfully!`);
            form.reset();
            usersCreatedCount++;
            updateStatistics();
            
            // Refresh the users list
            await loadUsers();
        } else {
            showStatus(resultDiv, 'error', `❌ Error: ${data.error || 'Failed to create user'}`);
        }
    } catch (error) {
        console.error('Error creating user:', error);
        showStatus(resultDiv, 'error', '❌ Network error. Please check your connection and API URL.');
    }
}

async function loadUsers() {
    const loadingDiv = document.getElementById('loadingUsers');
    const usersListDiv = document.getElementById('usersList');
    const errorDiv = document.getElementById('usersError');
    
    // Reset states
    loadingDiv.classList.remove('hidden');
    errorDiv.classList.add('hidden');
    usersListDiv.innerHTML = '';
    
    if (!apiBaseUrl) {
        loadingDiv.classList.add('hidden');
        usersListDiv.innerHTML = '<p class="text-gray-500 text-center py-4">Please configure the API URL first</p>';
        return;
    }
    
    try {
        const response = await fetch(`${apiBaseUrl}/api/users`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'X-Correlation-ID': generateCorrelationId()
            }
        });
        
        if (response.ok) {
            const users = await response.json();
            displayUsers(users);
            refreshCount++;
            updateStatistics();
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (error) {
        console.error('Error loading users:', error);
        loadingDiv.classList.add('hidden');
        errorDiv.classList.remove('hidden');
    } finally {
        loadingDiv.classList.add('hidden');
    }
}

function displayUsers(users) {
    const usersListDiv = document.getElementById('usersList');
    
    if (!users || users.length === 0) {
        usersListDiv.innerHTML = `
            <div class="text-center py-8">
                <i class="fas fa-user-slash text-4xl text-gray-400 mb-4"></i>
                <p class="text-gray-500">No users found. Create your first user!</p>
            </div>
        `;
        return;
    }
    
    const usersHtml = users.map(user => createUserCard(user)).join('');
    usersListDiv.innerHTML = usersHtml;
    
    // Update total users count
    document.getElementById('totalUsers').textContent = users.length;
}

function createUserCard(user) {
    const createdDate = new Date(user.created_at).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    return `
        <div class="user-card bg-gray-50 p-4 rounded-lg border border-gray-200">
            <div class="flex items-start justify-between">
                <div class="flex-1">
                    <h3 class="font-semibold text-gray-900 flex items-center">
                        <i class="fas fa-user text-blue-600 mr-2"></i>
                        ${escapeHtml(user.name)}
                    </h3>
                    <p class="text-gray-600 text-sm flex items-center mt-1">
                        <i class="fas fa-envelope text-gray-400 mr-2"></i>
                        ${escapeHtml(user.email)}
                    </p>
                    <p class="text-gray-500 text-xs mt-2 flex items-center">
                        <i class="fas fa-clock text-gray-400 mr-2"></i>
                        Created: ${createdDate}
                    </p>
                </div>
                <div class="ml-4">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        <i class="fas fa-check-circle mr-1"></i>
                        Active
                    </span>
                </div>
            </div>
            <div class="mt-3 text-xs text-gray-400">
                ID: ${escapeHtml(user.id)}
            </div>
        </div>
    `;
}

function updateStatistics() {
    document.getElementById('usersCreated').textContent = usersCreatedCount;
    document.getElementById('refreshCount').textContent = refreshCount;
}

function showStatus(element, type, message) {
    const icons = {
        success: '<i class="fas fa-check-circle mr-2"></i>',
        error: '<i class="fas fa-exclamation-circle mr-2"></i>',
        loading: '<i class="fas fa-spinner fa-spin mr-2"></i>',
        info: '<i class="fas fa-info-circle mr-2"></i>'
    };
    
    const colors = {
        success: 'text-green-700 bg-green-100 border-green-200',
        error: 'text-red-700 bg-red-100 border-red-200',
        loading: 'text-blue-700 bg-blue-100 border-blue-200',
        info: 'text-blue-700 bg-blue-100 border-blue-200'
    };
    
    element.innerHTML = `
        <div class="flex items-center p-3 border rounded-md ${colors[type]}">
            ${icons[type]}
            <span>${message}</span>
        </div>
    `;
    
    // Auto-hide success messages after 5 seconds
    if (type === 'success') {
        setTimeout(() => {
            element.innerHTML = '';
        }, 5000);
    }
}

function generateCorrelationId() {
    return 'web-' + Math.random().toString(36).substr(2, 9);
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Global functions for HTML onclick handlers
window.testConnection = testConnection;
window.loadUsers = loadUsers;

// Add some helpful console messages for developers
console.log(`
🚀 Azure Serverless User Management App
📋 Available functions:
  - testConnection() - Test API connectivity
  - loadUsers() - Refresh users list
  - createUser() - Create new user (form submission)

🔧 API Configuration:
  Current URL: ${apiBaseUrl}
  
💡 Pro tip: Open browser developer tools to see detailed logs
`);

// Handle offline/online status
window.addEventListener('online', function() {
    console.log('✅ Connection restored');
});

window.addEventListener('offline', function() {
    console.log('❌ Connection lost');
    const statusElements = document.querySelectorAll('#connectionStatus, #createResult');
    statusElements.forEach(el => {
        showStatus(el, 'error', '❌ No internet connection detected');
    });
}); 