import { useEffect, useCallback } from "react";
import { Link } from "react-router-dom";

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

  if (signedIn) {
    return (
      <>
        <h1>Authentication Successful</h1>
        <div>
          <span>Hello there, {username || ""}! </span>
          <Link to="/home" className="button">
            Go Home{" "}
          </Link>
        </div>
      </>
    );
  }
  return (
    <>
      <p>Loading...</p>
    </>
  );
};
