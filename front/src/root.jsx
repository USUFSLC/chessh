import { Link, Outlet } from "react-router-dom";

import logo from "./assets/chessh_sm.svg";

import { useAuthContext, DEFAULT_EXPIRY_TIME_MS } from "./context/auth_context";

export const Root = () => {
  const { signedIn, setUserId, setSignedIn, setSessionOver } = useAuthContext();

  const signOut = () => {
    fetch("/api/player/logout", {
      method: "GET",
      credentials: "same-origin",
    }).then(() => {
      setSignedIn(false);
      setUserId(null);
      setSessionOver(new Date());
    });
  };

  return (
    <>
      <div className="container">
        <div className="navbar">
          <div className="flex-row-around">
            <Link to="/home">
              <img src={logo} className="logo" alt="CheSSH Logo" />
            </Link>
          </div>
          <div className="nav">
            <Link className="link" to="/faq">
              FAQ
            </Link>
            {signedIn ? (
              <>
                <Link className="link" to="/user">
                  User
                </Link>
                <Link className="link" to="/keys">
                  Keys
                </Link>
                <Link className="button" onClick={signOut} to="/">
                  Sign Out
                </Link>
              </>
            ) : (
              <>
                <a
                  onClick={() =>
                    setSessionOver(
                      new Date(Date.now() + DEFAULT_EXPIRY_TIME_MS)
                    )
                  }
                  href={process.env.REACT_APP_GITHUB_OAUTH}
                  className="button"
                >
                  🐙 Login w/ GitHub 🐙
                </a>
              </>
            )}
          </div>
        </div>
        <div className="content">
          <Outlet />
        </div>
      </div>
    </>
  );
};
