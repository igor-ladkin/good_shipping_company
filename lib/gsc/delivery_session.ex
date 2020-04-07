defmodule GSC.DeliverySession do
  alias GSC.{Delivery, DeliveryManager}
  use GenServer

  require Logger

  # Callbacks

  def child_spec(delivery) do
    %{
      id: {__MODULE__, delivery.id},
      start: {__MODULE__, :start_link, [delivery]},
      restart: :temporary
    }
  end

  def init(delivery) do
    {:ok, delivery}
  end

  def handle_call(:start_delivery, _from, delivery) do
    delivery = Delivery.start(delivery)
    Logger.info("Delivery #{delivery.id} was started at #{delivery.started_at}")

    {:reply, {:started, delivery.id}, delivery}
  end

  def handle_call(:finish_delivery, _from, delivery) do
    delivery = Delivery.finish(delivery)
    Logger.info("Delivery #{delivery.id} was finished at #{delivery.finished_at}")

    {:stop, :normal, {:finished, delivery.id}, nil}
  end

  def handle_call(:check_delivery, _from, delivery) do
    {:reply, delivery, delivery}
  end

  # API

  def start_link(delivery) do
    GenServer.start_link(
      __MODULE__,
      delivery,
      name: via(delivery.id)
    )
  end

  def dispatch_delivery(delivery) do
    DynamicSupervisor.start_child(
      GSC.Supervisor.DeliverySession,
      {__MODULE__, delivery}
    )

    Logger.info("Delivery #{delivery.id} was dispatched at #{Time.utc_now()}")

    delivery
  end

  def start_delivery(delivery_id) do
    delivery_id
    |> via()
    |> GenServer.call(:start_delivery)
  end

  def finish_delivery(delivery_id) do
    delivery_id
    |> via()
    |> GenServer.call(:finish_delivery)
  end

  def check_delivery(delivery_id) do
    delivery_id
    |> via()
    |> GenServer.call(:check_delivery)
  end

  def simulate(delivery_id), do: simulate(delivery_id, Enum.random(1_000..15_000))

  def simulate(delivery_id, duration) do
    start_delivery(delivery_id)

    Logger.info("It will take #{duration} milliseconds to finish delivery #{delivery_id}")
    Process.sleep(duration)

    finish_delivery(delivery_id)

    DeliveryManager.track(delivery_id)
  end

  # Helpers

  defp via(delivery_id) do
    {
      :via,
      Registry,
      {GSC.Registry.DeliverySession, delivery_id}
    }
  end
end
