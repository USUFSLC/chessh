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
        </ol>
      </>
    );
  }

  return (
    <div>
      <h1>CheSSH</h1>
      <p>Hello!</p>
      <p>Looks like you're not signed in 👀. </p>
      <p>Please link your GitHub account above!</p>
    </div>
  );
};
