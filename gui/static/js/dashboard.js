;(function(window, document) {
  'use strict';

  function getKamailioStats(elem) {
    $.ajax({
      type: "GET",
      url: "/api/v1/kamailio/stats",
      dataType: "json",
      success: function(response, text_status, xhr) {
        var stats = response.data[0];
        // set defaults if bad response
        stats.current = stats.current !== undefined ? stats.current : 0;
        stats.waiting = stats.waiting !== undefined ? stats.waiting : 0;
        stats.total = stats.total !== undefined ? stats.total : 0;
        $("#dashboard_current_calls").text(stats.current);
        $("#dashboard_calls_inqueue").text(stats.waiting);
        $("#dashboard_total_calls_processed").text(stats.total);
      }
    });
  }

    // Initialize charts
    let messagesChart = null;
    let callsChart = null;

    // Fetch stats data from endpoint
    function fetchDashboardStats() {

      // Remove old alerts
      var alertsContainer = document.getElementById('alerts-container');
      while (alertsContainer.firstChild) {  
        alertsContainer.removeChild(alertsContainer.firstChild);
      }


      fetch('/api/v1/stats')
        .then(response => response.json())
        .then(results => {
          updateMetrics(results);
          updateCharts(results.data.charts);
          updateSystemInfo(results.data.components);
          updateAlerts(results.data.alerts);
          updateTopEndPointGroups(results.data.topEndpointGroups);
        })
        .catch(error => console.error('Error fetching dashboard stats:', error));
    }

    // Update metric cards
    function updateMetrics(results) {
      document.getElementById('active-calls').textContent = results.data.active_calls || 0;
      document.getElementById('queued-messages').textContent = results.data.queued_messages || 0;
      document.getElementById('cps-value').textContent = (results.calls_per_second || 0).toFixed(1);
      document.getElementById('reg-failures').textContent = results.data.registration_failures || 0;

    }

    // Update charts with data
    function updateCharts(data) {
      const defaultTimeLabels = ['11:00', '11:10', '11:20', '11:30', '11:40'];
      const defaultMessagesIncoming = [60, 80, 70, 90, 100];
      const defaultMessagesOutgoing = [40, 60, 50, 75, 85];
      const defaultCallsData = [40, 35, 45, 55, 50];
    
      const timeLabels = data['messagesOverTime'].timeLabels || defaultTimeLabels;
      const endpointGroupMessages = data['messagesOverTime'].messages || defaultMessagesIncoming;
     
      const carrierGroupTimeLabels = data['carrierGroupMessages'].timeLabels || defaultTimeLabels;
      const carrierGroupMessages = data['carrierGroupMessages'].messages || defaultMessagesIncoming;
      

      // Endpoint Group Messages Chart
      const messagesCtx = document.getElementById('messagesChart').getContext('2d');
      if (messagesChart) messagesChart.destroy();
      messagesChart = new Chart(messagesCtx, {
        type: 'line',
        data: {
          labels: timeLabels,
          datasets: [
            {
              label: 'Endpoint Group Messages',
              data: endpointGroupMessages,
              borderColor: '#ff9800',
              backgroundColor: 'rgba(255, 152, 0, 0.1)',
              fill: true,
              tension: 0.3,
              borderWidth: 2,
              pointRadius: 4,
              pointBackgroundColor: '#ff9800'
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                maxTicksLimit: 4
              }
            }
          }
        }
      });

      // Carrier Group Messages Chart
      const callsCtx = document.getElementById('callsChart').getContext('2d');
      if (callsChart) callsChart.destroy();
      callsChart = new Chart(callsCtx, {
        type: 'line',
        data: {
          labels:  carrierGroupTimeLabels,
          datasets: [
            {
              label: 'Carrier Group Messages',
              data: carrierGroupMessages,
              backgroundColor: '#1976d2',
              fill: true,
              tension: 0.3,
              borderWidth: 2,
              pointRadius: 4,
              pointBackgroundColor: '#1976d2'
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                maxTicksLimit: 4
              }
            }
          }
        }
      });
    }

    function updateSystemInfo(components) {
      const systemInfoContainer = document.getElementById('systems-container');
      systemInfoContainer.innerHTML = components.map(component => `
        <div class="status-item">
          <div class="system-info-header">
          ${component.status.toLowerCase() === 'running' ? '<span class="status-online">&#10003</span>' : '<span class="status-offline">&#215;</span>'}
            <span class="system-info-name">${component.name}:</span>
            ${component.name === 'Database' ? `<span class="system-info-type">${component.type}</span>` : ''}
            <span class="system-info-version">${component.version}</span>
            <span class="system-info-location">(${component.location})</span>
          </div>
        </div>
      `).join('');
    } 

    function updateAlerts(alerts) {
      
      var alertsContainer = document.getElementById('alerts-container');
      if (alerts.length === 0) {
        alertsContainer.innerHTML = 'No Alerts';
        return;
      } 
      alerts.forEach(function(alert) {
        const newDiv = document.createElement('div');
        const alertClass = alert.type === 'error' ? 'alert-error' : 'alert-warning';
        const icon = alert.type === 'error' ? '⚠' : '!';
        newDiv.classList.add('alert-item', alertClass);
        newDiv.innerHTML = `
          <span class="alert-icon">${icon}</span>
          <span class="alert-title">${alert.title}</span>
          <span class="alert-message">${alert.message}</span>
        `;
        alertsContainer.appendChild(newDiv);  
      });
    }

    function updateTopEndPointGroups(topEndpointGroups) {
      // Update endpoints
      if (topEndpointGroups.endpointgroups && topEndpointGroups.endpointgroups.length > 0) {
        const endpointsList = document.getElementById('endpoints-list');
        endpointsList.innerHTML = topEndpointGroups.endpointgroups.map(ep => `
          <li class="endpoint-item">
            <span class="endpoint-name">${ep.name}:</span>
            <a class="endpoint-calls" href="#">${ep.calls} Calls</a>
          </li>`
        ).join('');
      }
    }
      

    // Load data on page load
    document.addEventListener('DOMContentLoaded', function() {
      fetchDashboardStats();
      
      // Refresh stats every 30 seconds
      setInterval(fetchDashboardStats, 30000);
    });

})(window, document);
