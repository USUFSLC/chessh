import { useEffect } from "react";
import { Link } from "react-router-dom";

import { useAuthContext } from "../context/auth_context";

export const AuthSuccessful = () => {
  const { player, setPlayer, signedIn, setSignedIn, setSessionOver } =
    useAuthContext();

  useEffect(() => {
    fetch("/api/player/token/me", {
      credentials: "same-origin",
    })
      .then((r) => r.json())
      .then(({ player, expiration }) => {
        setSignedIn(!!player);
        setPlayer(player);
        setSessionOver(expiration);
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (signedIn) {
    return (
      <>
        <h1>Authentication Successful</h1>
        <div>
          <span>Hello there, {player?.username || ""}! </span>
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
