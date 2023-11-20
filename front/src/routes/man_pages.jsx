import { Link } from "react-router-dom";

const botMoveRequestSchema = `GameUpdate {
  bot_id: number;
  bot_name: string;
  game_id: number;
  fen: string;
  turn: string;
  bot_turn: boolean;
  last_move: string;
  status: string;
}`;

const botMoveResponseSchema = `BotMoveResponse {
  attempted_message: string;
}`;

export const ManPages = () => {
  return (
    <div>
      <div className="man-page-title">
        <div>CHESSH(1)</div>
        <div>User Help</div>
        <div>CHESSH(1)</div>
      </div>
      <br />
      <div>
        <div>
          <b>NAME</b>
        </div>
        <div>
          <ul>
            <li>chessh - multiplayer chess over ssh</li>
          </ul>
        </div>
      </div>

      <div>
        <div>
          <b>SYNOPSIS</b>
        </div>
        <div>
          <ul>
            <li>
              ssh <b>chessh</b>
            </li>
          </ul>
        </div>
      </div>

      <div>
        <div>
          <b>DESCRIPTION</b>
        </div>
        <div>
          <div>
            CheSSH uses the SSH protocol to send sequences of ANSI codes &
            plaintext to render a chess board in your shell, and listen to I/O
            by abusing the hell out of the{" "}
            <a href="https://www.erlang.org/doc/man/ssh.html">
              Erlang SSH Module
            </a>
            .
          </div>
        </div>
      </div>
      <br />
      <div>
        <div>
          <b>INTERACTION</b>
        </div>
        <div>
          <ul>
            <li>Ctrl + b / Escape to return to the main menu.</li>
            <li>Ctrl + c / Ctrl + d to exit CheSSH at any point.</li>
            <li>
              Arrow keys / vim (hjkl) keybinds to move around the board and
              menus.
            </li>
            <li>Select menu options with "enter".</li>
            <li>
              Select a game piece "enter", and move it to a square by pressing
              "enter" again.
            </li>
            <li>
              In the "Previous Games" viewer, use h/l or left/right to view the
              previous/next move.
            </li>
            <li>In a game board use "f" to flip the board.</li>
            <li>
              In the "Previous Games" viewer, use "m" to show the game's move
              history in UCI notation (which you may convert to PGN{" "}
              <a
                href="https://www.dcode.fr/uci-chess-notation"
                target="_blank"
                rel="noreferrer"
              >
                here
              </a>
              ).
            </li>
          </ul>
        </div>
      </div>
      <div>
        <div>
          <b>BOTS & WEBHOOKS</b>
        </div>
        <div>
          <ul>
            <li>
              Goto <Link to="/bots">/bots</Link> and create a bot, taking note
              of the new bot's token (keep this private!).
            </li>
            <li>
              Highly recommend{" "}
              <a href="https://ngrok.io" target="_blank" rel="noreferrer">
                ngrok
              </a>{" "}
              for testing.
            </li>
            <li>
              A "public" bot can be seen and played against by any player.
            </li>
            <li>
              A "private" bot can be seen and played against by the player which
              created it.
            </li>
            <li>
              A bot's "webhook" is the route that CheSSH will POST a JSON
              message to upon an update in a game it is playing. Upon a move, it
              will be immediately POST'd to with a single GameUpdate object, but
              when using the "redrive" feature (mostly for testing), an array of
              GameUpdates that correspond to games in which it is still the bot's turn:
              <pre>{botMoveRequestSchema}</pre>
            </li>
            <li>
              After receiving the update, the bot must "respond" with its
              attempted move, with the plain token (no "Bearer" prefix) in its
              "Authorization" header, and a body of (given "attempted_move" is
              the from space appended to the destination space i.e. "e2e4"):
              <pre>{botMoveResponseSchema}</pre>
            </li>
            <li>
              <a
                href="https://github.com/Simponic/chessh_bot/blob/3748df9a58ff92b71980eda613d4ffe6aa8bda91/src/api/index.ts#L18-L55"
                target="_blank"
                rel="noreferrer"
              >
                Here
              </a>
              is an example of how this logic should play out for a simple bot.
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};
