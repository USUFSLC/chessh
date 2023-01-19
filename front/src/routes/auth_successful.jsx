import { useEffect, useCallback } from "react";
import { Link } from "react-router-dom";

import {
  useAuthContext,
  DEFAULT_EXPIRY_TIME_MS,
} from "../context/auth_context";

export const AuthSuccessful = () => {
  const {
    username,
    userId,
    sessionOver,
    signedIn,
    setSignedIn,
    setUserId,
    setUsername,
    setSessionOver,
  } = useAuthContext();

  useEffect(() => {
    fetch("/api/player/me", {
      credentials: "same-origin",
    })
      .then((r) => r.json())
      .then((player) => {
        setSignedIn(!!player);
        setUserId(player.id);
        setUsername(player.username);
      });
  }, []);

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
