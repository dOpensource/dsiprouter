var settings_table;
let settingsData = {};

// Load settings on page load
document.addEventListener('DOMContentLoaded', function() {
  loadSettingsTable();
});

function getCategoryFromKey(key) {
  if (!key || typeof key !== 'string') return 'GENERAL';
  const parts = key.split('_');
  return parts.length > 1 ? parts[0] : 'GENERAL';
}

function normalizeSettingsResponse(response) {
  if (!response || !response.data) return [];

  const settingsObject = Array.isArray(response.data) ? response.data[0] : response.data;
  if (!settingsObject || typeof settingsObject !== 'object') return [];

  settingsData = settingsObject;

  return Object.keys(settingsObject).map((key) => ({
    key: key,
    value: settingsObject[key],
    category: getCategoryFromKey(key)
  }));
}



function loadSettingsTable() {
  // Reinitialize table to avoid duplicate DataTable instances.
  if ($.fn.DataTable.isDataTable('#settings-table')) {
    settings_table.destroy();
    $('#settings-table tbody').empty();
  }

  settings_table = $('#settings-table').DataTable({
    "ajax": {
      "url": "/api/v1/settings",
      "type": "GET",
      "dataSrc": function(response) {
        return normalizeSettingsResponse(response);
      }
    },
    "columns": [
      {
        "data": null,
        "render": function(data, type, row) {
          return `<input type="checkbox" class="row-check" value="${escapeHtml(row.key)}">`;
        }
      },
      {"data": "key"},
      {
        "data": "value",
        "render": function(data, type, row) {
          const safeValue = data === null || data === undefined ? '' : String(data);
          return `<input type="text" class="form-control" data-key="${escapeHtml(row.key)}" value="${escapeHtml(safeValue)}">`;
        }
      },
      {"data": "category"},
      {
        "data": null,
        "render": function(data, type, row) {
          const safeKey = JSON.stringify(row.key);
          return `<button onclick='updateSettingValue(${safeKey})' class="btn btn-primary">Save</button>
                  <button onclick='deleteSetting(${safeKey})' class="btn btn-danger">
                    <i class="ti ti-trash"></i>
                  </button>`;
        }
      }
    ],
    "order": [[1, 'asc']]
  });
}

function loadSettings() {
  if (settings_table) {
    settings_table.ajax.reload(null, false);
  } else {
    loadSettingsTable();
  }
}


function addNewSetting() {
  const key = document.getElementById('newSettingKey').value.trim();
  const value = document.getElementById('newSettingValue').value.trim();
  
  if (!key) {
    showMessage('Please enter a setting key', 'error');
    return;
  }
  
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(key)) {
    showMessage('Invalid key format. Key must start with a letter or underscore and contain only letters, numbers, and underscores.', 'error');
    return;
  }
  
  fetch('/api/v1/settings', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify({ key: key, value: value })
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showMessage('Error: ' + data.msg, 'error');
      return;
    }
    
    showMessage('Setting added successfully', 'success');
    document.getElementById('newSettingKey').value = '';
    document.getElementById('newSettingValue').value = '';
    loadSettings();
    reloadDsipRequired();
  })
  .catch(error => {
    showMessage('Error: ' + error.message, 'error');
  });
}

function updateSettingValue(key) {
  const inputElement = document.querySelector(`input[data-key="${key}"]`);
  if (!inputElement) return;
  
  const newValue = inputElement.value;
  
  fetch(`/api/v1/settings/${key}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify({ value: newValue })
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showMessage('Error: ' + data.msg, 'error');
      return;
    }
    
    showMessage('Setting updated successfully', 'success');
    loadSettings();
    reloadDsipRequired();
  })
  .catch(error => {
    showMessage('Error: ' + error.message, 'error');
  });
}

function deleteSetting(key) {
  if (!confirm(`Are you sure you want to delete the setting "${key}"?`)) {
    return;
  }
  
  fetch(`/api/v1/settings/${key}`, {
    method: 'DELETE',
    headers: {
      'Accept': 'application/json',
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showMessage('Error: ' + data.msg, 'error');
      return;
    }
    
    showMessage('Setting deleted successfully', 'success');
    loadSettings();
    reloadDsipRequired();
  })
  .catch(error => {
    showMessage('Error: ' + error.message, 'error');
  });
}

function showMessage(message, type) {
  const container = document.getElementById('message-bar');
  const alertDiv = document.createElement('div');
  alertDiv.className = `alert ${type}`;
  alertDiv.textContent = message;
  container.appendChild(alertDiv);
  container.style.display = 'block';
  container.hidden = false;

  // Auto-remove message after 5 seconds
  setTimeout(() => {
    alertDiv.remove();
  }, 5000);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}