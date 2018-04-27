# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule AntikytheraCore.TerminationManagerTest do
  use Croma.TestCase
  alias SolomonLib.Test.ProcessHelper
  alias SolomonLib.Test.GenServerHelper
  alias AntikytheraCore.Path, as: CorePath
  alias AntikytheraCore.ClusterHostsPoller

  defp mock_running_hosts(f) do
    :meck.new(ClusterHostsPoller, [:passthrough])
    :meck.expect(ClusterHostsPoller, :current_hosts, fn -> {:ok, %{}} end)
    f.()
    :meck.unload()
  end

  test "should activate RaftFleet on startup; deactivate RaftFleet on terminating and deactivate all AsyncJobBroker's" do
    zone = AntikytheraEal.ClusterConfiguration.zone_of_this_host()
    assert RaftFleet.active_nodes() == %{zone => [Node.self()]}
    TerminationManager.register_broker()

    mock_running_hosts(fn ->
      spawn_link(fn ->
        Enum.each(1..3, fn _ ->
          GenServerHelper.send_message_and_wait(TerminationManager, :check_host_status)
        end)
      end)
      ProcessHelper.monitor_wait(RaftFleet.Cluster)
      assert GenServerHelper.receive_cast_message() == :deactivate
    end)

    # discard all raft snapshot & log files and manually re-activate RaftFleet
    File.rm_rf!(CorePath.raft_persistence_dir_parent())
    :ok = RaftFleet.activate(zone)
    :timer.sleep(100)
    assert RaftFleet.active_nodes() == %{zone => [Node.self()]}
  end
end
