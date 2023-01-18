import { Link, Outlet } from "react-router-dom";

import logo from "./assets/chessh_sm.svg";

export const Root = () => (
  <>
    <div className="container">
      <div className="navbar">
        <div>
          <Link to="/home">
            <img src={logo} className="logo" />
          </Link>
        </div>
        <div className="nav">
          <Link className="link" to="/user">
            User
          </Link>
          <Link className="link" to="/keys">
            Keys
          </Link>
        </div>
      </div>
      <div className="content">
        <Outlet />
      </div>
    </div>
  </>
);
