import { CopyBlock, dracula } from "react-code-blocks";
import { Link } from "react-router-dom";

import { useAuthContext } from "../context/auth_context";

export const Home = () => {
  const { player, signedIn } = useAuthContext();

  if (signedIn) {
    const sshConfig = `Host chessh
  Hostname ${process.env.REACT_APP_SSH_SERVER}
  Port ${process.env.REACT_APP_SSH_PORT}
  User ${player?.username}
  PubkeyAuthentication yes`;
    return (
      <>
        <h2>Welcome, {player?.username}</h2>
        <hr />
        <h3>Getting Started</h3>
        <ol>
          <div>
            <li>
              Add a <Link to="/keys">public key</Link>, or{" "}
              <Link to="/password">set a password</Link>.
            </li>
          </div>
          <div>
            <li>
              Insert the following block in your{" "}
              <a href="https://linux.die.net/man/5/ssh_config">ssh config</a>:
            </li>

            <CopyBlock
              theme={dracula}
              text={sshConfig}
              showLineNumbers={true}
              wrapLines
              codeBlock
            />
          </div>

          <div>
            <li>Then, connect with:</li>
            <CopyBlock
              theme={dracula}
              text={"ssh -t chessh"}
              language={"shell"}
              showLineNumbers={false}
              codeBlock
            />
          </div>
          <div>
            <li>Finally, play chess!</li>
            <p>Ideally, keeping the following contols in mind:</p>
            <ul>
              <li>Ctrl + b / Escape to return to the main menu.</li>
              <li>Ctrl + c / Ctrl + d to exit at any point.</li>
              <li>Arrow keys to move around the board.</li>
              <li>
                Select a piece with "enter", and move it to a square by pressing
                "enter" again.
              </li>
            </ul>
          </div>
        </ol>
      </>
    );
  }

  return (
    <>
      <p>Looks like you're not signed in 👀. </p>
    </>
  );
};
