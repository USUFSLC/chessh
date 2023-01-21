defmodule Chessh.SSH.Client.GameSelector do
  import Ecto.Query
  alias Chessh.Repo

  def paginate_ish_query(query, current_id, direction) do
    sorted_query =
      if direction == :desc,
        do: from(g in query, order_by: [desc: g.id]),
        else: from(g in query, order_by: [asc: g.id])

    results =
      if !is_nil(current_id) do
        if direction == :desc,
          do: from(g in sorted_query, where: g.id < ^current_id),
          else: from(g in sorted_query, where: g.id > ^current_id)
      else
        sorted_query
      end
      |> Repo.all()
      |> Repo.preload([:light_player, :dark_player])

    if direction == :desc, do: results, else: Enum.reverse(results)
  end
end
