defmodule Chessh.Schema.KeyTest do
  use Chessh.RepoCase
  use ExUnit.Case
  alias Chessh.Key

  @valid_attrs %{
    name: "Logan's Key",
    key:
      {{{:ECPoint,
         <<159, 246, 44, 226, 70, 24, 71, 127, 118, 17, 96, 71, 18, 121, 48, 203, 244, 140, 156,
           56, 179, 138, 64, 242, 169, 140, 109, 156, 174, 148, 222, 56>>},
        {:namedCurve, {1, 3, 101, 112}}}, [comment: 'logan@yagami']}
  }
  @valid_key_attrs %{
    name: "asdf key",
    key:
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC7Mpf2QIL32MmKxcrXAoZM3l7/hBy+8d+WqTRMun+tC/XYNiXSIDuZv01an3D1d22fmSpZiprFQzjB4yEz23qw= logan@yagami"
  }
  @invalid_key_attrs %{
    name: "An Invalid Key",
    key: "AAAAC3NzaC1lZDI1NTE5AAAAIJ/2LOJGGEd/dhFgRxJ5MMv0jJw4s4pA8qmMbZyulN44"
  }
  @dsa_key_attrs %{
    name: "A DSA Key",
    key:
      "ssh-dss AAAAB3NzaC1kc3MAAACBAKkpMO6EbCb0BdA9m5ZJ0fGtpqJRXhyC7i4WWAdqFXxDPL0wakOmn2Vu3e4Z7UUwjSNB4jHQFzcrFKLAuXSCCMX5/nXTR5kFF3D7eSb8FApplh0+BKJn1B04A3atEqXrne6oDzl+eGbVTBL6rftFK90mi0FOHyYmT88gsbBEKgSHAAAAFQDqHCZC7aORvYqF8v9ONVOXAkUaTQAAAIAx3XEupb+JdXNak1TExQ1568M7CFj5GqBlSuKnBmEq6g24WIu7v1SQ2l3+YpOQv30+7GczpF1paPHnitOrDcMuwWM1HqbHkc6UPIjIhoaVeogOKIYw2gVMIQImdgS6ky3HADVrmOPvjakPIoCyk70zBWuwc82QC4Bc6yd58Uu1GQAAAIEAgdYvKFo7y6zq/PGVfnEfRtxstE2HxdxNe7n/FEHuRfWYEhNkoEqbVGEFg9OsAOXML8/6C7iEXXgqO8BT6lEJg4TbHZVPTfqCVwxDFrjSJ3aDm/22IjChkX9QTTDzJquA13iTNWlY7Z5yrxVhD+Pyjz3kXL1GvaphtCVp+K5P+GU="
  }
  @empty_attrs %{}

  test "changeset with valid attributes" do
    IO.puts(inspect(Key.changeset(%Key{}, @valid_attrs)))
    assert Key.changeset(%Key{}, @valid_attrs).valid?
    assert Key.changeset(%Key{}, @valid_key_attrs).valid?
  end

  test "changeset with invalid attributes" do
    refute Key.changeset(%Key{}, @empty_attrs).valid?
    refute Key.changeset(%Key{}, @invalid_key_attrs).valid?
    refute Key.changeset(%Key{}, @dsa_key_attrs).valid?
  end
end
