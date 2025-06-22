// assets/js/hooks.js
let Hooks = {} 

// Chart Hook - API Usage by Integrator
Hooks.Chart = {
  mounted() {
    // Bar Chart Options
    let barOptions = {
      series: [{
        name: 'ZRA',
        data: [1850, 1920, 2100, 2050, 2200, 2150, 2300, 2250, 2400]
      }, {
        name: 'NAPSA',
        data: [1200, 1300, 1450, 1400, 1500, 1550, 1600, 1650, 1700]
      }, {
        name: 'WCFCB',
        data: [800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200]
      }, {
        name: 'NHIMA',
        data: [0, 0, 0, 0, 0, 0, 350, 450, 550]
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
          text: 'API Calls'
        }
      },
      fill: {
        opacity: 1,
        colors: ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd']
      },
      tooltip: {
        y: {
          formatter: function (val) {
            return val + " calls"
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
        name: 'ZRA',
        data: [120, 115, 130, 125, 110, 105, 100, 95, 90]
      }, {
        name: 'NAPSA',
        data: [90, 85, 95, 100, 90, 85, 80, 75, 70]
      }, {
        name: 'WCFCB',
        data: [150, 145, 155, 160, 150, 145, 140, 135, 130]
      }, {
        name: 'NHIMA',
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

// Pie Chart Hook - Transaction Distribution
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
      labels: ['ZRA', 'NAPSA', 'WCFCB', 'NHIMA'],
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
        categories: ['ZRA', 'NAPSA', 'WCFCB', 'NHIMA'],
        labels: {
          formatter: function (val) {
            return val + "%";
          }
        }
      },
      yaxis: {
        title: {
          text: 'Integrator'
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
