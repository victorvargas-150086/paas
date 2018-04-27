# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule AntikytheraCore.GearConfigPoller do
  @moduledoc """
  Periodically polls changes in gear configs.

  Gear configs are persisted in a shared data storage (e.g. NFS) and are cached in ETS in each erlang node.
  Note that gear configs are loaded (cached into ETS) at each step of

  - `AntikytheraCore.start/2`: all existing gear configs are loaded
  - each gear's `start/2`: the gear's gear config is loaded

  Thus this GenServer's responsibility is just to keep up with changes in the shared data storage.

  Depends on `AntikytheraCore.GearManager` (when applying changes in gear configs results in update of cowboy routing).
  """

  use GenServer
  alias AntikytheraCore.Config.Gear, as: GearConfig

  @interval 60_000

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @impl true
  def init(:ok) do
    {:ok, %{last_checked_at: 0}, @interval}
  end

  @impl true
  def handle_info(:timeout, state) do
    checked_at = System.system_time(:seconds)
    GearConfig.load_all(state[:last_checked_at])
    {:noreply, %{state | last_checked_at: checked_at}, @interval}
  end
end
