import { Link, Outlet } from "react-router-dom";

import logo from "./assets/chessh_sm.svg";

import { useAuthContext } from "./context/auth_context";

export const Root = () => {
  const { signedIn, signOut } = useAuthContext();

  return (
    <>
      <div className="container">
        <div className="flex-row-around">
          <Link to="/home">
            <img src={logo} className="logo" alt="CheSSH Logo" />
          </Link>
        </div>
        <div className="navbar">
          <div className="nav">
            {signedIn ? (
              <>
                <Link className="button" onClick={signOut} to="/">
                  Sign Out
                </Link>
                <Link className="link" to="/home">
                  Home
                </Link>
                <Link className="link" to="/password">
                  Password
                </Link>
                <Link className="link" to="/keys">
                  Keys
                </Link>
                <Link className="link" to="/bots">
                  Bots
                </Link>
              </>
            ) : (
              <>
                <a
                  href={process.env.REACT_APP_DISCORD_OAUTH}
                  className="button"
                >
                  👾 Login w/ Discord 👾
                </a>
              </>
            )}

            <Link className="link" to="/man-pages">
              Man Pages
            </Link>
          </div>
        </div>
        <div className="content">
          <Outlet />
        </div>
      </div>
    </>
  );
};
