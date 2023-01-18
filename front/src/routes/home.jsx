import { CopyBlock, dracula } from "react-code-blocks";
import { Link } from "react-router-dom";

import { useAuthContext } from "../context/auth_context";

export const Home = () => {
  const { username, signedIn } = useAuthContext();

  if (signedIn) {
    const sshConfig = `Host chessh
  Hostname ${process.env.REACT_APP_SSH_SERVER}
  User ${username}
  Port ${process.env.REACT_APP_SSH_PORT}
  PubkeyAuthentication yes`;
    return (
      <>
        <h2>Hello there, {username}!</h2>
        <p>
          You can now start playing CheSSH by using any of your imported{" "}
          <Link to="/keys">public keys</Link>, or by{" "}
          <Link to="/user">creating a password</Link>.
        </p>

        <hr />
        <h2>Getting Started</h2>
        <ol>
          <li>
            Add the following to your ssh config (normally in ~/.ssh/config):
          </li>

          <CopyBlock
            theme={dracula}
            text={sshConfig}
            showLineNumbers={true}
            wrapLines
            codeBlock
          />

          <div>
            <li>And connect with:</li>
            <CopyBlock
              theme={dracula}
              text={`ssh -t chessh`}
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
    </div>
  );
};
