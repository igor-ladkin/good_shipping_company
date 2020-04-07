defmodule GSC.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {GSC.DeliveryManager, [name: GSC.DeliveryManager]},
      {Registry, [name: GSC.Registry.DeliverySession, keys: :unique]},
      {DynamicSupervisor, [name: GSC.Supervisor.DeliverySession, strategy: :one_for_one]}
    ]

    Supervisor.start_link(children, name: GSC.Supervisor, strategy: :one_for_one)
  end
end
