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
      fetch('/api/v1/stats')
        .then(response => response.json())
        .then(results => {
          updateMetrics(results);
          updateCharts(results);
        })
        .catch(error => console.error('Error fetching dashboard stats:', error));
    }

    // Update metric cards
    function updateMetrics(results) {
      document.getElementById('active-calls').textContent = results.data.active_calls || 0;
      document.getElementById('queued-messages').textContent = results.data.queued_messages || 0;
      document.getElementById('cps-value').textContent = (results.calls_per_second || 0).toFixed(1);
      document.getElementById('reg-failures').textContent = results.data.registration_failures || 0;

      document.getElementById('sip-status').textContent = results.data.sip_server_status || 'Online';
      document.getElementById('db-status').textContent = results.data.database_status || 'Connected';

      // Update endpoints
      if (results.data.top_endpoints && results.data.top_endpoints.length > 0) {
        const endpointsList = document.getElementById('endpoints-list');
        endpointsList.innerHTML = data.top_endpoints.map(ep =>
          `<li class="endpoint-item">
            <span class="endpoint-name">${ep.name}:</span>
            <a class="endpoint-calls" href="#">${ep.calls} Calls</a>
          </li>`
        ).join('');
      }

      // Update alerts
      if (results.data.alerts && results.data.alerts.length > 0) {
        const alertsContainer = document.getElementById('alerts-container');
        alertsContainer.innerHTML = data.alerts.map(alert => {
          const alertClass = alert.type === 'error' ? 'alert-error' : 'alert-warning';
          const icon = alert.type === 'error' ? '⚠' : '!';
          return `<div class="alert-item ${alertClass}">
            <span class="alert-icon">${icon}</span>
            <span class="alert-title">${alert.title}</span>
            <span class="alert-message">${alert.message}</span>
          </div>`;
        }).join('');
      }
    }

    // Update charts with data
    function updateCharts(data) {
      const defaultTimeLabels = ['11:00', '11:10', '11:20', '11:30', '11:40'];
      const defaultMessagesIncoming = [60, 80, 70, 90, 100];
      const defaultMessagesOutgoing = [40, 60, 50, 75, 85];
      const defaultCallsData = [40, 35, 45, 55, 50];
      const defaultCpsData = [2.5, 2.8, 3.0, 3.2, 3.5];

      const timeLabels = data.time_labels || defaultTimeLabels;
      const messagesIncoming = data.messages_incoming || defaultMessagesIncoming;
      const messagesOutgoing = data.messages_outgoing || defaultMessagesOutgoing;
      const activeCalls = data.active_calls || defaultCallsData;
      const cpsValues = data.cps_values || defaultCpsData;

      // Messages Over Time Chart
      const messagesCtx = document.getElementById('messagesChart').getContext('2d');
      if (messagesChart) messagesChart.destroy();
      messagesChart = new Chart(messagesCtx, {
        type: 'line',
        data: {
          labels: timeLabels,
          datasets: [
            {
              label: 'Incoming Messages',
              data: messagesIncoming,
              borderColor: '#ff9800',
              backgroundColor: 'rgba(255, 152, 0, 0.1)',
              fill: true,
              tension: 0.3,
              borderWidth: 2,
              pointRadius: 4,
              pointBackgroundColor: '#ff9800'
            },
            {
              label: 'Outgoing Messages',
              data: messagesOutgoing,
              borderColor: '#1976d2',
              backgroundColor: 'rgba(25, 118, 210, 0.1)',
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

      // Active Calls & CPS Chart
      const callsCtx = document.getElementById('callsChart').getContext('2d');
      if (callsChart) callsChart.destroy();
      callsChart = new Chart(callsCtx, {
        type: 'bar',
        data: {
          labels: timeLabels,
          datasets: [
            {
              label: 'Calls Per Second',
              data: activeCalls,
              backgroundColor: '#ff9800',
              yAxisID: 'y'
            },
            {
              type: 'line',
              label: 'CPS',
              data: cpsValues,
              borderColor: '#1976d2',
              backgroundColor: 'transparent',
              borderWidth: 2,
              yAxisID: 'y1',
              pointRadius: 4,
              pointBackgroundColor: '#1976d2',
              tension: 0.3
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
              type: 'linear',
              display: true,
              position: 'left',
              title: {
                display: false
              },
              beginAtZero: true
            },
            y1: {
              type: 'linear',
              display: true,
              position: 'right',
              title: {
                display: false
              },
              beginAtZero: true,
              grid: {
                drawOnChartArea: false
              }
            }
          }
        }
      });
    }

    // Load data on page load
    document.addEventListener('DOMContentLoaded', function() {
      fetchDashboardStats();
      
      // Refresh stats every 30 seconds
      setInterval(fetchDashboardStats, 30000);
    });

})(window, document);
