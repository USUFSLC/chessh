import { useEffect, useCallback } from "react";
import { useAuthContext } from "../context/auth_context";

export const AuthSuccessful = () => {
  const { username, signedIn, setSignedIn, setUserId, setUsername } =
    useAuthContext();

  const fetchMyself = useCallback(
    () =>
      fetch("/api/player/me", {
        credentials: "same-origin",
      })
        .then((r) => r.json())
        .then((player) => {
          setSignedIn(!!player);
          setUserId(player.id);
          setUsername(player.username);
        }),
    [setSignedIn, setUserId, setUsername]
  );

  useEffect(() => {
    fetchMyself();
  }, [fetchMyself]);

  return (
    <>
      <h1>Successful Auth</h1>
      {signedIn ? <p>Hello there, {username || ""}</p> : <p>Loading...</p>}
    </>
  );
};
