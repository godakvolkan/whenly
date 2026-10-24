import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    status: Object,
    daily: Object,
    weekly: Object,
    busiestDay: Object,
    busiestHour: Object
  }

  async connect() {
    try {
      const chartModule = await import("chart.js")
      const Chart = chartModule.Chart || chartModule.default || window.Chart
      if (chartModule.registerables && typeof Chart.register === "function") {
        Chart.register(...chartModule.registerables)
      }
      this.Chart = Chart

      if (this.Chart) {
        if (this.Chart.defaults) {
          this.Chart.defaults.font.family = "'Plus Jakarta Sans', system-ui, sans-serif"
          this.Chart.defaults.color = "#64748B"
        }

        this.renderWeeklyChart()
        this.renderStatusChart()
        this.renderDailyChart()
        this.renderDayChart()
        this.renderHourChart()
      }
    } catch (err) {
      console.warn("Chart.js yüklenemedi veya grafik render edilirken hata:", err)
    }
  }

  renderWeeklyChart() {
    const ctx = this.element.querySelector("#weeklyChart")
    if (!ctx || !this.Chart) return
    this.Chart.getChart?.(ctx)?.destroy()

    const data = this.weeklyValue || {}
    new this.Chart(ctx, {
      type: "bar",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Haftalık Randevu",
          data: Object.values(data),
          backgroundColor: "rgba(79, 70, 229, 0.8)",
          borderRadius: 8,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (context) => ` ${context.parsed.y} Randevu`
            }
          }
        },
        scales: {
          y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: "#E2E8F0" } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  renderStatusChart() {
    const ctx = this.element.querySelector("#statusChart")
    if (!ctx || !this.Chart) return
    this.Chart.getChart?.(ctx)?.destroy()

    const data = this.statusValue || {}
    const labels = Object.keys(data)
    const values = Object.values(data)
    const colors = ["#059669", "#D97706", "#4F46E5", "#DC2626", "#6366F1", "#94A3B8", "#F59E0B"]

    new this.Chart(ctx, {
      type: "doughnut",
      data: {
        labels,
        datasets: [{ data: values, backgroundColor: colors, borderWidth: 0 }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "bottom", labels: { padding: 16, usePointStyle: true } }
        },
        cutout: "65%"
      }
    })
  }

  renderDailyChart() {
    const ctx = this.element.querySelector("#dailyChart")
    if (!ctx || !this.Chart) return
    this.Chart.getChart?.(ctx)?.destroy()

    const data = this.dailyValue || {}
    new this.Chart(ctx, {
      type: "bar",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Randevu",
          data: Object.values(data),
          backgroundColor: "rgba(79, 70, 229, 0.7)",
          borderRadius: 6,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: "#E2E8F0" } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  renderDayChart() {
    const ctx = this.element.querySelector("#dayChart")
    if (!ctx || !this.Chart) return
    this.Chart.getChart?.(ctx)?.destroy()

    const data = this.busiestDayValue || {}
    new this.Chart(ctx, {
      type: "bar",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Randevu",
          data: Object.values(data),
          backgroundColor: "rgba(5, 150, 105, 0.7)",
          borderRadius: 6,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: "#E2E8F0" } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  renderHourChart() {
    const ctx = this.element.querySelector("#hourChart")
    if (!ctx || !this.Chart) return
    this.Chart.getChart?.(ctx)?.destroy()

    const data = this.busiestHourValue || {}
    new this.Chart(ctx, {
      type: "line",
      data: {
        labels: Object.keys(data),
        datasets: [{
          label: "Randevu",
          data: Object.values(data),
          borderColor: "#4F46E5",
          backgroundColor: "rgba(79, 70, 229, 0.1)",
          fill: true,
          tension: 0.4,
          pointBackgroundColor: "#4F46E5",
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: "#E2E8F0" } },
          x: { grid: { display: false } }
        }
      }
    })
  }
}
