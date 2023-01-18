import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import { AuthProvider } from "./context/auth_context";
import { Root } from "./root";
import { Demo } from "./routes/demo";
import { Home } from "./routes/home";
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
        path: "user",
        element: <Home />,
      },
      {
        path: "auth-successful",
        element: <AuthSuccessful />,
      },
      {
        path: "keys",
        element: <Home />,
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
