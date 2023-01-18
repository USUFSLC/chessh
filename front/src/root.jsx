import { Link, Outlet } from "react-router-dom";

import logo from "./assets/chessh_sm.svg";

import { useAuthContext, DEFAULT_EXPIRY_TIME_MS } from "./context/auth_context";

export const Root = () => {
  const { signedIn, setSignedIn, setSessionOver } = useAuthContext();
  return (
    <>
      <div className="container">
        <div className="navbar">
          <div>
            <Link to="/home">
              <img src={logo} className="logo" alt="CheSSH Logo" />
            </Link>
          </div>
          <div className="nav">
            {signedIn ? (
              <>
                <Link className="link" to="/user">
                  User
                </Link>
                <Link className="link" to="/keys">
                  Keys
                </Link>
                <Link
                  className="link"
                  onClick={() => setSignedIn(false)}
                  to="/"
                >
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
                  className="link"
                >
                  Login w/ GitHub
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
