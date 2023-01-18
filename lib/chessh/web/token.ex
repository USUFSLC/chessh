defmodule Chessh.Web.Token do
  use Joken.Config

  def token_config, do: default_claims(default_exp: 12 * 60 * 60)
end
