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
            <li>Arrow keys / hjkl keybinds to move around the board.</li>
            <li>
              Select a piece with "enter", and move it to a square by pressing
              "enter" again.
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};
