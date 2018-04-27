# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule SolomonLib.Controller.Response do
  @moduledoc """
  [DEPRECATED] Utility functions to put specific responses.
  """

  defdelegate redirect(conn, url, status \\ 302), to: SolomonLib.Conn
end
