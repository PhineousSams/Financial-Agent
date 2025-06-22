// assets/js/hooks.js
let Hooks = {} 

// Chart Hook - API Usage by Integrator
Hooks.Chart = {
  mounted() {
    // Bar Chart Options for User Data
    let barOptions = {
      series: [{
        name: 'Sarah Mwanza',
        data: [125, 132, 145, 138, 152, 148, 165, 159, 172]
      }, {
        name: 'James Banda',
        data: [89, 95, 102, 98, 108, 112, 118, 124, 130]
      }, {
        name: 'Mary Phiri',
        data: [45, 52, 58, 61, 67, 72, 78, 84, 90]
      }, {
        name: 'David Tembo',
        data: [0, 0, 0, 0, 0, 0, 15, 28, 42]
      }],
      chart: {
        type: 'bar',
        height: 350,
        toolbar: {
          show: false
        }
      },
      plotOptions: {
        bar: {
          horizontal: false,
          columnWidth: '55%',
          endingShape: 'rounded',
          borderRadius: 4
        }
      },
      dataLabels: {
        enabled: false
      },
      stroke: {
        show: true,
        width: 2,
        colors: ['transparent']
      },
      xaxis: {
        categories: ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']
      },
      yaxis: {
        title: {
          text: 'Active Users'
        }
      },
      fill: {
        opacity: 1,
        colors: ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd']
      },
      tooltip: {
        y: {
          formatter: function (val) {
            return val + " users"
          }
        }
      }
    };

    // Initialize and render Bar Chart
    let barChart = new ApexCharts(this.el, barOptions);
    barChart.render();
  }
};

// Response Time Chart Hook
Hooks.ResponseTime = {
  mounted() {
    let options = {
      series: [{
        name: 'Sarah Mwanza',
        data: [120, 115, 130, 125, 110, 105, 100, 95, 90]
      }, {
        name: 'James Banda',
        data: [90, 85, 95, 100, 90, 85, 80, 75, 70]
      }, {
        name: 'Mary Phiri',
        data: [150, 145, 155, 160, 150, 145, 140, 135, 130]
      }, {
        name: 'David Tembo',
        data: [0, 0, 0, 0, 0, 0, 110, 105, 100]
      }],
      chart: {
        height: 350,
        type: 'line',
        zoom: {
          enabled: false
        },
        toolbar: {
          show: false
        }
      },
      dataLabels: {
        enabled: false
      },
      stroke: {
        curve: 'smooth',
        width: 3,
        colors: ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd']
      },
      grid: {
        row: {
          colors: ['#f3f4f6', 'transparent'],
          opacity: 0.5
        }
      },
      xaxis: {
        categories: ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']
      },
      yaxis: {
        title: {
          text: 'Response Time (ms)'
        }
      },
      tooltip: {
        y: {
          formatter: function(val) {
            return val + " ms";
          }
        }
      }
    };

    let chart = new ApexCharts(this.el, options);
    chart.render();
  }
};

// Pie Chart Hook - User Distribution
Hooks.Pie = {
  mounted() {
    // Donut Chart Options
    let pieOptions = {
      series: [42, 28, 18, 12],
      chart: {
        type: 'pie',
        height: 350,
        toolbar: {
          show: false
        }
      },
      labels: ['Sarah Mwanza', 'James Banda', 'Mary Phiri', 'David Tembo'],
      colors: ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd'],
      dataLabels: {
        enabled: true
      },
      responsive: [{
        breakpoint: 480,
        options: {
          chart: {
            width: 200
          },
          legend: {
            position: 'bottom'
          }
        }
      }],
      legend: {
        position: 'right',
        offsetY: 0,
        height: 250
      }
    };

    // Initialize and render Donut Chart
    let pieChart = new ApexCharts(this.el, pieOptions);
    pieChart.render();
  }
};

// Error Rate Chart Hook
Hooks.ErrorRate = {
  mounted() {
    let options = {
      series: [{
        name: 'Error Rate (%)',
        data: [2.1, 1.8, 3.5, 2.8]
      }],
      chart: {
        height: 350,
        type: 'bar',
        toolbar: {
          show: false
        }
      },
      plotOptions: {
        bar: {
          borderRadius: 4,
          horizontal: true,
          distributed: true,
          dataLabels: {
            position: 'top'
          }
        }
      },
      colors: ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd'],
      dataLabels: {
        enabled: true,
        formatter: function (val) {
          return val + "%";
        },
        offsetX: 30
      },
      xaxis: {
        categories: ['Sarah Mwanza', 'James Banda', 'Mary Phiri', 'David Tembo'],
        labels: {
          formatter: function (val) {
            return val + "%";
          }
        }
      },
      yaxis: {
        title: {
          text: 'User'
        }
      }
    };

    let chart = new ApexCharts(this.el, options);
    chart.render();
  }
};


Hooks.VideoLoader = {
  mounted() {
    // Show loader for 3 seconds
    setTimeout(() => {
      document.getElementById('video-loader').classList.add('mobile'); // Add hidden class to hide loader
      document.getElementById('video-frame').style.display = 'block'; // Show video
    }, 3000); // 3000 milliseconds = 3 seconds
  }
};
 

export default Hooks;
