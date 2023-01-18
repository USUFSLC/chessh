import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";

import * as AsciinemaPlayer from "asciinema-player";
import "asciinema-player/dist/bundle/asciinema-player.css";

const demoProps = {
  theme: "tango",
  startAt: 12,
  autoPlay: true,
};

const demoCast = "/chessh.cast";
const demoCastElementId = "demo";

export const Demo = () => {
  const player = useRef(null);
  const [renderedPlayer, setRenderedPlayer] = useState(false);

  useEffect(() => {
    if (!renderedPlayer) {
      AsciinemaPlayer.create(
        demoCast,
        document.getElementById(demoCastElementId),
        demoProps
      );
      setRenderedPlayer(true);
    }
  }, [renderedPlayer, player]);

  return (
    <div className="demo-container">
      <h1>
        Welcome to <span style={{ color: "green" }}>> CheSSH!</span>
      </h1>
      <div className="flex-row-around">
        <p>
          CheSSH is a multiplayer, scalable, free, open source, and potentially
          passwordless game of Chess over the SSH protocol.
        </p>
        <a
          className="button gold"
          href="https://github.com/Simponic/chessh"
          target="_blank"
          rel="noreferrer"
        >
          🌟 Star 🌟
        </a>
      </div>
      <hr />
      <div ref={player} id={demoCastElementId} />
      <hr />
      <div className="flex-row-around">
        <h3>Would you like to play a game?</h3>
        <Link className="button" to="/home">
          Yes, Joshua ⇒
        </Link>
      </div>
    </div>
  );
};
