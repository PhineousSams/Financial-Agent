// assets/js/hooks.js
let Hooks = {}

import { jsPDF } from "jspdf";
import "jspdf-autotable";

const doc = new jsPDF();

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

Hooks.GeneratePDF = {
  mounted() {
    this.handleEvent("pdf_data", ({ applicant, applicant_id, quiz_id }) => {
      this.downloadFile(applicant, applicant_id, quiz_id);
    });
  },
  
  downloadFile(applicant, applicant_id, quiz_id) {
    // Prepare the data for the PDF generation
    const applicantName = `${applicant.applicant}`;
    const quizTitle = applicant.quiz;
    const score = applicant.score;
    const dateIssued = new Date(applicant.inserted_at).toLocaleDateString();


    const generatePDFContent = (logo = null) => {
      // Set page size to landscape
      const doc = new jsPDF({
        orientation: 'landscape',
        unit: 'mm',
        format: 'a4'
      });
    
      // Define colors
      const darkGreen = '#006400';
      const lightGreen = '#90EE90';
      const amber = '#FFBF00';
    
      // Add background design
      doc.setFillColor(lightGreen);
      doc.rect(0, 0, 297, 210, 'F');  // Fill entire page
      doc.setFillColor(darkGreen);
      doc.rect(10, 10, 277, 190, 'F'); // Dark green border
      doc.setFillColor(255, 255, 255);
      doc.rect(15, 15, 267, 180, 'F'); // White content area
    
      // Add geometric shapes
      doc.setFillColor(amber);
      doc.triangle(0, 0, 40, 0, 0, 60, 'F');
      doc.triangle(297, 210, 257, 210, 297, 150, 'F');
    
      // Set title
      doc.setFont('Helvetica', 'bold');
      doc.setFontSize(30);
      doc.setTextColor(darkGreen);
      doc.text('CERTIFICATE OF COMPLETION', 148.5, 40, { align: 'center' });
  
    
      // Add certificate details
      doc.setFontSize(12);
      doc.setTextColor(0);
      doc.text('THIS CERTIFICATE IS PROUDLY PRESENTED TO', 148.5, 80, { align: 'center' });
    
      doc.setFontSize(30);
      doc.setTextColor(darkGreen);
      doc.text(applicantName, 148.5, 100, { align: 'center' });
    
      doc.setFontSize(12);
      doc.setTextColor(0);
      doc.text(`FOR SUCCESSFULLY COMPLETING THE COURSE:`, 148.5, 120, { align: 'center' });
      
      doc.setFontSize(20);
      doc.setTextColor(darkGreen);
      doc.text(quizTitle, 148.5, 135, { align: 'center' });
    
      doc.setFontSize(14);
      doc.setTextColor(amber);
      doc.text(`Score: ${score}%`, 148.5, 155, { align: 'center' });
    
      // Add "Best Award" circle
      doc.setFillColor(darkGreen);
      doc.circle(240, 160, 15, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(8);
      doc.text('BEST', 240, 157, { align: 'center' });
      doc.text('AWARD', 240, 163, { align: 'center' });
    
      // Add signatures
      doc.setDrawColor(0);
      doc.setLineWidth(0.5);
      doc.line(70, 180, 130, 180);
      doc.line(167, 180, 227, 180);
    
      doc.setFontSize(10);
      doc.setTextColor(0);
      doc.text('Director', 100, 185, { align: 'center' });
      doc.text('Manager', 197, 185, { align: 'center' });
    
      // Add date
      doc.text(`Date Issued: ${dateIssued}`, 148.5, 195, { align: 'center' });
    
      // Add logo if available
      if (logo) {
        doc.addImage(logo, 'PNG', 10, 10, 30, 30);
      }
    
      // Save the PDF
      doc.save('CEEC_Quiz_Certificate.pdf');
    
      // Send an event back to LiveView after file download
      this.pushEvent("file_downloaded", { message: "File has been downloaded successfully" });
    };

    // Try to load the image, but generate PDF even if it fails
    this.loadImage('D:/financial_agent/priv/static/images/ceec-logo-white.png')
      .then((logo) => {
        generatePDFContent(logo);
      })
      .catch(err => {
        console.error('Error loading image:', err);
        // Generate PDF without the logo
        generatePDFContent();
        // Send a warning event back to LiveView
        this.pushEvent("file_download_warning", { 
          error: "..!",
          applicant_id: applicant_id,
          quiz_id: quiz_id
        });
      });
  },

  async loadImage(url) {
    const response = await fetch(url);
    const blob = await response.blob();
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result);
      reader.readAsDataURL(blob);
    });
  }
};

export default Hooks;
