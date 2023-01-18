import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import { Root } from "./root";
import { Demo } from "./routes/demo";
import { Home } from "./routes/home";

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
        path: "keys",
        element: <Home />,
      },
    ],
  },
]);

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<RouterProvider router={router} />);
