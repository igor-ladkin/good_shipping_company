defmodule GSC.DeliveryManager do
  alias GSC.{Delivery, DeliverySession}
  use GenServer

  require Logger

  # Callbacks

  def init(infinite \\ false) do
    {:ok,
     %{
       ongoing: [],
       scheduled: Stream.repeatedly(&Delivery.new/0),
       infinite: infinite
     }}
  end

  def handle_call(:peek, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:toggle, _from, state) do
    {:reply, :ok, %{state | infinite: !state.infinite}}
  end

  def handle_call(:dispatch_batch, _from, %{ongoing: ongoing} = state)
      when length(ongoing) != 0 do
    {:reply, {:error, :batch_already_dispatched}, state}
  end

  def handle_call(:dispatch_batch, _from, state) do
    delivery_ids = dispatch_deliveries(state.scheduled)
    {:reply, {:ok, delivery_ids}, %{state | ongoing: delivery_ids}}
  end

  def handle_call(:simulate, _from, state) do
    Enum.each(state.ongoing, &start_simulation/1)
    {:reply, :ok, state}
  end

  def handle_call({:track, delivery_id}, _from, state) do
    ongoing = List.delete(state.ongoing, delivery_id)

    if Enum.empty?(ongoing) && state.infinite do
      self() |> IO.inspect()
      Process.send_after(self(), :dispatch_batch, 500)
      Process.send_after(self(), :simulate, 1_000)
    end

    {:reply, :ok, %{state | ongoing: ongoing}}
  end

  def handle_info(:dispatch_batch, state) do
    delivery_ids = dispatch_deliveries(state.scheduled)
    {:noreply, %{state | ongoing: delivery_ids}}
  end

  def handle_info(:simulate, state) do
    Enum.each(state.ongoing, &start_simulation/1)
    {:noreply, state}
  end

  # API

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, false, options)
  end

  def peek() do
    GenServer.call(__MODULE__, :peek)
  end

  def toggle() do
    GenServer.call(__MODULE__, :toggle)
  end

  def track(delivery_id) do
    GenServer.call(__MODULE__, {:track, delivery_id})
  end

  def dispatch_batch() do
    GenServer.call(__MODULE__, :dispatch_batch)
  end

  def simulate() do
    dispatch_batch()
    GenServer.call(__MODULE__, :simulate)
  end

  # Helpers

  defp dispatch_deliveries(generator) do
    Logger.warn("Dispatching new deliveries")

    generator
    |> Enum.take(5)
    |> Enum.map(&DeliverySession.dispatch_delivery/1)
    |> Enum.map(& &1.id)
  end

  defp start_simulation(delivery_id) do
    Task.start(fn -> DeliverySession.simulate(delivery_id) end)
  end
end
