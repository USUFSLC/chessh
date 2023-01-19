import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import { AuthProvider } from "./context/auth_context";
import { Root } from "./root";
import { Demo } from "./routes/demo";
import { Home } from "./routes/home";
import { Keys } from "./routes/keys";
import { Password } from "./routes/password";
import { AuthSuccessful } from "./routes/auth_successful";

import "./index.css";

const router = createBrowserRouter([
  { path: "/", element: <Demo /> },
  {
    path: "/",
    element: <Root />,
    errorElement: <> </>,
    children: [
      {
        path: "home",
        element: <Home />,
      },
      {
        path: "password",
        element: <Password />,
      },
      {
        path: "keys",
        element: <Keys />,
      },
      {
        path: "auth-successful",
        element: <AuthSuccessful />,
      },
    ],
  },
]);

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(
  <AuthProvider>
    <RouterProvider router={router} />
  </AuthProvider>
);
