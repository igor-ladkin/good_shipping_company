defmodule GSC.Delivery do
  defstruct [:id, :state, :started_at, :finished_at]

  def new() do
    %__MODULE__{
      id: UUID.uuid4(),
      state: "pending"
    }
  end

  def start(delivery) do
    %{delivery | state: "started", started_at: Time.utc_now()}
  end

  def finish(delivery) do
    %{delivery | state: "finished", finished_at: Time.utc_now()}
  end
end
