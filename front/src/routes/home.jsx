import { CopyBlock, dracula } from "react-code-blocks";
import { Link } from "react-router-dom";

import { useAuthContext } from "../context/auth_context";

const generateSSHConfig = (username) => `Host chessh
  Hostname ${process.env.REACT_APP_SSH_SERVER}
  Port ${process.env.REACT_APP_SSH_PORT}
  User ${username.includes(" ") ? '"' + username + '"' : username}"
  PubkeyAuthentication yes
`;

export const Home = () => {
  const { player, signedIn } = useAuthContext();

  if (signedIn) {
    const sshConfig = generateSSHConfig(player?.username);

    return (
      <>
        <h2>Welcome, {player?.username}</h2>
        <hr />
        <h3>Getting Started</h3>
        <ol>
          <div>
            <li>
              Consider joining the{" "}
              <a href={process.env.REACT_APP_DISCORD_INVITE}>CheSSH Discord</a>{" "}
              to receive notifications when other players are looking for
              opponents, or when it is your move in a game.
            </li>
          </div>
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
              text={"ssh chessh"}
              language={"shell"}
              showLineNumbers={false}
              codeBlock
            />
          </div>
          <div>
            <li>
              Finally, check out the short <a href="/man-pages">man pages</a> .
            </li>
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
