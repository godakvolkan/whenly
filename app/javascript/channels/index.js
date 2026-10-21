import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

consumer.subscriptions.create("BookingsChannel", {
  received(data) {
    if (data.type === "booking_update") {
      const event = new CustomEvent("booking:updated", { detail: data })
      window.dispatchEvent(event)
    }
  }
})

export default consumer
