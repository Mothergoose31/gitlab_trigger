defmodule CreateHelm.SystemBehaviour do
  @callback cmd(binary(), [binary()], Keyword.t()) :: {binary(), non_neg_integer()}
end
